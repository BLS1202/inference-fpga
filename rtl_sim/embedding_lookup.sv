module embedding_lookup #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int DATA_WIDTH = 16,
    parameter int SUM_WIDTH = 16,
    parameter int TOKEN_ADDR_WIDTH = (VOCAB_SIZE*N_EMBD <= 1) ? 1 : $clog2(VOCAB_SIZE*N_EMBD),
    parameter int POS_ADDR_WIDTH = (BLOCK_SIZE*N_EMBD <= 1) ? 1 : $clog2(BLOCK_SIZE*N_EMBD)
) (
    input  logic clk,
    input  logic rst_n,
    input  logic valid_in,
    input  logic [$clog2(VOCAB_SIZE)-1:0] token_id,
    input  logic [$clog2(BLOCK_SIZE)-1:0] pos_id,

    output logic token_bram_en,
    output logic [TOKEN_ADDR_WIDTH-1:0] token_bram_addr,
    input  logic [DATA_WIDTH-1:0] token_bram_dout,
    output logic pos_bram_en,
    output logic [POS_ADDR_WIDTH-1:0] pos_bram_addr,
    input  logic [DATA_WIDTH-1:0] pos_bram_dout,

    output logic valid_out,
    output logic signed [N_EMBD*SUM_WIDTH-1:0] embedding
);

    localparam int INDEX_WIDTH = (N_EMBD <= 1) ? 1 : $clog2(N_EMBD);
    typedef enum logic [1:0] {ST_IDLE, ST_READ, ST_DRAIN, ST_DONE} state_t;
    state_t state;

    logic [INDEX_WIDTH-1:0] issue_index;
    logic [INDEX_WIDTH-1:0] issue_index_d1, issue_index_d2;
    logic request_valid_d1, request_valid_d2;
    logic [TOKEN_ADDR_WIDTH-1:0] token_base_addr;
    logic [POS_ADDR_WIDTH-1:0] pos_base_addr;
    logic signed [N_EMBD*DATA_WIDTH-1:0] token_vec, pos_vec;

    assign token_bram_en = (state == ST_READ) || request_valid_d1 ||
                           request_valid_d2;
    assign pos_bram_en   = (state == ST_READ) || request_valid_d1 ||
                           request_valid_d2;
    assign token_bram_addr = token_base_addr + issue_index;
    assign pos_bram_addr = pos_base_addr + issue_index;

    function automatic logic signed [DATA_WIDTH-1:0] sat_sum;
        input logic signed [DATA_WIDTH-1:0] a;
        input logic signed [DATA_WIDTH-1:0] b;
        logic signed [DATA_WIDTH:0] sum;
        begin
            sum = $signed(a) + $signed(b);
            if (sum > ((1 <<< (DATA_WIDTH-1)) - 1))
                sat_sum = {1'b0, {(DATA_WIDTH-1){1'b1}}};
            else if (sum < -(1 <<< (DATA_WIDTH-1)))
                sat_sum = {1'b1, {(DATA_WIDTH-1){1'b0}}};
            else
                sat_sum = sum[DATA_WIDTH-1:0];
        end
    endfunction

    always_comb begin
        embedding = '0;
        for (int i = 0; i < N_EMBD; i++) begin
            embedding[i*SUM_WIDTH +: SUM_WIDTH] = sat_sum(
                token_vec[i*DATA_WIDTH +: DATA_WIDTH],
                pos_vec[i*DATA_WIDTH +: DATA_WIDTH]
            );
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            issue_index <= '0;
            issue_index_d1 <= '0;
            issue_index_d2 <= '0;
            request_valid_d1 <= 1'b0;
            request_valid_d2 <= 1'b0;
            token_base_addr <= '0;
            pos_base_addr <= '0;
            token_vec <= '0;
            pos_vec <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            request_valid_d1 <= (state == ST_READ);
            request_valid_d2 <= request_valid_d1;
            issue_index_d1 <= issue_index;
            issue_index_d2 <= issue_index_d1;

            if (request_valid_d2) begin
                token_vec[issue_index_d2*DATA_WIDTH +: DATA_WIDTH] <= token_bram_dout;
                pos_vec[issue_index_d2*DATA_WIDTH +: DATA_WIDTH] <= pos_bram_dout;
            end

            case (state)
                ST_IDLE: if (valid_in) begin
                    token_base_addr <= token_id * N_EMBD;
                    pos_base_addr <= pos_id * N_EMBD;
                    issue_index <= '0;
                    state <= ST_READ;
                end
                ST_READ: if (issue_index == N_EMBD - 1)
                    state <= ST_DRAIN;
                else
                    issue_index <= issue_index + 1'b1;
                ST_DRAIN: if (request_valid_d2 && issue_index_d2 == N_EMBD - 1)
                    state <= ST_DONE;
                ST_DONE: begin
                    valid_out <= 1'b1;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
