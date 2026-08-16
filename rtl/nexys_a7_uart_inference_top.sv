`timescale 1ns/1ps

// Nexys A7 UART wrapper for top_inference.
//
// UART protocol:
//   RX byte 0: first token_id in the low TOKEN_WIDTH bits
//   Press BTNC once for each inference step after the first token is received.
//   TX bytes : all generated next_token values in the low TOKEN_WIDTH bits
//              after BOS/EOS or the 16-token context limit is reached.
//
// For the current 20 ns / 50 MHz project clock and 115200 baud:
//   CLKS_PER_BIT = 50_000_000 / 115200 ~= 434
module nexys_a7_uart_inference_top #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int N_HEAD = 4,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12,
    parameter int CLKS_PER_BIT = 434,
    parameter string EXP_INIT_FILE = "exp_lut.mem"
) (
    input  logic        CLK100MHZ,
    input  logic [1:0]  sw,
    input  logic        btnc,
    input  logic        UART_TXD_IN,
    output logic        UART_RXD_OUT,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [7:0]  an,
    output logic [15:0] LED
);

    localparam int TOKEN_WIDTH = (VOCAB_SIZE <= 1) ? 1 : $clog2(VOCAB_SIZE);
    localparam int POS_WIDTH = (BLOCK_SIZE <= 1) ? 1 : $clog2(BLOCK_SIZE);
    localparam logic [7:0] VOCAB_SIZE_BYTE = 8'(VOCAB_SIZE);
    localparam int BOS_TOKEN = VOCAB_SIZE - 1;

    typedef enum logic [3:0] {
        ST_WAIT_TOKEN,
        ST_WAIT_BUTTON,
        ST_CLEAR,
        ST_START_0,
        ST_START_1,
        ST_WAIT_CORE,
        ST_STORE_RESULT,
        ST_ADVANCE,
        ST_TX_LOAD,
        ST_TX_SEND,
        ST_TX_WAIT
    } state_t;

    state_t state;

    logic clk_50mhz, clk_locked;
    clk_wiz_0 clk_wiz_i (
        .clk_in1(CLK100MHZ),
        .reset(sw[1]),
        .clk_out1(clk_50mhz),
        .locked(clk_locked)
    );

    logic [1:0] reset_sync;
    logic rst_l;

    logic uart_rx_valid;
    logic [7:0] uart_rx_data;
    logic uart_rx_busy;
    logic uart_frame_error;

    logic uart_tx_valid;
    logic [7:0] uart_tx_data;
    logic uart_tx_ready;
    logic uart_tx_busy;
    logic uart_tx_done;
    logic button_pressed;
    logic button_pressed_pulse;

    logic core_start;
    logic clear_kv_cache;
    logic [TOKEN_WIDTH-1:0] token_id;
    logic [POS_WIDTH-1:0] pos_id;
    logic core_busy;
    logic core_valid;
    logic signed [VOCAB_SIZE*DATA_WIDTH-1:0] logits_out;
    logic [VOCAB_SIZE*DATA_WIDTH-1:0] probs_out;
    logic [TOKEN_WIDTH-1:0] next_token;
    logic end_token;
    logic [5:0] core_debug_state;
    logic protocol_error;
    logic [31:0] sevenseg_value;
    logic [TOKEN_WIDTH-1:0] generated_tokens [0:BLOCK_SIZE-1];
    logic [POS_WIDTH:0] generated_count;
    logic [POS_WIDTH:0] tx_index;

    always_ff @(posedge clk_50mhz or posedge sw[1]) begin
        if (sw[1]) begin
            reset_sync <= 2'b00;
        end else begin
            reset_sync <= {reset_sync[0], 1'b1};
        end
    end

    assign rst_l = reset_sync[1];

    button button_start_i (
        .clk           (clk_50mhz),
        .rst_l         (rst_l),
        .button_in     (btnc),
        .pressed       (button_pressed),
        .pressed_pulse (button_pressed_pulse)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_rx_i (
        .clk(clk_50mhz),
        .rst_l(rst_l),
        .rx(UART_TXD_IN),
        .rx_valid(uart_rx_valid),
        .rx_data(uart_rx_data),
        .rx_busy(uart_rx_busy),
        .frame_error(uart_frame_error)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_i (
        .clk(clk_50mhz),
        .rst_l(rst_l),
        .tx_valid(uart_tx_valid),
        .tx_data(uart_tx_data),
        .tx(UART_RXD_OUT),
        .tx_ready(uart_tx_ready),
        .tx_busy(uart_tx_busy),
        .tx_done(uart_tx_done)
    );

    top_inference #(
        .VOCAB_SIZE    (VOCAB_SIZE),
        .BLOCK_SIZE    (BLOCK_SIZE),
        .N_EMBD        (N_EMBD),
        .N_HEAD        (N_HEAD),
        .DATA_WIDTH    (DATA_WIDTH),
        .ACC_WIDTH     (ACC_WIDTH),
        .FRAC_BITS     (FRAC_BITS),
        .EXP_INIT_FILE (EXP_INIT_FILE)
    ) inference_i (
        .clk            (clk_50mhz),
        .rst_l          (rst_l),
        .start          (core_start),
        .token_id       (token_id),
        .pos_id         (pos_id),
        .clear_kv_cache (clear_kv_cache),
        .busy           (core_busy),
        .valid_out      (core_valid),
        .logits_out     (logits_out),
        .probs_out      (probs_out),
        .next_token     (next_token),
        .end_token      (end_token),
        .debug_state    (core_debug_state)
    );

    sevenseg sevenseg_i (
        .clk   (clk_50mhz),
        .rst_l (rst_l),
        .value (sevenseg_value),
        .seg   (seg),
        .dp    (dp),
        .an    (an)
    );

    always_ff @(posedge clk_50mhz or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_WAIT_TOKEN;
            token_id <= '0;
            pos_id <= '0;
            core_start <= 1'b0;
            clear_kv_cache <= 1'b0;
            uart_tx_valid <= 1'b0;
            uart_tx_data <= '0;
            protocol_error <= 1'b0;
            generated_count <= '0;
            tx_index <= '0;
            for (int i = 0; i < BLOCK_SIZE; i++) begin
                generated_tokens[i] <= '0;
            end
        end else begin
            core_start <= 1'b0;
            clear_kv_cache <= 1'b0;
            uart_tx_valid <= 1'b0;

            case (state)
                ST_WAIT_TOKEN: begin
                    if (uart_rx_valid) begin
                        if (!uart_frame_error && (uart_rx_data < VOCAB_SIZE_BYTE)) begin
                            token_id <= TOKEN_WIDTH'(uart_rx_data);
                            pos_id <= '0;
                            generated_count <= '0;
                            tx_index <= '0;
                            state <= ST_WAIT_BUTTON;
                        end else begin
                            protocol_error <= 1'b1;
                        end
                    end
                end

                ST_WAIT_BUTTON: begin
                    // Debug stepping mode: every core invocation is launched
                    // by one debounced BTNC pulse. Only the first step clears
                    // the KV cache; later steps continue the same sequence.
                    if (button_pressed_pulse) begin
                        if (pos_id == '0)
                            state <= ST_CLEAR;
                        else
                            state <= ST_START_0;
                    end
                end

                ST_CLEAR: begin
                    clear_kv_cache <= 1'b1;
                    state <= ST_START_0;
                end

                ST_START_0: begin
                    core_start <= 1'b1;
                    state <= ST_START_1;
                end

                ST_START_1: begin
                    core_start <= 1'b1;
                    state <= ST_WAIT_CORE;
                end

                ST_WAIT_CORE: begin
                    if (core_valid)
                        state <= ST_STORE_RESULT;
                end

                ST_STORE_RESULT: begin
                    generated_tokens[generated_count] <= next_token;
                    generated_count <= generated_count + 1'b1;
                    state <= ST_ADVANCE;
                end

                ST_ADVANCE: begin
                    if (end_token ||
                        (next_token == TOKEN_WIDTH'(BOS_TOKEN)) ||
                        (pos_id == POS_WIDTH'(BLOCK_SIZE - 1))) begin
                        tx_index <= '0;
                        state <= ST_TX_LOAD;
                    end else begin
                        token_id <= next_token;
                        pos_id <= pos_id + 1'b1;
                        // Wait for the next button press instead of launching
                        // the next autoregressive step immediately.
                        state <= ST_WAIT_BUTTON;
                    end
                end

                ST_TX_LOAD: begin
                    if (tx_index == generated_count) begin
                        state <= ST_WAIT_TOKEN;
                    end else if (uart_tx_ready) begin
                        uart_tx_data <= {{(8-TOKEN_WIDTH){1'b0}}, generated_tokens[tx_index]};
                        state <= ST_TX_SEND;
                    end
                end

                ST_TX_SEND: begin
                    if (uart_tx_ready) begin
                        uart_tx_valid <= 1'b1;
                        state <= ST_TX_WAIT;
                    end
                end

                ST_TX_WAIT: begin
                    if (uart_tx_done) begin
                        tx_index <= tx_index + 1'b1;
                        state <= ST_TX_LOAD;
                    end
                end

                default: begin
                    state <= ST_WAIT_TOKEN;
                end
            endcase
        end
    end

    always_comb begin
        sevenseg_value = '0;
        sevenseg_value[5:0] = core_debug_state;
        sevenseg_value[13:8] = 6'(state);
        sevenseg_value[20:16] = token_id;
        sevenseg_value[28:24] = generated_tokens[0]; 

        LED = '0;
        LED[0] = core_busy;
        LED[1] = core_valid;
        LED[2] = uart_rx_busy;
        LED[3] = uart_tx_busy;
        LED[4] = uart_frame_error;
        LED[5] = protocol_error;
        LED[6] = end_token;
        LED[7] = button_pressed;
        LED[8 +: TOKEN_WIDTH] = next_token;
    end
endmodule : nexys_a7_uart_inference_top
