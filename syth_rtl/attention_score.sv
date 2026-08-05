import fixed_point_utils::*;

module attention_score #(
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int N_HEAD = 4,
    parameter int HEAD_DIM = N_EMBD / N_HEAD,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,

    output logic busy,
    output logic valid_out,

    input  logic [$clog2(BLOCK_SIZE)-1:0] pos_id,
    input  logic signed [N_EMBD*DATA_WIDTH-1:0] q_vec,
    input  logic signed [BLOCK_SIZE*N_EMBD*DATA_WIDTH-1:0] keys_cache,

    output logic signed [N_HEAD*BLOCK_SIZE*DATA_WIDTH-1:0] attn_logits
);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_FLUSH_1,
        ST_FLUSH_2,
        ST_FEED,
        ST_WAIT,
        ST_DONE
    } state_t;

    state_t state;

    logic matmul_start;
    logic [N_HEAD-1:0] head_busy;
    logic [N_HEAD-1:0] head_valid;

    logic signed [BLOCK_SIZE*HEAD_DIM*DATA_WIDTH-1:0] key_head_matrix [0:N_HEAD-1];
    logic signed [HEAD_DIM*DATA_WIDTH-1:0] q_head_vector [0:N_HEAD-1];
    logic signed [BLOCK_SIZE*DATA_WIDTH-1:0] score_head_out [0:N_HEAD-1];

    localparam int SCORE_FEED_CYCLES = BLOCK_SIZE + HEAD_DIM - 1;
    localparam int SCORE_COUNT_WIDTH =
        (SCORE_FEED_CYCLES <= 1) ? 1 : $clog2(SCORE_FEED_CYCLES);

    logic [SCORE_COUNT_WIDTH-1:0] score_feed_count;
    logic score_feed_valid;
    logic score_feed_last;
    logic signed [BLOCK_SIZE*DATA_WIDTH-1:0] score_a_feed [0:N_HEAD-1];
    logic signed [DATA_WIDTH-1:0] score_b_feed [0:N_HEAD-1];

    assign busy = (state != ST_IDLE);

    assign score_feed_valid = (state == ST_FEED);
    assign score_feed_last =
        score_feed_valid && (score_feed_count == SCORE_FEED_CYCLES - 1);

    function automatic signed [DATA_WIDTH-1:0] get_q;
        input int head;
        input int dim;
        begin
            get_q = q_vec[((head*HEAD_DIM + dim) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic signed [DATA_WIDTH-1:0] get_k;
        input int pos;
        input int head;
        input int dim;
        begin
            get_k = keys_cache[((pos*N_EMBD + head*HEAD_DIM + dim) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic signed [DATA_WIDTH-1:0] scale_by_sqrt_head_dim;
        input signed [DATA_WIDTH-1:0] value;
        begin
            if (HEAD_DIM == 4) begin
                scale_by_sqrt_head_dim = $signed(value) >>> 1;
            end else if (HEAD_DIM == 1) begin
                scale_by_sqrt_head_dim = value;
            end else begin
                scale_by_sqrt_head_dim = value;
            end
        end
    endfunction

    always_comb begin
        for (int head = 0; head < N_HEAD; head++) begin
            q_head_vector[head] = '0;
            key_head_matrix[head] = '0;

            for (int dim = 0; dim < HEAD_DIM; dim++) begin
                q_head_vector[head][dim*DATA_WIDTH +: DATA_WIDTH] = get_q(head, dim);
            end

            for (int pos = 0; pos < BLOCK_SIZE; pos++) begin
                for (int dim = 0; dim < HEAD_DIM; dim++) begin
                    key_head_matrix[head][((pos*HEAD_DIM + dim) * DATA_WIDTH) +: DATA_WIDTH] =
                        get_k(pos, head, dim);
                end
            end
        end
    end

    // Stream K and Q through the systolic array. At feed cycle t, row r
    // receives K[r][t-r] and the corresponding PE receives Q[t-r].
    always_comb begin
        for (int head = 0; head < N_HEAD; head++) begin
            score_a_feed[head] = '0;
            score_b_feed[head] = '0;

            if (score_feed_valid) begin
                if (score_feed_count < HEAD_DIM) begin
                    score_b_feed[head] =
                        q_head_vector[head][score_feed_count*DATA_WIDTH +: DATA_WIDTH];
                end

                for (int row = 0; row < BLOCK_SIZE; row++) begin
                    if ((score_feed_count >= row) &&
                        ((score_feed_count - row) < HEAD_DIM)) begin
                        score_a_feed[head][row*DATA_WIDTH +: DATA_WIDTH] =
                            key_head_matrix[head][
                                ((row*HEAD_DIM + (score_feed_count - row)) * DATA_WIDTH)
                                +: DATA_WIDTH];
                    end
                end
            end
        end
    end

    genvar head_gen;
    generate
        for (head_gen = 0; head_gen < N_HEAD; head_gen++) begin : gen_head_matmul
            matmul_unit #(
                .M(BLOCK_SIZE),
                .K(HEAD_DIM),
                .N(1),
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(ACC_WIDTH),
                .FRAC_BITS(FRAC_BITS)
            ) score_matmul_i (
                .clk(clk),
                .rst_l(rst_l),
                .start(matmul_start),
                .busy(head_busy[head_gen]),
                .valid_out(head_valid[head_gen]),
                .a_feed(score_a_feed[head_gen]),
                .b_feed(score_b_feed[head_gen]),
                .feed_valid(score_feed_valid),
                .feed_last(score_feed_last),
                .matrix_c(score_head_out[head_gen])
            );
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_IDLE;
            matmul_start <= 1'b0;
            valid_out <= 1'b0;
            attn_logits <= '0;
            score_feed_count <= '0;
        end else begin
            matmul_start <= 1'b0;
            valid_out <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        matmul_start <= 1'b1;
                        score_feed_count <= '0;
                        state <= ST_FLUSH_1;
                    end
                end

                ST_FLUSH_1: begin
                    state <= ST_FLUSH_2;
                end

                ST_FLUSH_2: begin
                    score_feed_count <= '0;
                    state <= ST_FEED;
                end

                ST_FEED: begin
                    if (score_feed_count == SCORE_FEED_CYCLES - 1) begin
                        state <= ST_WAIT;
                    end else begin
                        score_feed_count <= score_feed_count + 1'b1;
                    end
                end

                ST_WAIT: begin
                    if (&head_valid) begin
                        for (int head = 0; head < N_HEAD; head++) begin
                            for (int pos = 0; pos < BLOCK_SIZE; pos++) begin
                                attn_logits[((head*BLOCK_SIZE + pos) * DATA_WIDTH) +: DATA_WIDTH] <=
                                    mask_future_logit(
                                        pos <= pos_id,
                                        scale_by_sqrt_head_dim(
                                            score_head_out[head][pos*DATA_WIDTH +: DATA_WIDTH]
                                        )
                                    );
                            end
                        end
                        state <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    valid_out <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule : attention_score
