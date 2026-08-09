module embedding_lookup #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int DATA_WIDTH = 16,
    parameter int SUM_WIDTH = 16,
    parameter string WTE_INIT_FILE = "microgpt/generated/wte_q12.hex",
    parameter string WPE_INIT_FILE = "microgpt/generated/wpe_q12.hex"
) (
    input  logic                                clk,
    input  logic                                rst_n,
    input  logic                                valid_in,
    input  logic [$clog2(VOCAB_SIZE)-1:0]       token_id,
    input  logic [$clog2(BLOCK_SIZE)-1:0]       pos_id,
    output logic                                valid_out,
    output logic signed [N_EMBD*SUM_WIDTH-1:0]  embedding
);

    logic token_valid;
    logic pos_valid;
    logic signed [N_EMBD*DATA_WIDTH-1:0] token_vec;
    logic signed [N_EMBD*DATA_WIDTH-1:0] pos_vec;

    embedding_rom #(
        .ROWS(VOCAB_SIZE),
        .COLS(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .INIT_FILE(WTE_INIT_FILE)
    ) token_embedding_rom (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .row_idx(token_id),
        .valid_out(token_valid),
        .row_data(token_vec)
    );

    embedding_rom #(
        .ROWS(BLOCK_SIZE),
        .COLS(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .INIT_FILE(WPE_INIT_FILE)
    ) position_embedding_rom (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .row_idx(pos_id),
        .valid_out(pos_valid),
        .row_data(pos_vec)
    );

    assign valid_out = token_valid & pos_valid;

    function automatic logic signed [DATA_WIDTH-1:0] sat_sum;
        input logic signed [DATA_WIDTH-1:0] a;
        input logic signed [DATA_WIDTH-1:0] b;
        logic signed [DATA_WIDTH:0] sum;
        begin
            sum = $signed(a) + $signed(b);
            if (sum > ((1 <<< (DATA_WIDTH-1)) - 1)) begin
                sat_sum = {1'b0, {(DATA_WIDTH-1){1'b1}}};
            end else if (sum < -(1 <<< (DATA_WIDTH-1))) begin
                sat_sum = {1'b1, {(DATA_WIDTH-1){1'b0}}};
            end else begin
                sat_sum = sum[DATA_WIDTH-1:0];
            end
        end
    endfunction

    always_comb begin
        embedding = '0;
        for (int i = 0; i < N_EMBD; i++) begin
            embedding[i*SUM_WIDTH +: SUM_WIDTH] =
                sat_sum(
                    $signed(token_vec[i*DATA_WIDTH +: DATA_WIDTH]),
                    $signed(pos_vec[i*DATA_WIDTH +: DATA_WIDTH])
                );
        end
    end

`ifndef SYNTHESIS
    always_ff @(posedge clk) begin
        if (rst_n && valid_in) begin
            assert (int'(token_id) < VOCAB_SIZE)
                else $fatal(1, "embedding_lookup token_id out of range: %0d", token_id);
            assert (int'(pos_id) < BLOCK_SIZE)
                else $fatal(1, "embedding_lookup pos_id out of range: %0d", pos_id);
        end
    end
`endif
endmodule
