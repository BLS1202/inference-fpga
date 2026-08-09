`timescale 1ns/1ps

// Top-level wrapper for token and position embedding BRAMs.
//
// The two blk_mem_gen instances are Vivado IP blocks. Configure both IPs
// for 16-bit data, synchronous read, and the same address width used below.
module bram_emb #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int DATA_WIDTH = 16,
    parameter int BRAM_ADDR_WIDTH = 9,
    parameter int TEST_TOKEN_ID = 26,
    parameter int TEST_POS_ID = 0
);

    logic clk;
    logic rst_n;
    logic start;
    logic [$clog2(VOCAB_SIZE)-1:0] token_id;
    logic [$clog2(BLOCK_SIZE)-1:0] pos_id;

    logic busy;
    logic valid_out;
    logic signed [N_EMBD*DATA_WIDTH-1:0] token_embedding;
    logic signed [N_EMBD*DATA_WIDTH-1:0] position_embedding;

    logic token_bram_en;
    logic [BRAM_ADDR_WIDTH-1:0] token_bram_addr;
    logic [DATA_WIDTH-1:0] token_bram_dout;

    logic pos_bram_en;
    logic [BRAM_ADDR_WIDTH-1:0] pos_bram_addr;
    logic [DATA_WIDTH-1:0] pos_bram_dout;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        token_id = TEST_TOKEN_ID;
        pos_id = TEST_POS_ID;

        #20;
        rst_n = 1'b1;

        #20;
        start = 1'b1;
        #10;
        start = 1'b0;
    end

    embedding_bram_reader #(
        .VOCAB_SIZE      (VOCAB_SIZE),
        .BLOCK_SIZE      (BLOCK_SIZE),
        .N_EMBD          (N_EMBD),
        .DATA_WIDTH      (DATA_WIDTH),
        .BRAM_ADDR_WIDTH (BRAM_ADDR_WIDTH)
    ) reader_i (
        .clk               (clk),
        .rst_n             (rst_n),
        .start             (start),
        .token_id          (token_id),
        .pos_id            (pos_id),
        .token_bram_en     (token_bram_en),
        .token_bram_addr   (token_bram_addr),
        .token_bram_dout   (token_bram_dout),
        .pos_bram_en       (pos_bram_en),
        .pos_bram_addr     (pos_bram_addr),
        .pos_bram_dout     (pos_bram_dout),
        .busy              (busy),
        .valid_out         (valid_out),
        .token_embedding   (token_embedding),
        .position_embedding(position_embedding)
    );

    // Token embedding BRAM, initialized with the exported WTE weights.
    blk_mem_gen_0 token_bram (
        .clka  (clk),
        .ena   (token_bram_en),
        .addra (token_bram_addr),
        .douta (token_bram_dout),
        .dina  ('0),
        .wea   (1'b0)
    );

    // Position embedding BRAM, initialized with the exported WPE weights.
    blk_mem_gen_1 position_bram (
        .clka  (clk),
        .ena   (pos_bram_en),
        .addra (pos_bram_addr),
        .douta (pos_bram_dout),
        .dina  ('0),
        .wea   (1'b0)
    );

    always @(posedge clk) begin
        if (valid_out) begin
            $display("Embedding read completed at time %0t", $time);
            $display("  token id: %0d", token_id);
            $display("  position: %0d", pos_id);
            $display("  token embedding: 0x%h", token_embedding);
            $display("  position embedding: 0x%h", position_embedding);
            $finish;
        end
    end

endmodule
