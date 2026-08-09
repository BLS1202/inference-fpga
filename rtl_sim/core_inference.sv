import fixed_point_utils::*;

module top_inference #(
      // Number of possible tokens.
      // microgpt has 26 character tokens + 1 BOS/end token = 27.
      parameter int VOCAB_SIZE = 27,

      // Maximum sequence length / context window.
      // microgpt generates up to 16 positions.
      parameter int BLOCK_SIZE = 16,

      // Embedding/model hidden width.
      // Every token vector, position vector, q/k/v vector, and residual vector has 16 values.
      parameter int N_EMBD = 16,

      // Number of attention heads.
      // microgpt uses 4 heads.
      parameter int N_HEAD = 4,

      // Width of each attention head.
      // HEAD_DIM = N_EMBD / N_HEAD = 16 / 4 = 4.
      parameter int HEAD_DIM = N_EMBD / N_HEAD,

      // Fixed-point data width for most model values.
      // Current exported weights are signed 16-bit Q4.12.
      parameter int DATA_WIDTH = 16,

      // Accumulator width for dot products / matmul.
      // Wider than DATA_WIDTH to avoid overflow during multiply-accumulate.
      parameter int ACC_WIDTH = 64,

      // Number of fractional bits in fixed-point values.
      // Q4.12 means 12 fractional bits.
      parameter int FRAC_BITS = 12,

      // Bit width needed to represent token IDs 0..VOCAB_SIZE-1.
      // For VOCAB_SIZE=27, TOKEN_WIDTH=5.
      parameter int TOKEN_WIDTH = $clog2(VOCAB_SIZE),

      // Bit width needed to represent position IDs 0..BLOCK_SIZE-1.
      // For BLOCK_SIZE=16, POS_WIDTH=4.
      parameter int POS_WIDTH = $clog2(BLOCK_SIZE),

      // Embedding lookup adds token and position embeddings.
      // Embeddings use the same signed 16-bit Q4.12 format as the rest of
      // the model data path.
      parameter int EMB_WIDTH = DATA_WIDTH,

      // Trained MicroGPT parameter files. Paths are relative to the
      // simulator working directory.
      parameter string WTE_INIT_FILE = "microgpt/generated/wte_q12.hex",
      parameter string WPE_INIT_FILE = "microgpt/generated/wpe_q12.hex",
      parameter string ATTN_WQ_INIT_FILE = "microgpt/generated/layer0_attn_wq_q12.hex",
      parameter string ATTN_WK_INIT_FILE = "microgpt/generated/layer0_attn_wk_q12.hex",
      parameter string ATTN_WV_INIT_FILE = "microgpt/generated/layer0_attn_wv_q12.hex",
      parameter string ATTN_WO_INIT_FILE = "microgpt/generated/layer0_attn_wo_q12.hex",
      parameter string MLP_FC1_INIT_FILE = "microgpt/generated/layer0_mlp_fc1_q12.hex",
      parameter string MLP_FC2_INIT_FILE = "microgpt/generated/layer0_mlp_fc2_q12.hex",
      parameter string LM_HEAD_INIT_FILE = "microgpt/generated/lm_head_q12.hex",
      parameter string EXP_INIT_FILE = "microgpt/generated/exp_q12.hex"
)
(
    input  logic clk,
    input  logic rst_l,

    // Starts one next-token inference step.
    input  logic start,

    // Input token for this step.
    // For pos_id=0, this should usually be BOS token 26.
    input  logic [TOKEN_WIDTH-1:0] token_id,

    // Current sequence position, 0..15.
    input  logic [POS_WIDTH-1:0] pos_id,

    // Clears KV cache before starting a new sequence/name.
    input  logic clear_kv_cache,

    // Core status.
    output logic busy,
    output logic valid_out,

    // Final raw scores from lm_head.
    output logic signed [VOCAB_SIZE*DATA_WIDTH-1:0] logits_out,

    // Final softmax probabilities.
    output logic [VOCAB_SIZE*DATA_WIDTH-1:0] probs_out,

    // Chosen next token.
    // At first, this can be argmax. Later, replace with RNG sampling.
    output logic [TOKEN_WIDTH-1:0] next_token,

    // High when next_token is BOS/end token.
    output logic end_token
);



    enum logic [5:0] {
        ST_IDLE,

        ST_EMBED,

        ST_RMS0,

        ST_ATTN_Q,
        ST_ATTN_K,
        ST_ATTN_V,

        ST_KV_WRITE,

        ST_ATTN_SCORE,

        ST_ATTN_SOFTMAX,

        ST_ATTN_VALUE,

        ST_ATTN_WO,

        ST_ATTN_RESIDUAL,

        ST_RMS1,

        ST_MLP_FC1,

        ST_MLP_RELU,

        ST_MLP_FC2,

        ST_MLP_RESIDUAL,

        ST_LM_HEAD,

        ST_SOFTMAX,

        ST_SELECT_TOKEN,

        ST_DONE
    } state, nState;

    logic embed_valid_in;
    logic embed_valid_out;
    logic signed [N_EMBD*EMB_WIDTH-1:0] embedding_vec;

    logic rms0_valid_in;
    logic rms0_valid_out;
    logic signed [N_EMBD*DATA_WIDTH-1:0] rms0_vec;

    logic q_start;
    logic k_start;
    logic v_start;

    logic q_busy;
    logic k_busy;
    logic v_busy;

    logic q_valid;
    logic k_valid;
    logic v_valid;

    logic signed [N_EMBD*DATA_WIDTH-1:0] q_vec;
    logic signed [N_EMBD*DATA_WIDTH-1:0] k_vec;
    logic signed [N_EMBD*DATA_WIDTH-1:0] v_vec;

    logic kv_write_en;


    logic attn_score_start;
    logic attn_score_busy;
    logic attn_score_valid;

    logic attn_softmax_start;
    logic attn_softmax_busy;
    logic attn_softmax_valid;

    logic attn_value_start;
    logic attn_value_busy;
    logic attn_value_valid;

    logic attn_wo_start;
    logic attn_wo_busy;
    logic attn_wo_valid;

    logic signed [BLOCK_SIZE*N_EMBD*DATA_WIDTH-1:0] keys_cache;
    logic signed [BLOCK_SIZE*N_EMBD*DATA_WIDTH-1:0] values_cache;

    logic signed [N_HEAD*BLOCK_SIZE*DATA_WIDTH-1:0] attn_logits;
    logic [N_HEAD*BLOCK_SIZE*DATA_WIDTH-1:0] attn_probs;

    logic signed [N_EMBD*DATA_WIDTH-1:0] attn_context_vec;
    logic signed [N_EMBD*DATA_WIDTH-1:0] attn_wo_vec;
    logic signed [N_EMBD*DATA_WIDTH-1:0] attn_residual_vec;

    logic [N_HEAD-1:0] attn_softmax_head_busy;
    logic [N_HEAD-1:0] attn_softmax_head_valid;
    logic signed [BLOCK_SIZE*DATA_WIDTH-1:0] attn_logits_head [0:N_HEAD-1];
    logic [BLOCK_SIZE*DATA_WIDTH-1:0] attn_probs_head [0:N_HEAD-1];

    logic [N_HEAD-1:0] attn_value_head_busy;
    logic [N_HEAD-1:0] attn_value_head_valid;
    logic signed [BLOCK_SIZE*DATA_WIDTH-1:0] attn_probs_head_signed [0:N_HEAD-1];
    logic signed [BLOCK_SIZE*HEAD_DIM*DATA_WIDTH-1:0] value_head_matrix [0:N_HEAD-1];
    logic signed [HEAD_DIM*DATA_WIDTH-1:0] context_head_vec [0:N_HEAD-1];

    localparam int MLP_HIDDEN = 4 * N_EMBD;

    logic rms1_valid_in;
    logic rms1_valid_out;
    logic signed [N_EMBD*DATA_WIDTH-1:0] rms1_vec;

    logic mlp_fc1_start;
    logic mlp_fc1_busy;
    logic mlp_fc1_valid;
    logic signed [MLP_HIDDEN*DATA_WIDTH-1:0] mlp_fc1_vec;
    logic signed [MLP_HIDDEN*DATA_WIDTH-1:0] mlp_relu_vec;

    logic mlp_fc2_start;
    logic mlp_fc2_busy;
    logic mlp_fc2_valid;
    logic signed [N_EMBD*DATA_WIDTH-1:0] mlp_fc2_vec;
    logic signed [N_EMBD*DATA_WIDTH-1:0] mlp_residual_vec;

    logic lm_head_start;
    logic lm_head_busy;
    logic lm_head_valid;
    logic signed [VOCAB_SIZE*DATA_WIDTH-1:0] lm_logits_vec;

    logic final_softmax_start;
    logic final_softmax_busy;
    logic final_softmax_valid;
    logic [VOCAB_SIZE*DATA_WIDTH-1:0] final_probs_vec;

    logic [TOKEN_WIDTH-1:0] argmax_token;
    logic signed [DATA_WIDTH-1:0] argmax_value;

    // Shared linear-layer matmul resources. Scheduling and result routing are
    // added separately; these signals are intentionally idle for now.
    logic shared_matmul_start;
    logic shared_matmul_busy;
    logic shared_matmul_valid;
    logic signed [N_EMBD*N_EMBD*DATA_WIDTH-1:0] shared_matrix_a;
    logic signed [N_EMBD*DATA_WIDTH-1:0] shared_matrix_b;
    logic signed [N_EMBD*DATA_WIDTH-1:0] shared_matrix_c;

    typedef enum logic [3:0] {
        OP_NONE,
        OP_Q,
        OP_K,
        OP_V,
        OP_WO,
        OP_FC1,
        OP_FC2,
        OP_LM
    } matmul_op_t;

    matmul_op_t shared_op;
    logic [5:0] shared_row_base;
    logic [5:0] shared_col_base;
    logic shared_started;
    logic signed [ACC_WIDTH-1:0] fc2_acc [0:N_EMBD-1];

    function automatic logic signed [ACC_WIDTH-1:0] extend_data;
        input logic signed [DATA_WIDTH-1:0] value;
        begin
            extend_data = {{(ACC_WIDTH-DATA_WIDTH){value[DATA_WIDTH-1]}}, value};
        end
    endfunction

    logic signed [DATA_WIDTH-1:0] attn_wq_mem [0:N_EMBD*N_EMBD-1];
    logic signed [DATA_WIDTH-1:0] attn_wk_mem [0:N_EMBD*N_EMBD-1];
    logic signed [DATA_WIDTH-1:0] attn_wv_mem [0:N_EMBD*N_EMBD-1];
    logic signed [DATA_WIDTH-1:0] attn_wo_mem [0:N_EMBD*N_EMBD-1];
    logic signed [DATA_WIDTH-1:0] mlp_fc1_mem [0:MLP_HIDDEN*N_EMBD-1];
    logic signed [DATA_WIDTH-1:0] mlp_fc2_mem [0:N_EMBD*MLP_HIDDEN-1];
    logic signed [DATA_WIDTH-1:0] lm_head_mem [0:VOCAB_SIZE*N_EMBD-1];

    initial begin
        $readmemh(ATTN_WQ_INIT_FILE, attn_wq_mem);
        $readmemh(ATTN_WK_INIT_FILE, attn_wk_mem);
        $readmemh(ATTN_WV_INIT_FILE, attn_wv_mem);
        $readmemh(ATTN_WO_INIT_FILE, attn_wo_mem);
        $readmemh(MLP_FC1_INIT_FILE, mlp_fc1_mem);
        $readmemh(MLP_FC2_INIT_FILE, mlp_fc2_mem);
        $readmemh(LM_HEAD_INIT_FILE, lm_head_mem);
    end

    assign q_busy = shared_matmul_busy && (shared_op == OP_Q);
    assign k_busy = shared_matmul_busy && (shared_op == OP_K);
    assign v_busy = shared_matmul_busy && (shared_op == OP_V);
    assign attn_wo_busy = shared_matmul_busy && (shared_op == OP_WO);
    assign mlp_fc1_busy = shared_matmul_busy && (shared_op == OP_FC1);
    assign mlp_fc2_busy = shared_matmul_busy && (shared_op == OP_FC2);
    assign lm_head_busy = shared_matmul_busy && (shared_op == OP_LM);

    assign q_valid = shared_matmul_valid && (shared_op == OP_Q);
    assign k_valid = shared_matmul_valid && (shared_op == OP_K);
    assign v_valid = shared_matmul_valid && (shared_op == OP_V);
    assign attn_wo_valid = shared_matmul_valid && (shared_op == OP_WO);

    assign mlp_fc1_valid =
        shared_matmul_valid &&
        (shared_op == OP_FC1) &&
        (shared_row_base == 6'd48);

    assign mlp_fc2_valid =
        shared_matmul_valid &&
        (shared_op == OP_FC2) &&
        (shared_col_base == 6'd48);

    assign lm_head_valid =
        shared_matmul_valid &&
        (shared_op == OP_LM) &&
        (shared_row_base == 6'd16);

    always_comb begin
        shared_matmul_start = 1'b0;

        if (!shared_started &&
            !shared_matmul_busy &&
            !shared_matmul_valid) begin
            case (state)
                ST_ATTN_Q,
                ST_ATTN_K,
                ST_ATTN_V,
                ST_ATTN_WO,
                ST_MLP_FC1,
                ST_MLP_FC2,
                ST_LM_HEAD:
                    shared_matmul_start = 1'b1;
                default:
                    shared_matmul_start = 1'b0;
            endcase
        end
    end

    always_comb begin
        shared_matrix_a = '0;
        shared_matrix_b = '0;

        for (int row = 0; row < N_EMBD; row++) begin
            for (int col = 0; col < N_EMBD; col++) begin
                case (shared_op)
                    OP_Q:
                        if ((int'(shared_row_base) + row) < N_EMBD)
                            shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] =
                                attn_wq_mem[((int'(shared_row_base) + row)*N_EMBD) + col];
                    OP_K:
                        if ((int'(shared_row_base) + row) < N_EMBD)
                            shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] =
                                attn_wk_mem[((int'(shared_row_base) + row)*N_EMBD) + col];
                    OP_V:
                        if ((int'(shared_row_base) + row) < N_EMBD)
                            shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] =
                                attn_wv_mem[((int'(shared_row_base) + row)*N_EMBD) + col];
                    OP_WO:
                        if ((int'(shared_row_base) + row) < N_EMBD)
                            shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] =
                                attn_wo_mem[((int'(shared_row_base) + row)*N_EMBD) + col];
                    OP_FC1:
                        if ((int'(shared_row_base) + row) < MLP_HIDDEN)
                            shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] =
                                mlp_fc1_mem[((int'(shared_row_base) + row)*N_EMBD) + col];
                    OP_FC2:
                        if ((int'(shared_row_base) + row) < N_EMBD)
                            shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] =
                                mlp_fc2_mem[
                                    ((int'(shared_row_base) + row)*MLP_HIDDEN) +
                                    int'(shared_col_base) + col
                                ];
                    OP_LM:
                        if ((int'(shared_row_base) + row) < VOCAB_SIZE)
                            shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] =
                                lm_head_mem[((int'(shared_row_base) + row)*N_EMBD) + col];
                    default:
                        shared_matrix_a[((row*N_EMBD + col)*DATA_WIDTH) +: DATA_WIDTH] = '0;
                endcase
            end
        end

        for (int col = 0; col < N_EMBD; col++) begin
            case (shared_op)
                OP_Q, OP_K, OP_V:
                    shared_matrix_b[col*DATA_WIDTH +: DATA_WIDTH] =
                        rms0_vec[col*DATA_WIDTH +: DATA_WIDTH];
                OP_WO:
                    shared_matrix_b[col*DATA_WIDTH +: DATA_WIDTH] =
                        attn_context_vec[col*DATA_WIDTH +: DATA_WIDTH];
                OP_FC1:
                    shared_matrix_b[col*DATA_WIDTH +: DATA_WIDTH] =
                        rms1_vec[col*DATA_WIDTH +: DATA_WIDTH];
                OP_FC2:
                    shared_matrix_b[col*DATA_WIDTH +: DATA_WIDTH] =
                        mlp_relu_vec[(int'(shared_col_base) + col)*DATA_WIDTH +: DATA_WIDTH];
                OP_LM:
                    shared_matrix_b[col*DATA_WIDTH +: DATA_WIDTH] =
                        mlp_residual_vec[col*DATA_WIDTH +: DATA_WIDTH];
                default:
                    shared_matrix_b[col*DATA_WIDTH +: DATA_WIDTH] = '0;
            endcase
        end
    end



    assign busy = (state != ST_IDLE);
    assign valid_out = (state == ST_DONE);
    embedding_lookup #(
        .VOCAB_SIZE(VOCAB_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .N_EMBD(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .SUM_WIDTH(EMB_WIDTH),
        .WTE_INIT_FILE(WTE_INIT_FILE),
        .WPE_INIT_FILE(WPE_INIT_FILE)
    ) embedding_lookup_i (
        .clk(clk),
        .rst_n(rst_l),
        .valid_in(embed_valid_in),
        .token_id(token_id),
        .pos_id(pos_id),
        .valid_out(embed_valid_out),
        .embedding(embedding_vec)
    );

    rmsnorm #(
        .N_EMBD(N_EMBD),
        .IN_WIDTH(EMB_WIDTH),
        .OUT_WIDTH(DATA_WIDTH),
        .FRAC_BITS(12)
    ) rmsnorm0_i (
        .clk(clk),
        .rst_l(rst_l),
        .valid_in(rms0_valid_in),
        .x_in(embedding_vec),
        .valid_out(rms0_valid_out),
        .x_out(rms0_vec)
    );

    matmul_unit #(
        .M(N_EMBD),
        .K(N_EMBD),
        .N(1),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .LANES(N_EMBD)
    ) shared_linear_matmul_i (
        .clk(clk),
        .rst_l(rst_l),
        .start(shared_matmul_start),
        .busy(shared_matmul_busy),
        .valid_out(shared_matmul_valid),
        .matrix_a(shared_matrix_a),
        .matrix_b(shared_matrix_b),
        .matrix_c(shared_matrix_c)
    );

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            shared_op       <= OP_NONE;
            shared_row_base <= '0;
            shared_col_base <= '0;
            shared_started  <= 1'b0;

            q_vec       <= '0;
            k_vec       <= '0;
            v_vec       <= '0;
            attn_wo_vec <= '0;
            mlp_fc1_vec <= '0;
            mlp_fc2_vec <= '0;
            lm_logits_vec <= '0;

            for (int i = 0; i < N_EMBD; i++) begin
                fc2_acc[i] <= '0;
            end
        end else begin
            if (shared_matmul_start) begin
                shared_started <= 1'b1;

                case (state)
                    ST_ATTN_Q:  shared_op <= OP_Q;
                    ST_ATTN_K:  shared_op <= OP_K;
                    ST_ATTN_V:  shared_op <= OP_V;
                    ST_ATTN_WO: shared_op <= OP_WO;
                    ST_MLP_FC1: shared_op <= OP_FC1;
                    ST_MLP_FC2: shared_op <= OP_FC2;
                    ST_LM_HEAD: shared_op <= OP_LM;
                    default:    shared_op <= OP_NONE;
                endcase
            end

            if (shared_matmul_valid) begin
                shared_started <= 1'b0;

                case (shared_op)
                    OP_Q: begin
                        q_vec <= shared_matrix_c;
                        shared_row_base <= '0;
                    end

                    OP_K: begin
                        k_vec <= shared_matrix_c;
                        shared_row_base <= '0;
                    end

                    OP_V: begin
                        v_vec <= shared_matrix_c;
                        shared_row_base <= '0;
                    end

                    OP_WO: begin
                        attn_wo_vec <= shared_matrix_c;
                        shared_row_base <= '0;
                    end

                    OP_FC1: begin
                        for (int i = 0; i < N_EMBD; i++) begin
                            mlp_fc1_vec[(int'(shared_row_base) + i)*DATA_WIDTH +: DATA_WIDTH] <=
                                shared_matrix_c[i*DATA_WIDTH +: DATA_WIDTH];
                        end

                        if (shared_row_base == 6'd48)
                            shared_row_base <= '0;
                        else
                            shared_row_base <= shared_row_base + 6'd16;
                    end

                    OP_FC2: begin
                        for (int i = 0; i < N_EMBD; i++) begin
                            if (shared_col_base == 6'd48) begin
                                mlp_fc2_vec[i*DATA_WIDTH +: DATA_WIDTH] <=
                                    sat16(
                                        fc2_acc[i] +
                                        extend_data($signed(shared_matrix_c[i*DATA_WIDTH +: DATA_WIDTH]))
                                    );
                                fc2_acc[i] <= '0;
                            end else begin
                                fc2_acc[i] <= fc2_acc[i] +
                                    extend_data($signed(shared_matrix_c[i*DATA_WIDTH +: DATA_WIDTH]));
                            end
                        end

                        if (shared_col_base == 6'd48)
                            shared_col_base <= '0;
                        else
                            shared_col_base <= shared_col_base + 6'd16;
                    end

                    OP_LM: begin
                        for (int i = 0; i < N_EMBD; i++) begin
                            if ((int'(shared_row_base) + i) < VOCAB_SIZE)
                                lm_logits_vec[(int'(shared_row_base) + i)*DATA_WIDTH +: DATA_WIDTH] <=
                                    shared_matrix_c[i*DATA_WIDTH +: DATA_WIDTH];
                        end

                        if (shared_row_base == 6'd16)
                            shared_row_base <= '0;
                        else
                            shared_row_base <= shared_row_base + 6'd16;
                    end

                    default: begin
                    end
                endcase
            end

            if ((state == ST_RMS0) && rms0_valid_out) begin
                shared_row_base <= '0;
                shared_col_base <= '0;
            end

            if ((state == ST_ATTN_Q) && q_valid)
                shared_row_base <= '0;

            if ((state == ST_ATTN_K) && k_valid)
                shared_row_base <= '0;

            if ((state == ST_ATTN_VALUE) && attn_value_valid)
                shared_row_base <= '0;

            if ((state == ST_RMS1) && rms1_valid_out) begin
                shared_row_base <= '0;
                shared_col_base <= '0;
            end

            if (state == ST_MLP_RELU) begin
                shared_row_base <= '0;
                shared_col_base <= '0;
                for (int i = 0; i < N_EMBD; i++) begin
                    fc2_acc[i] <= '0;
                end
            end

            if (state == ST_MLP_RESIDUAL)
                shared_row_base <= '0;
        end
    end

    kv_cache #(
        .BLOCK_SIZE(BLOCK_SIZE),
        .N_EMBD(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH)
    ) kv_cache_i (
        .clk(clk),
        .rst_l(rst_l),

        .clear(clear_kv_cache),

        .write_en(kv_write_en),
        .write_pos(pos_id),
        .key_in(k_vec),
        .value_in(v_vec),

        .keys_out(keys_cache),
        .values_out(values_cache)
    );

    attention_score #(
      .BLOCK_SIZE(BLOCK_SIZE),
      .N_EMBD(N_EMBD),
      .N_HEAD(N_HEAD),
      .HEAD_DIM(HEAD_DIM),
      .DATA_WIDTH(DATA_WIDTH),
      .ACC_WIDTH(64),
      .FRAC_BITS(12)
    ) attention_score_i (
        .clk(clk),
        .rst_l(rst_l),
        .start(attn_score_start),
        .busy(attn_score_busy),
        .valid_out(attn_score_valid),

        .pos_id(pos_id),
        .q_vec(q_vec),
        .keys_cache(keys_cache),

        .attn_logits(attn_logits)
    );

    assign attn_softmax_busy = |attn_softmax_head_busy;
    assign attn_softmax_valid = &attn_softmax_head_valid;
    assign attn_value_busy = |attn_value_head_busy;
    assign attn_value_valid = &attn_value_head_valid;

    always_comb begin
        attn_probs = '0;
        attn_context_vec = '0;

        for (int head = 0; head < N_HEAD; head++) begin
            attn_logits_head[head] =
                attn_logits[(head*BLOCK_SIZE*DATA_WIDTH) +: BLOCK_SIZE*DATA_WIDTH];
            attn_probs[(head*BLOCK_SIZE*DATA_WIDTH) +: BLOCK_SIZE*DATA_WIDTH] =
                attn_probs_head[head];
            attn_probs_head_signed[head] = attn_probs_head[head];
            value_head_matrix[head] = '0;

            for (int pos = 0; pos < BLOCK_SIZE; pos++) begin
                for (int dim = 0; dim < HEAD_DIM; dim++) begin
                    value_head_matrix[head][((pos*HEAD_DIM + dim) * DATA_WIDTH) +: DATA_WIDTH] =
                        values_cache[((pos*N_EMBD + head*HEAD_DIM + dim) * DATA_WIDTH) +: DATA_WIDTH];
                end
            end

            for (int dim = 0; dim < HEAD_DIM; dim++) begin
                attn_context_vec[((head*HEAD_DIM + dim) * DATA_WIDTH) +: DATA_WIDTH] =
                    context_head_vec[head][dim*DATA_WIDTH +: DATA_WIDTH];
            end
        end
    end

    genvar attn_head_gen;
    generate
        for (attn_head_gen = 0; attn_head_gen < N_HEAD; attn_head_gen++) begin : gen_attention_softmax_value
            softmax_unit #(
                .VECTOR_SIZE(BLOCK_SIZE),
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(32),
                .FRAC_BITS(FRAC_BITS),
                .EXP_INIT_FILE(EXP_INIT_FILE)
            ) attn_softmax_i (
                .clk(clk),
                .rst_l(rst_l),
                .start(attn_softmax_start),
                .busy(attn_softmax_head_busy[attn_head_gen]),
                .valid_out(attn_softmax_head_valid[attn_head_gen]),
                .logits(attn_logits_head[attn_head_gen]),
                .probs(attn_probs_head[attn_head_gen])
            );

            matmul_unit #(
                .M(1),
                .K(BLOCK_SIZE),
                .N(HEAD_DIM),
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(ACC_WIDTH),
                .FRAC_BITS(FRAC_BITS)
            ) attn_value_matmul_i (
                .clk(clk),
                .rst_l(rst_l),
                .start(attn_value_start),
                .busy(attn_value_head_busy[attn_head_gen]),
                .valid_out(attn_value_head_valid[attn_head_gen]),
                .matrix_a(attn_probs_head_signed[attn_head_gen]),
                .matrix_b(value_head_matrix[attn_head_gen]),
                .matrix_c(context_head_vec[attn_head_gen])
            );
        end
    endgenerate

    always_comb begin
        attn_residual_vec = '0;

        for (int i = 0; i < N_EMBD; i++) begin
            attn_residual_vec[i*DATA_WIDTH +: DATA_WIDTH] =
                sat_add16(
                    rms0_vec[i*DATA_WIDTH +: DATA_WIDTH],
                    attn_wo_vec[i*DATA_WIDTH +: DATA_WIDTH]
                );
        end
    end

    rmsnorm #(
        .N_EMBD(N_EMBD),
        .IN_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) rmsnorm1_i (
        .clk(clk),
        .rst_l(rst_l),
        .valid_in(rms1_valid_in),
        .x_in(attn_residual_vec),
        .valid_out(rms1_valid_out),
        .x_out(rms1_vec)
    );

    relu #(
        .VECTOR_SIZE(MLP_HIDDEN),
        .DATA_WIDTH(DATA_WIDTH)
    ) mlp_relu_i (
        .x_in(mlp_fc1_vec),
        .x_out(mlp_relu_vec)
    );

    always_comb begin
        mlp_residual_vec = '0;

        for (int i = 0; i < N_EMBD; i++) begin
            mlp_residual_vec[i*DATA_WIDTH +: DATA_WIDTH] =
                sat_add16(
                    attn_residual_vec[i*DATA_WIDTH +: DATA_WIDTH],
                    mlp_fc2_vec[i*DATA_WIDTH +: DATA_WIDTH]
                );
        end
    end

    softmax_unit #(
        .VECTOR_SIZE(VOCAB_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(32),
        .FRAC_BITS(FRAC_BITS),
        .EXP_INIT_FILE(EXP_INIT_FILE)
    ) final_softmax_i (
        .clk(clk),
        .rst_l(rst_l),
        .start(final_softmax_start),
        .busy(final_softmax_busy),
        .valid_out(final_softmax_valid),
        .logits(lm_logits_vec),
        .probs(final_probs_vec)
    );

    always_comb begin
        argmax_token = '0;
        argmax_value = $signed(final_probs_vec[0 +: DATA_WIDTH]);

        for (int i = 1; i < VOCAB_SIZE; i++) begin
            if ($signed(final_probs_vec[i*DATA_WIDTH +: DATA_WIDTH]) > argmax_value) begin
                argmax_value = $signed(final_probs_vec[i*DATA_WIDTH +: DATA_WIDTH]);
                argmax_token = TOKEN_WIDTH'(i);
            end
        end
    end

    assign logits_out = lm_logits_vec;
    assign probs_out = final_probs_vec;
    assign next_token = argmax_token;
    assign end_token = (argmax_token == TOKEN_WIDTH'(VOCAB_SIZE - 1));


    always_ff@(posedge clk, negedge rst_l) begin
        if(~rst_l) begin
            state <= ST_IDLE;
        end else begin
            state <= nState;
        end
    end

    always_comb begin

        unique case(state)
            ST_IDLE: begin
                if(start) nState = ST_EMBED;
                else nState = ST_IDLE;
            end
            ST_EMBED: begin
                if(embed_valid_out) nState = ST_RMS0;
                else nState = ST_EMBED;
            end
            ST_RMS0: begin
                if(rms0_valid_out) nState = ST_ATTN_Q;
                else nState = ST_RMS0;
            end
            ST_ATTN_Q: begin
                if(q_valid) nState = ST_ATTN_K;
                else nState = ST_ATTN_Q;
            end

            ST_ATTN_K: begin
                if(k_valid) nState = ST_ATTN_V;
                else nState = ST_ATTN_K;
            end

            ST_ATTN_V: begin
                if(v_valid) nState = ST_KV_WRITE;
                else nState = ST_ATTN_V;
            end

            ST_KV_WRITE: begin
                nState = ST_ATTN_SCORE;
            end

            ST_ATTN_SCORE: begin
                if (attn_score_valid) nState = ST_ATTN_SOFTMAX;
                else nState = ST_ATTN_SCORE;
            end

            ST_ATTN_SOFTMAX: begin
                if (attn_softmax_valid) nState = ST_ATTN_VALUE;
                else nState = ST_ATTN_SOFTMAX;
            end

            ST_ATTN_VALUE: begin
                if (attn_value_valid) nState = ST_ATTN_WO;
                else nState = ST_ATTN_VALUE;
            end

            ST_ATTN_WO: begin
                if (attn_wo_valid) nState = ST_ATTN_RESIDUAL;
                else nState = ST_ATTN_WO;
            end

            ST_ATTN_RESIDUAL: begin
                nState = ST_RMS1;
            end

            ST_RMS1: begin
                if (rms1_valid_out) nState = ST_MLP_FC1;
                else nState = ST_RMS1;
            end

            ST_MLP_FC1: begin
                if (mlp_fc1_valid) nState = ST_MLP_RELU;
                else nState = ST_MLP_FC1;
            end

            ST_MLP_RELU: begin
                nState = ST_MLP_FC2;
            end

            ST_MLP_FC2: begin
                if (mlp_fc2_valid) nState = ST_MLP_RESIDUAL;
                else nState = ST_MLP_FC2;
            end

            ST_MLP_RESIDUAL: begin
                nState = ST_LM_HEAD;
            end

            ST_LM_HEAD: begin
                if (lm_head_valid) nState = ST_SOFTMAX;
                else nState = ST_LM_HEAD;
            end

            ST_SOFTMAX: begin
                if (final_softmax_valid) nState = ST_SELECT_TOKEN;
                else nState = ST_SOFTMAX;
            end

            ST_SELECT_TOKEN: begin
                nState = ST_DONE;
            end

            ST_DONE: begin
                nState = ST_IDLE;
            end
            default: begin
                nState = ST_IDLE;
            end
        endcase
    end

    always_comb begin
        embed_valid_in = 1'b0;
        rms0_valid_in = 1'b0;
        rms1_valid_in = 1'b0;

        q_start = 1'b0;
        k_start = 1'b0;
        v_start = 1'b0;

        kv_write_en = 1'b0;
        attn_score_start = 1'b0;
        attn_softmax_start = 1'b0;
        attn_value_start = 1'b0;
        attn_wo_start = 1'b0;
        mlp_fc1_start = 1'b0;
        mlp_fc2_start = 1'b0;
        lm_head_start = 1'b0;
        final_softmax_start = 1'b0;

        unique case(state)
            ST_IDLE: begin
                if(start) embed_valid_in = 1'b1;
            end
            ST_EMBED: begin
                if(embed_valid_out) rms0_valid_in = 1'b1;
            end
            ST_RMS0: begin
                if(rms0_valid_out) q_start = 1'b1;
            end
            ST_ATTN_Q: begin
                if(q_valid) k_start = 1'b1;
            end
            ST_ATTN_K: begin
                if(k_valid) v_start = 1'b1;
            end
            ST_ATTN_V: begin
                if(v_valid) kv_write_en = 1'b1;
            end
            ST_KV_WRITE: begin
                attn_score_start = 1'b1;
            end

            ST_ATTN_SCORE: begin
                if (attn_score_valid) begin
                    attn_softmax_start = 1'b1;
                end
            end

            ST_ATTN_SOFTMAX: begin
                if (attn_softmax_valid) begin
                    attn_value_start = 1'b1;
                end
            end

            ST_ATTN_VALUE: begin
                if (attn_value_valid) begin
                    attn_wo_start = 1'b1;
                end
            end

            ST_ATTN_WO: begin
                // Wait for the output projection to finish.
            end

            ST_ATTN_RESIDUAL: begin
                rms1_valid_in = 1'b1;
            end

            ST_RMS1: begin
                if (rms1_valid_out) begin
                    mlp_fc1_start = 1'b1;
                end
            end

            ST_MLP_FC1: begin
                // Wait for the first MLP projection to finish.
            end

            ST_MLP_RELU: begin
                mlp_fc2_start = 1'b1;
            end

            ST_MLP_FC2: begin
                // Wait for the second MLP projection to finish.
            end

            ST_MLP_RESIDUAL: begin
                lm_head_start = 1'b1;
            end

            ST_LM_HEAD: begin
                if (lm_head_valid) begin
                    final_softmax_start = 1'b1;
                end
            end

            ST_SOFTMAX: begin
                // Wait for the final softmax to finish.
            end

            ST_SELECT_TOKEN: begin
                // Token selection is combinational.
            end

            ST_DONE: begin
                // valid_out is asserted from the state register.
            end
            default: begin
            end
        endcase
    end


endmodule : top_inference
