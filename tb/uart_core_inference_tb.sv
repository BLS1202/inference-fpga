`timescale 1ns/1ps

// UART-driven smoke test for top_inference.
//
// Host protocol used by this testbench:
//   byte 0: token_id in the low TOKEN_WIDTH bits
//   byte 1: pos_id in the low POS_WIDTH bits
//
// The FPGA-side bridge runs one inference step and sends back:
//   byte 0: next_token in the low TOKEN_WIDTH bits

module uart_inference_bridge #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int N_HEAD = 4,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12,
    parameter int TOKEN_WIDTH = $clog2(VOCAB_SIZE),
    parameter int POS_WIDTH = $clog2(BLOCK_SIZE),
    parameter int CLKS_PER_BIT = 16,
    parameter string EXP_INIT_FILE = "exp_lut.mem"
) (
    input  logic clk,
    input  logic rst_l,
    input  logic uart_rx_i,
    output logic uart_tx_o
);

    typedef enum logic [2:0] {
        ST_WAIT_TOKEN,
        ST_WAIT_POS,
        ST_CLEAR,
        ST_START_0,
        ST_START_1,
        ST_WAIT_CORE,
        ST_TX_SEND,
        ST_TX_WAIT
    } state_t;

    state_t state;

    logic uart_rx_valid;
    logic [7:0] uart_rx_data;
    logic uart_rx_busy;
    logic uart_frame_error;

    logic uart_tx_valid;
    logic [7:0] uart_tx_data;
    logic uart_tx_ready;
    logic uart_tx_busy;
    logic uart_tx_done;

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

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_rx_core_i (
        .clk(clk),
        .rst_l(rst_l),
        .rx(uart_rx_i),
        .rx_valid(uart_rx_valid),
        .rx_data(uart_rx_data),
        .rx_busy(uart_rx_busy),
        .frame_error(uart_frame_error)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_core_i (
        .clk(clk),
        .rst_l(rst_l),
        .tx_valid(uart_tx_valid),
        .tx_data(uart_tx_data),
        .tx(uart_tx_o),
        .tx_ready(uart_tx_ready),
        .tx_busy(uart_tx_busy),
        .tx_done(uart_tx_done)
    );

    top_inference #(
        .VOCAB_SIZE(VOCAB_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .N_EMBD(N_EMBD),
        .N_HEAD(N_HEAD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .TOKEN_WIDTH(TOKEN_WIDTH),
        .POS_WIDTH(POS_WIDTH),
        .EXP_INIT_FILE(EXP_INIT_FILE)
    ) core_i (
        .clk(clk),
        .rst_l(rst_l),
        .start(core_start),
        .token_id(token_id),
        .pos_id(pos_id),
        .clear_kv_cache(clear_kv_cache),
        .busy(core_busy),
        .valid_out(core_valid),
        .logits_out(logits_out),
        .probs_out(probs_out),
        .next_token(next_token),
        .end_token(end_token),
        .debug_state(core_debug_state)
    );

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_WAIT_TOKEN;
            token_id <= '0;
            pos_id <= '0;
            core_start <= 1'b0;
            clear_kv_cache <= 1'b0;
            uart_tx_valid <= 1'b0;
            uart_tx_data <= '0;
        end else begin
            core_start <= 1'b0;
            clear_kv_cache <= 1'b0;
            uart_tx_valid <= 1'b0;

            case (state)
                ST_WAIT_TOKEN: begin
                    if (uart_rx_valid && !uart_frame_error) begin
                        token_id <= TOKEN_WIDTH'(uart_rx_data);
                        state <= ST_WAIT_POS;
                    end
                end

                ST_WAIT_POS: begin
                    if (uart_rx_valid && !uart_frame_error) begin
                        pos_id <= POS_WIDTH'(uart_rx_data);
                        if (POS_WIDTH'(uart_rx_data) == '0)
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
                        state <= ST_TX_SEND;
                end

                ST_TX_SEND: begin
                    if (uart_tx_ready) begin
                        uart_tx_data <= {{(8-TOKEN_WIDTH){1'b0}}, next_token};
                        uart_tx_valid <= 1'b1;
                        state <= ST_TX_WAIT;
                    end
                end

                ST_TX_WAIT: begin
                    if (uart_tx_done)
                        state <= ST_WAIT_TOKEN;
                end

                default: begin
                    state <= ST_WAIT_TOKEN;
                end
            endcase
        end
    end
endmodule : uart_inference_bridge

module uart_core_inference_tb #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int N_HEAD = 4,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12,
    parameter int TOKEN_WIDTH = $clog2(VOCAB_SIZE),
    parameter int POS_WIDTH = $clog2(BLOCK_SIZE),
    parameter int CLKS_PER_BIT = 16,
    parameter int NUM_TOKENS = 2,
    parameter string EXP_INIT_FILE = "exp_lut.mem"
);

    logic clk;
    logic rst_l;

    logic host_to_fpga;
    logic fpga_to_host;

    logic host_tx_valid;
    logic [7:0] host_tx_data;
    logic host_tx_ready;
    logic host_tx_busy;
    logic host_tx_done;

    logic host_rx_valid;
    logic [7:0] host_rx_data;
    logic host_rx_busy;
    logic host_frame_error;
    logic tb_error;

    logic [TOKEN_WIDTH-1:0] input_tokens [0:NUM_TOKENS-1];
    logic [TOKEN_WIDTH-1:0] file_tokens [0:255];
    string token_file;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) host_tx_i (
        .clk(clk),
        .rst_l(rst_l),
        .tx_valid(host_tx_valid),
        .tx_data(host_tx_data),
        .tx(host_to_fpga),
        .tx_ready(host_tx_ready),
        .tx_busy(host_tx_busy),
        .tx_done(host_tx_done)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) host_rx_i (
        .clk(clk),
        .rst_l(rst_l),
        .rx(fpga_to_host),
        .rx_valid(host_rx_valid),
        .rx_data(host_rx_data),
        .rx_busy(host_rx_busy),
        .frame_error(host_frame_error)
    );

    uart_inference_bridge #(
        .VOCAB_SIZE(VOCAB_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .N_EMBD(N_EMBD),
        .N_HEAD(N_HEAD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .TOKEN_WIDTH(TOKEN_WIDTH),
        .POS_WIDTH(POS_WIDTH),
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .EXP_INIT_FILE(EXP_INIT_FILE)
    ) dut (
        .clk(clk),
        .rst_l(rst_l),
        .uart_rx_i(host_to_fpga),
        .uart_tx_o(fpga_to_host)
    );

    task automatic uart_send_byte(input logic [7:0] data);
        begin
            while (!host_tx_ready)
                @(posedge clk);
            @(negedge clk);
            host_tx_data = data;
            host_tx_valid = 1'b1;
            @(negedge clk);
            host_tx_valid = 1'b0;
            @(posedge host_tx_done);
            @(posedge clk);
        end
    endtask

    task automatic uart_wait_byte(output logic [7:0] data);
        begin
            for (int cycles = 0; !host_rx_valid && cycles < 200000; cycles++)
                @(posedge clk);
            if (!host_rx_valid) begin
                tb_error = 1'b1;
                data = '0;
            end else begin
                if (host_frame_error)
                    tb_error = 1'b1;
                data = host_rx_data;
                @(posedge clk);
            end
        end
    endtask

    initial begin
//        if ($test$plusargs("VCD")) begin
//            $dumpfile("build/verilator/uart_core_inference_tb/uart_core_inference_tb.vcd");
//            $dumpvars(0, uart_core_inference_tb);
//        end

        token_file = "input_tokens.mem";
        $readmemh(token_file, file_tokens);

        tb_error = 1'b0;
        for (int i = 0; i < NUM_TOKENS; i++) begin
            input_tokens[i] = file_tokens[i];
            if (int'(input_tokens[i]) >= VOCAB_SIZE) begin
                input_tokens[i] = '0;
                tb_error = 1'b1;
            end
        end

        rst_l = 1'b0;
        host_tx_valid = 1'b0;
        host_tx_data = '0;

        repeat (5) @(posedge clk);
        rst_l = 1'b1;
        repeat (5) @(posedge clk);

        for (int step = 0; step < NUM_TOKENS; step++) begin
            logic [7:0] response;

            uart_send_byte({{(8-TOKEN_WIDTH){1'b0}}, input_tokens[step]});
            uart_send_byte(8'(step));
            uart_wait_byte(response);
        end

        repeat (10) @(posedge clk);
        $finish;
    end
endmodule : uart_core_inference_tb
