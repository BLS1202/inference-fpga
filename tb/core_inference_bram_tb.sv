`timescale 1ns/1ps

module core_inference_bram_tb;

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

    // 100 MHz simulation clock.
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
        .clk           (clk),
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
        .end_token     (end_token),
        .debug_state   (debug_state)
    );

    initial begin
        rst_l = 1'b0;
        start = 1'b0;
        clear_kv_cache = 1'b0;
        token_id = TOKEN_WIDTH'(26);
        pos_id = POS_WIDTH'(0);

        // Hold reset for two clock cycles.
        repeat (2) @(posedge clk);
        rst_l = 1'b1;

        // Clear the cache before the first inference step.
        @(negedge clk);
        clear_kv_cache = 1'b1;
        @(negedge clk);
        clear_kv_cache = 1'b0;

        // Start one inference request.
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        // Allow the inference pipeline to run, then end simulation.
        repeat (20000000) @(posedge clk);
        $finish;
    end

endmodule
