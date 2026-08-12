`timescale 1ns/1ps

// Smoke test for the original rtl inference implementation.
module rtl_inference_tb #(
    parameter int NUM_TOKENS = 5
);

    localparam int VOCAB_SIZE = 27;
    localparam int BLOCK_SIZE = 16;
    localparam int N_EMBD = 16;
    localparam int N_HEAD = 4;
    localparam int DATA_WIDTH = 16;
    localparam int ACC_WIDTH = 64;
    localparam int FRAC_BITS = 12;
    localparam int TOKEN_WIDTH = $clog2(VOCAB_SIZE);
    localparam int POS_WIDTH = $clog2(BLOCK_SIZE);

    logic clk;
    logic rst_l;
    logic start;
    logic clear_kv_cache;
    logic [TOKEN_WIDTH-1:0] token_id;
    logic [POS_WIDTH-1:0] pos_id;

    logic busy;
    logic valid_out;
    logic signed [VOCAB_SIZE*DATA_WIDTH-1:0] logits_out;
    logic [VOCAB_SIZE*DATA_WIDTH-1:0] probs_out;
    logic [TOKEN_WIDTH-1:0] next_token;
    logic end_token;
    logic [5:0] debug_state;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    top_inference #(
        .VOCAB_SIZE (VOCAB_SIZE),
        .BLOCK_SIZE (BLOCK_SIZE),
        .N_EMBD     (N_EMBD),
        .N_HEAD     (N_HEAD),
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .FRAC_BITS  (FRAC_BITS)
    ) dut (
        .clk            (clk),
        .rst_l          (rst_l),
        .start          (start),
        .token_id       (token_id),
        .pos_id         (pos_id),
        .clear_kv_cache (clear_kv_cache),
        .busy           (busy),
        .valid_out      (valid_out),
        .logits_out     (logits_out),
        .probs_out      (probs_out),
        .next_token     (next_token),
        .end_token      (end_token),
        .debug_state    (debug_state)
    );

    initial begin
        $dumpfile("build/verilator/rtl_inference_tb/rtl_inference_tb.vcd");
        $dumpvars(0, rtl_inference_tb);

        rst_l = 1'b0;
        start = 1'b0;
        clear_kv_cache = 1'b0;
        token_id = TOKEN_WIDTH'(0);
        pos_id = POS_WIDTH'(1);

        repeat (2) @(posedge clk);
        rst_l = 1'b1;

        @(negedge clk);
        clear_kv_cache = 1'b1;
        @(negedge clk);
        clear_kv_cache = 1'b0;

        for (int i = 0; i < NUM_TOKENS; i++) begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            @(negedge clk);
            start = 1'b0;

            @(posedge valid_out);
            token_id = next_token;
            if (pos_id == BLOCK_SIZE - 1) begin
                pos_id = '0;
            end else begin
                pos_id = pos_id + 1'b1;
            end
        end

        repeat (4) @(posedge clk);
        $finish;
    end

endmodule
