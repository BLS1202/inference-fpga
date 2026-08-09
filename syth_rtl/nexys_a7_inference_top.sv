`timescale 1ns/1ps

// Nexys A7 board wrapper for the MicroGPT inference core.
//
// Current XDC connections:
//   sw[0] : start one inference step on a rising edge
//   sw[1] : active-high reset
//   LED[0]: core busy
//   LED[1]: result valid
//   LED[2]: end token detected
//   LED[7:3]: selected next token
//   LED[11:8]: current sequence position
module nexys_a7_inference_top #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int N_HEAD = 4,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12,
    parameter string EXP_INIT_FILE = "exp_lut.mem"
) (
    input  logic       CLK100MHZ,
    input  logic [1:0] sw,
    output logic [15:0] LED
);

    localparam int TOKEN_WIDTH = (VOCAB_SIZE <= 1) ? 1 : $clog2(VOCAB_SIZE);
    localparam int POS_WIDTH = (BLOCK_SIZE <= 1) ? 1 : $clog2(BLOCK_SIZE);

    logic [1:0] reset_sync;
    logic rst_l;

    logic start;
    logic start_switch_d;
    logic clear_kv_cache;
    logic clear_pending;

    logic [TOKEN_WIDTH-1:0] token_id;
    logic [POS_WIDTH-1:0] pos_id;

    logic busy;
    logic valid_out;
    logic signed [VOCAB_SIZE*DATA_WIDTH-1:0] logits_out;
    logic [VOCAB_SIZE*DATA_WIDTH-1:0] probs_out;
    logic [TOKEN_WIDTH-1:0] next_token;
    logic end_token;

    // Synchronize release of the active-high reset switch.
    always_ff @(posedge CLK100MHZ or posedge sw[1]) begin
        if (sw[1]) begin
            reset_sync <= 2'b00;
        end else begin
            reset_sync <= {reset_sync[0], 1'b1};
        end
    end

    assign rst_l = reset_sync[1];

    // Generate one start pulse from a rising edge of sw[0].
    // A request is accepted by the core only when it is idle.
    always_ff @(posedge CLK100MHZ or negedge rst_l) begin
        if (!rst_l) begin
            start_switch_d <= 1'b0;
            start <= 1'b0;
        end else begin
            start_switch_d <= sw[0];
            start <= sw[0] & ~start_switch_d;
        end
    end

    // Clear the KV cache once after reset is released.
    always_ff @(posedge CLK100MHZ or negedge rst_l) begin
        if (!rst_l) begin
            clear_pending <= 1'b1;
            clear_kv_cache <= 1'b0;
        end else begin
            clear_kv_cache <= clear_pending;
            clear_pending <= 1'b0;
        end
    end

    // Begin with the BOS/end token used by MicroGPT. After each completed
    // step, feed the selected token into the next sequence position.
    always_ff @(posedge CLK100MHZ or negedge rst_l) begin
        if (!rst_l) begin
            token_id <= TOKEN_WIDTH'(VOCAB_SIZE - 1);
            pos_id <= '0;
        end else if (valid_out) begin
            token_id <= next_token;

            if (pos_id == BLOCK_SIZE - 1) begin
                pos_id <= '0;
            end else begin
                pos_id <= pos_id + 1'b1;
            end
        end
    end

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
        .clk           (CLK100MHZ),
        .rst_l         (rst_l),
        .start         (start),
        .token_id      (token_id),
        .pos_id        (pos_id),
        .clear_kv_cache(clear_kv_cache),
        .busy          (busy),
        .valid_out     (valid_out),
        .logits_out    (logits_out),
        .probs_out     (probs_out),
        .next_token    (next_token),
        .end_token     (end_token)
    );

    always_comb begin
        LED = '0;
        LED[0] = busy;
        LED[1] = valid_out;
        LED[2] = end_token;
        LED[3 +: TOKEN_WIDTH] = next_token;
        LED[8 +: POS_WIDTH] = pos_id;
    end

endmodule
