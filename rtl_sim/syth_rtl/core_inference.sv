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
      parameter string EXP_INIT_FILE = "exp_lut.mem"
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

    logic embed_start;
    logic embed_busy;
    logic embed_valid_out;
    logic token_bram_en;
    logic [8:0] token_bram_addr;
    logic [DATA_WIDTH-1:0] token_bram_dout;
    logic pos_bram_en;
    logic [8:0] pos_bram_addr;
    logic [DATA_WIDTH-1:0] pos_bram_dout;
    logic signed [N_EMBD*DATA_WIDTH-1:0] token_embedding;
    logic signed [N_EMBD*DATA_WIDTH-1:0] position_embedding;
    logic signed [N_EMBD*EMB_WIDTH-1:0] embedding_vec;

    localparam int MLP_HIDDEN = 4 * N_EMBD;
    localparam int LINEAR_ADDR_Q  = (N_EMBD <= 1) ? 1 : $clog2(N_EMBD);
    localparam int LINEAR_ADDR_FC2 = (MLP_HIDDEN <= 1) ? 1 : $clog2(MLP_HIDDEN);

    logic [N_EMBD-1:0] q_weight_en;
    logic [N_EMBD*LINEAR_ADDR_Q-1:0] q_weight_addr;
    logic [N_EMBD*DATA_WIDTH-1:0] q_weight_dout;

    logic [N_EMBD-1:0] k_weight_en;
    logic [N_EMBD*LINEAR_ADDR_Q-1:0] k_weight_addr;
    logic [N_EMBD*DATA_WIDTH-1:0] k_weight_dout;

    logic [N_EMBD-1:0] v_weight_en;
    logic [N_EMBD*LINEAR_ADDR_Q-1:0] v_weight_addr;
    logic [N_EMBD*DATA_WIDTH-1:0] v_weight_dout;

    logic [N_EMBD-1:0] wo_weight_en;
    logic [N_EMBD*LINEAR_ADDR_Q-1:0] wo_weight_addr;
    logic [N_EMBD*DATA_WIDTH-1:0] wo_weight_dout;

    logic [MLP_HIDDEN-1:0] fc1_weight_en;
    logic [MLP_HIDDEN*LINEAR_ADDR_Q-1:0] fc1_weight_addr;
    logic [MLP_HIDDEN*DATA_WIDTH-1:0] fc1_weight_dout;

    logic [N_EMBD-1:0] fc2_weight_en;
    logic [N_EMBD*LINEAR_ADDR_FC2-1:0] fc2_weight_addr;
    logic [N_EMBD*DATA_WIDTH-1:0] fc2_weight_dout;

    logic [VOCAB_SIZE-1:0] lm_weight_en;
    logic [VOCAB_SIZE*LINEAR_ADDR_Q-1:0] lm_weight_addr;
    logic [VOCAB_SIZE*DATA_WIDTH-1:0] lm_weight_dout;

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

    localparam int ATTN_VALUE_FEED_CYCLES = BLOCK_SIZE + HEAD_DIM - 1;
    localparam int ATTN_VALUE_COUNT_WIDTH =
        (ATTN_VALUE_FEED_CYCLES <= 1) ? 1 : $clog2(ATTN_VALUE_FEED_CYCLES);

    typedef enum logic [2:0] {
        ST_VALUE_FEED_IDLE,
        ST_VALUE_FEED_WAIT_1,
        ST_VALUE_FEED_WAIT_2,
        ST_VALUE_FEED_RUN,
        ST_VALUE_FEED_WAIT_RESULT
    } attn_value_feed_state_t;

    attn_value_feed_state_t attn_value_feed_state;
    logic [ATTN_VALUE_COUNT_WIDTH-1:0] attn_value_feed_count;
    logic attn_value_feed_valid;
    logic attn_value_feed_last;
    logic signed [DATA_WIDTH-1:0] attn_value_a_feed [0:N_HEAD-1];
    logic signed [HEAD_DIM*DATA_WIDTH-1:0] attn_value_b_feed [0:N_HEAD-1];

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




    assign busy = (state != ST_IDLE);
    assign valid_out = (state == ST_DONE);
    embedding_bram_reader #(
        .VOCAB_SIZE(VOCAB_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .N_EMBD(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(9)
    ) embedding_reader_i (
        .clk(clk),
        .rst_n(rst_l),
        .start(embed_start),
        .token_id(token_id),
        .pos_id(pos_id),
        .token_bram_en(token_bram_en),
        .token_bram_addr(token_bram_addr),
        .token_bram_dout(token_bram_dout),
        .pos_bram_en(pos_bram_en),
        .pos_bram_addr(pos_bram_addr),
        .pos_bram_dout(pos_bram_dout),
        .busy(embed_busy),
        .valid_out(embed_valid_out),
        .token_embedding(token_embedding),
        .position_embedding(position_embedding)
    );

    blk_mem_gen_0 token_embedding_bram (
        .clka(clk),
        .ena(token_bram_en),
        .addra(token_bram_addr),
        .douta(token_bram_dout),
        .dina('0),
        .wea(1'b0)
    );

    blk_mem_gen_1 position_embedding_bram (
        .clka(clk),
        .ena(pos_bram_en),
        .addra(pos_bram_addr),
        .douta(pos_bram_dout),
        .dina('0),
        .wea(1'b0)
    );

    // Weight BRAMs. Each BRAM stores one output column: W[k][column].

    // Q weight columns
    blk_mem_gen_q_0 q_weight_bram_0 (
        .clka  (clk),
        .ena   (q_weight_en[0]),
        .addra (q_weight_addr[0*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[0*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_1 q_weight_bram_1 (
        .clka  (clk),
        .ena   (q_weight_en[1]),
        .addra (q_weight_addr[1*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[1*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_2 q_weight_bram_2 (
        .clka  (clk),
        .ena   (q_weight_en[2]),
        .addra (q_weight_addr[2*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[2*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_3 q_weight_bram_3 (
        .clka  (clk),
        .ena   (q_weight_en[3]),
        .addra (q_weight_addr[3*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[3*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_4 q_weight_bram_4 (
        .clka  (clk),
        .ena   (q_weight_en[4]),
        .addra (q_weight_addr[4*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[4*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_5 q_weight_bram_5 (
        .clka  (clk),
        .ena   (q_weight_en[5]),
        .addra (q_weight_addr[5*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[5*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_6 q_weight_bram_6 (
        .clka  (clk),
        .ena   (q_weight_en[6]),
        .addra (q_weight_addr[6*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[6*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_7 q_weight_bram_7 (
        .clka  (clk),
        .ena   (q_weight_en[7]),
        .addra (q_weight_addr[7*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[7*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_8 q_weight_bram_8 (
        .clka  (clk),
        .ena   (q_weight_en[8]),
        .addra (q_weight_addr[8*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[8*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_9 q_weight_bram_9 (
        .clka  (clk),
        .ena   (q_weight_en[9]),
        .addra (q_weight_addr[9*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[9*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_10 q_weight_bram_10 (
        .clka  (clk),
        .ena   (q_weight_en[10]),
        .addra (q_weight_addr[10*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[10*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_11 q_weight_bram_11 (
        .clka  (clk),
        .ena   (q_weight_en[11]),
        .addra (q_weight_addr[11*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[11*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_12 q_weight_bram_12 (
        .clka  (clk),
        .ena   (q_weight_en[12]),
        .addra (q_weight_addr[12*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[12*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_13 q_weight_bram_13 (
        .clka  (clk),
        .ena   (q_weight_en[13]),
        .addra (q_weight_addr[13*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[13*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_14 q_weight_bram_14 (
        .clka  (clk),
        .ena   (q_weight_en[14]),
        .addra (q_weight_addr[14*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[14*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_q_15 q_weight_bram_15 (
        .clka  (clk),
        .ena   (q_weight_en[15]),
        .addra (q_weight_addr[15*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (q_weight_dout[15*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );

    // K weight columns
    blk_mem_gen_k_0 k_weight_bram_0 (
        .clka  (clk),
        .ena   (k_weight_en[0]),
        .addra (k_weight_addr[0*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[0*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_1 k_weight_bram_1 (
        .clka  (clk),
        .ena   (k_weight_en[1]),
        .addra (k_weight_addr[1*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[1*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_2 k_weight_bram_2 (
        .clka  (clk),
        .ena   (k_weight_en[2]),
        .addra (k_weight_addr[2*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[2*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_3 k_weight_bram_3 (
        .clka  (clk),
        .ena   (k_weight_en[3]),
        .addra (k_weight_addr[3*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[3*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_4 k_weight_bram_4 (
        .clka  (clk),
        .ena   (k_weight_en[4]),
        .addra (k_weight_addr[4*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[4*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_5 k_weight_bram_5 (
        .clka  (clk),
        .ena   (k_weight_en[5]),
        .addra (k_weight_addr[5*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[5*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_6 k_weight_bram_6 (
        .clka  (clk),
        .ena   (k_weight_en[6]),
        .addra (k_weight_addr[6*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[6*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_7 k_weight_bram_7 (
        .clka  (clk),
        .ena   (k_weight_en[7]),
        .addra (k_weight_addr[7*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[7*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_8 k_weight_bram_8 (
        .clka  (clk),
        .ena   (k_weight_en[8]),
        .addra (k_weight_addr[8*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[8*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_9 k_weight_bram_9 (
        .clka  (clk),
        .ena   (k_weight_en[9]),
        .addra (k_weight_addr[9*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[9*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_10 k_weight_bram_10 (
        .clka  (clk),
        .ena   (k_weight_en[10]),
        .addra (k_weight_addr[10*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[10*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_11 k_weight_bram_11 (
        .clka  (clk),
        .ena   (k_weight_en[11]),
        .addra (k_weight_addr[11*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[11*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_12 k_weight_bram_12 (
        .clka  (clk),
        .ena   (k_weight_en[12]),
        .addra (k_weight_addr[12*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[12*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_13 k_weight_bram_13 (
        .clka  (clk),
        .ena   (k_weight_en[13]),
        .addra (k_weight_addr[13*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[13*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_14 k_weight_bram_14 (
        .clka  (clk),
        .ena   (k_weight_en[14]),
        .addra (k_weight_addr[14*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[14*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_k_15 k_weight_bram_15 (
        .clka  (clk),
        .ena   (k_weight_en[15]),
        .addra (k_weight_addr[15*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (k_weight_dout[15*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );

    // V weight columns
    blk_mem_gen_v_0 v_weight_bram_0 (
        .clka  (clk),
        .ena   (v_weight_en[0]),
        .addra (v_weight_addr[0*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[0*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_1 v_weight_bram_1 (
        .clka  (clk),
        .ena   (v_weight_en[1]),
        .addra (v_weight_addr[1*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[1*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_2 v_weight_bram_2 (
        .clka  (clk),
        .ena   (v_weight_en[2]),
        .addra (v_weight_addr[2*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[2*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_3 v_weight_bram_3 (
        .clka  (clk),
        .ena   (v_weight_en[3]),
        .addra (v_weight_addr[3*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[3*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_4 v_weight_bram_4 (
        .clka  (clk),
        .ena   (v_weight_en[4]),
        .addra (v_weight_addr[4*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[4*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_5 v_weight_bram_5 (
        .clka  (clk),
        .ena   (v_weight_en[5]),
        .addra (v_weight_addr[5*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[5*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_6 v_weight_bram_6 (
        .clka  (clk),
        .ena   (v_weight_en[6]),
        .addra (v_weight_addr[6*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[6*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_7 v_weight_bram_7 (
        .clka  (clk),
        .ena   (v_weight_en[7]),
        .addra (v_weight_addr[7*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[7*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_8 v_weight_bram_8 (
        .clka  (clk),
        .ena   (v_weight_en[8]),
        .addra (v_weight_addr[8*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[8*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_9 v_weight_bram_9 (
        .clka  (clk),
        .ena   (v_weight_en[9]),
        .addra (v_weight_addr[9*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[9*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_10 v_weight_bram_10 (
        .clka  (clk),
        .ena   (v_weight_en[10]),
        .addra (v_weight_addr[10*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[10*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_11 v_weight_bram_11 (
        .clka  (clk),
        .ena   (v_weight_en[11]),
        .addra (v_weight_addr[11*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[11*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_12 v_weight_bram_12 (
        .clka  (clk),
        .ena   (v_weight_en[12]),
        .addra (v_weight_addr[12*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[12*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_13 v_weight_bram_13 (
        .clka  (clk),
        .ena   (v_weight_en[13]),
        .addra (v_weight_addr[13*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[13*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_14 v_weight_bram_14 (
        .clka  (clk),
        .ena   (v_weight_en[14]),
        .addra (v_weight_addr[14*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[14*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_v_15 v_weight_bram_15 (
        .clka  (clk),
        .ena   (v_weight_en[15]),
        .addra (v_weight_addr[15*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (v_weight_dout[15*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );

    // WO weight columns
    blk_mem_gen_wo_0 wo_weight_bram_0 (
        .clka  (clk),
        .ena   (wo_weight_en[0]),
        .addra (wo_weight_addr[0*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[0*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_1 wo_weight_bram_1 (
        .clka  (clk),
        .ena   (wo_weight_en[1]),
        .addra (wo_weight_addr[1*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[1*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_2 wo_weight_bram_2 (
        .clka  (clk),
        .ena   (wo_weight_en[2]),
        .addra (wo_weight_addr[2*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[2*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_3 wo_weight_bram_3 (
        .clka  (clk),
        .ena   (wo_weight_en[3]),
        .addra (wo_weight_addr[3*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[3*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_4 wo_weight_bram_4 (
        .clka  (clk),
        .ena   (wo_weight_en[4]),
        .addra (wo_weight_addr[4*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[4*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_5 wo_weight_bram_5 (
        .clka  (clk),
        .ena   (wo_weight_en[5]),
        .addra (wo_weight_addr[5*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[5*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_6 wo_weight_bram_6 (
        .clka  (clk),
        .ena   (wo_weight_en[6]),
        .addra (wo_weight_addr[6*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[6*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_7 wo_weight_bram_7 (
        .clka  (clk),
        .ena   (wo_weight_en[7]),
        .addra (wo_weight_addr[7*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[7*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_8 wo_weight_bram_8 (
        .clka  (clk),
        .ena   (wo_weight_en[8]),
        .addra (wo_weight_addr[8*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[8*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_9 wo_weight_bram_9 (
        .clka  (clk),
        .ena   (wo_weight_en[9]),
        .addra (wo_weight_addr[9*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[9*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_10 wo_weight_bram_10 (
        .clka  (clk),
        .ena   (wo_weight_en[10]),
        .addra (wo_weight_addr[10*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[10*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_11 wo_weight_bram_11 (
        .clka  (clk),
        .ena   (wo_weight_en[11]),
        .addra (wo_weight_addr[11*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[11*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_12 wo_weight_bram_12 (
        .clka  (clk),
        .ena   (wo_weight_en[12]),
        .addra (wo_weight_addr[12*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[12*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_13 wo_weight_bram_13 (
        .clka  (clk),
        .ena   (wo_weight_en[13]),
        .addra (wo_weight_addr[13*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[13*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_14 wo_weight_bram_14 (
        .clka  (clk),
        .ena   (wo_weight_en[14]),
        .addra (wo_weight_addr[14*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[14*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_wo_15 wo_weight_bram_15 (
        .clka  (clk),
        .ena   (wo_weight_en[15]),
        .addra (wo_weight_addr[15*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (wo_weight_dout[15*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );

    // FC1 weight columns
    blk_mem_gen_fc1_0 fc1_weight_bram_0 (
        .clka  (clk),
        .ena   (fc1_weight_en[0]),
        .addra (fc1_weight_addr[0*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[0*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_1 fc1_weight_bram_1 (
        .clka  (clk),
        .ena   (fc1_weight_en[1]),
        .addra (fc1_weight_addr[1*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[1*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_2 fc1_weight_bram_2 (
        .clka  (clk),
        .ena   (fc1_weight_en[2]),
        .addra (fc1_weight_addr[2*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[2*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_3 fc1_weight_bram_3 (
        .clka  (clk),
        .ena   (fc1_weight_en[3]),
        .addra (fc1_weight_addr[3*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[3*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_4 fc1_weight_bram_4 (
        .clka  (clk),
        .ena   (fc1_weight_en[4]),
        .addra (fc1_weight_addr[4*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[4*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_5 fc1_weight_bram_5 (
        .clka  (clk),
        .ena   (fc1_weight_en[5]),
        .addra (fc1_weight_addr[5*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[5*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_6 fc1_weight_bram_6 (
        .clka  (clk),
        .ena   (fc1_weight_en[6]),
        .addra (fc1_weight_addr[6*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[6*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_7 fc1_weight_bram_7 (
        .clka  (clk),
        .ena   (fc1_weight_en[7]),
        .addra (fc1_weight_addr[7*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[7*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_8 fc1_weight_bram_8 (
        .clka  (clk),
        .ena   (fc1_weight_en[8]),
        .addra (fc1_weight_addr[8*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[8*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_9 fc1_weight_bram_9 (
        .clka  (clk),
        .ena   (fc1_weight_en[9]),
        .addra (fc1_weight_addr[9*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[9*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_10 fc1_weight_bram_10 (
        .clka  (clk),
        .ena   (fc1_weight_en[10]),
        .addra (fc1_weight_addr[10*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[10*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_11 fc1_weight_bram_11 (
        .clka  (clk),
        .ena   (fc1_weight_en[11]),
        .addra (fc1_weight_addr[11*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[11*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_12 fc1_weight_bram_12 (
        .clka  (clk),
        .ena   (fc1_weight_en[12]),
        .addra (fc1_weight_addr[12*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[12*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_13 fc1_weight_bram_13 (
        .clka  (clk),
        .ena   (fc1_weight_en[13]),
        .addra (fc1_weight_addr[13*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[13*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_14 fc1_weight_bram_14 (
        .clka  (clk),
        .ena   (fc1_weight_en[14]),
        .addra (fc1_weight_addr[14*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[14*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_15 fc1_weight_bram_15 (
        .clka  (clk),
        .ena   (fc1_weight_en[15]),
        .addra (fc1_weight_addr[15*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[15*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_16 fc1_weight_bram_16 (
        .clka  (clk),
        .ena   (fc1_weight_en[16]),
        .addra (fc1_weight_addr[16*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[16*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_17 fc1_weight_bram_17 (
        .clka  (clk),
        .ena   (fc1_weight_en[17]),
        .addra (fc1_weight_addr[17*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[17*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_18 fc1_weight_bram_18 (
        .clka  (clk),
        .ena   (fc1_weight_en[18]),
        .addra (fc1_weight_addr[18*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[18*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_19 fc1_weight_bram_19 (
        .clka  (clk),
        .ena   (fc1_weight_en[19]),
        .addra (fc1_weight_addr[19*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[19*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_20 fc1_weight_bram_20 (
        .clka  (clk),
        .ena   (fc1_weight_en[20]),
        .addra (fc1_weight_addr[20*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[20*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_21 fc1_weight_bram_21 (
        .clka  (clk),
        .ena   (fc1_weight_en[21]),
        .addra (fc1_weight_addr[21*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[21*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_22 fc1_weight_bram_22 (
        .clka  (clk),
        .ena   (fc1_weight_en[22]),
        .addra (fc1_weight_addr[22*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[22*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_23 fc1_weight_bram_23 (
        .clka  (clk),
        .ena   (fc1_weight_en[23]),
        .addra (fc1_weight_addr[23*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[23*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_24 fc1_weight_bram_24 (
        .clka  (clk),
        .ena   (fc1_weight_en[24]),
        .addra (fc1_weight_addr[24*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[24*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_25 fc1_weight_bram_25 (
        .clka  (clk),
        .ena   (fc1_weight_en[25]),
        .addra (fc1_weight_addr[25*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[25*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_26 fc1_weight_bram_26 (
        .clka  (clk),
        .ena   (fc1_weight_en[26]),
        .addra (fc1_weight_addr[26*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[26*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_27 fc1_weight_bram_27 (
        .clka  (clk),
        .ena   (fc1_weight_en[27]),
        .addra (fc1_weight_addr[27*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[27*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_28 fc1_weight_bram_28 (
        .clka  (clk),
        .ena   (fc1_weight_en[28]),
        .addra (fc1_weight_addr[28*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[28*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_29 fc1_weight_bram_29 (
        .clka  (clk),
        .ena   (fc1_weight_en[29]),
        .addra (fc1_weight_addr[29*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[29*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_30 fc1_weight_bram_30 (
        .clka  (clk),
        .ena   (fc1_weight_en[30]),
        .addra (fc1_weight_addr[30*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[30*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_31 fc1_weight_bram_31 (
        .clka  (clk),
        .ena   (fc1_weight_en[31]),
        .addra (fc1_weight_addr[31*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[31*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_32 fc1_weight_bram_32 (
        .clka  (clk),
        .ena   (fc1_weight_en[32]),
        .addra (fc1_weight_addr[32*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[32*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_33 fc1_weight_bram_33 (
        .clka  (clk),
        .ena   (fc1_weight_en[33]),
        .addra (fc1_weight_addr[33*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[33*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_34 fc1_weight_bram_34 (
        .clka  (clk),
        .ena   (fc1_weight_en[34]),
        .addra (fc1_weight_addr[34*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[34*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_35 fc1_weight_bram_35 (
        .clka  (clk),
        .ena   (fc1_weight_en[35]),
        .addra (fc1_weight_addr[35*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[35*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_36 fc1_weight_bram_36 (
        .clka  (clk),
        .ena   (fc1_weight_en[36]),
        .addra (fc1_weight_addr[36*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[36*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_37 fc1_weight_bram_37 (
        .clka  (clk),
        .ena   (fc1_weight_en[37]),
        .addra (fc1_weight_addr[37*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[37*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_38 fc1_weight_bram_38 (
        .clka  (clk),
        .ena   (fc1_weight_en[38]),
        .addra (fc1_weight_addr[38*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[38*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_39 fc1_weight_bram_39 (
        .clka  (clk),
        .ena   (fc1_weight_en[39]),
        .addra (fc1_weight_addr[39*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[39*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_40 fc1_weight_bram_40 (
        .clka  (clk),
        .ena   (fc1_weight_en[40]),
        .addra (fc1_weight_addr[40*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[40*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_41 fc1_weight_bram_41 (
        .clka  (clk),
        .ena   (fc1_weight_en[41]),
        .addra (fc1_weight_addr[41*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[41*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_42 fc1_weight_bram_42 (
        .clka  (clk),
        .ena   (fc1_weight_en[42]),
        .addra (fc1_weight_addr[42*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[42*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_43 fc1_weight_bram_43 (
        .clka  (clk),
        .ena   (fc1_weight_en[43]),
        .addra (fc1_weight_addr[43*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[43*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_44 fc1_weight_bram_44 (
        .clka  (clk),
        .ena   (fc1_weight_en[44]),
        .addra (fc1_weight_addr[44*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[44*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_45 fc1_weight_bram_45 (
        .clka  (clk),
        .ena   (fc1_weight_en[45]),
        .addra (fc1_weight_addr[45*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[45*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_46 fc1_weight_bram_46 (
        .clka  (clk),
        .ena   (fc1_weight_en[46]),
        .addra (fc1_weight_addr[46*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[46*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_47 fc1_weight_bram_47 (
        .clka  (clk),
        .ena   (fc1_weight_en[47]),
        .addra (fc1_weight_addr[47*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[47*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_48 fc1_weight_bram_48 (
        .clka  (clk),
        .ena   (fc1_weight_en[48]),
        .addra (fc1_weight_addr[48*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[48*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_49 fc1_weight_bram_49 (
        .clka  (clk),
        .ena   (fc1_weight_en[49]),
        .addra (fc1_weight_addr[49*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[49*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_50 fc1_weight_bram_50 (
        .clka  (clk),
        .ena   (fc1_weight_en[50]),
        .addra (fc1_weight_addr[50*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[50*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_51 fc1_weight_bram_51 (
        .clka  (clk),
        .ena   (fc1_weight_en[51]),
        .addra (fc1_weight_addr[51*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[51*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_52 fc1_weight_bram_52 (
        .clka  (clk),
        .ena   (fc1_weight_en[52]),
        .addra (fc1_weight_addr[52*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[52*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_53 fc1_weight_bram_53 (
        .clka  (clk),
        .ena   (fc1_weight_en[53]),
        .addra (fc1_weight_addr[53*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[53*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_54 fc1_weight_bram_54 (
        .clka  (clk),
        .ena   (fc1_weight_en[54]),
        .addra (fc1_weight_addr[54*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[54*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_55 fc1_weight_bram_55 (
        .clka  (clk),
        .ena   (fc1_weight_en[55]),
        .addra (fc1_weight_addr[55*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[55*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_56 fc1_weight_bram_56 (
        .clka  (clk),
        .ena   (fc1_weight_en[56]),
        .addra (fc1_weight_addr[56*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[56*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_57 fc1_weight_bram_57 (
        .clka  (clk),
        .ena   (fc1_weight_en[57]),
        .addra (fc1_weight_addr[57*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[57*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_58 fc1_weight_bram_58 (
        .clka  (clk),
        .ena   (fc1_weight_en[58]),
        .addra (fc1_weight_addr[58*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[58*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_59 fc1_weight_bram_59 (
        .clka  (clk),
        .ena   (fc1_weight_en[59]),
        .addra (fc1_weight_addr[59*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[59*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_60 fc1_weight_bram_60 (
        .clka  (clk),
        .ena   (fc1_weight_en[60]),
        .addra (fc1_weight_addr[60*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[60*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_61 fc1_weight_bram_61 (
        .clka  (clk),
        .ena   (fc1_weight_en[61]),
        .addra (fc1_weight_addr[61*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[61*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_62 fc1_weight_bram_62 (
        .clka  (clk),
        .ena   (fc1_weight_en[62]),
        .addra (fc1_weight_addr[62*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[62*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc1_63 fc1_weight_bram_63 (
        .clka  (clk),
        .ena   (fc1_weight_en[63]),
        .addra (fc1_weight_addr[63*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (fc1_weight_dout[63*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );

    // FC2 weight columns
    blk_mem_gen_fc2_0 fc2_weight_bram_0 (
        .clka  (clk),
        .ena   (fc2_weight_en[0]),
        .addra (fc2_weight_addr[0*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[0*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_1 fc2_weight_bram_1 (
        .clka  (clk),
        .ena   (fc2_weight_en[1]),
        .addra (fc2_weight_addr[1*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[1*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_2 fc2_weight_bram_2 (
        .clka  (clk),
        .ena   (fc2_weight_en[2]),
        .addra (fc2_weight_addr[2*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[2*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_3 fc2_weight_bram_3 (
        .clka  (clk),
        .ena   (fc2_weight_en[3]),
        .addra (fc2_weight_addr[3*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[3*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_4 fc2_weight_bram_4 (
        .clka  (clk),
        .ena   (fc2_weight_en[4]),
        .addra (fc2_weight_addr[4*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[4*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_5 fc2_weight_bram_5 (
        .clka  (clk),
        .ena   (fc2_weight_en[5]),
        .addra (fc2_weight_addr[5*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[5*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_6 fc2_weight_bram_6 (
        .clka  (clk),
        .ena   (fc2_weight_en[6]),
        .addra (fc2_weight_addr[6*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[6*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_7 fc2_weight_bram_7 (
        .clka  (clk),
        .ena   (fc2_weight_en[7]),
        .addra (fc2_weight_addr[7*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[7*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_8 fc2_weight_bram_8 (
        .clka  (clk),
        .ena   (fc2_weight_en[8]),
        .addra (fc2_weight_addr[8*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[8*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_9 fc2_weight_bram_9 (
        .clka  (clk),
        .ena   (fc2_weight_en[9]),
        .addra (fc2_weight_addr[9*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[9*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_10 fc2_weight_bram_10 (
        .clka  (clk),
        .ena   (fc2_weight_en[10]),
        .addra (fc2_weight_addr[10*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[10*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_11 fc2_weight_bram_11 (
        .clka  (clk),
        .ena   (fc2_weight_en[11]),
        .addra (fc2_weight_addr[11*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[11*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_12 fc2_weight_bram_12 (
        .clka  (clk),
        .ena   (fc2_weight_en[12]),
        .addra (fc2_weight_addr[12*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[12*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_13 fc2_weight_bram_13 (
        .clka  (clk),
        .ena   (fc2_weight_en[13]),
        .addra (fc2_weight_addr[13*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[13*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_14 fc2_weight_bram_14 (
        .clka  (clk),
        .ena   (fc2_weight_en[14]),
        .addra (fc2_weight_addr[14*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[14*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_fc2_15 fc2_weight_bram_15 (
        .clka  (clk),
        .ena   (fc2_weight_en[15]),
        .addra (fc2_weight_addr[15*LINEAR_ADDR_FC2 +: LINEAR_ADDR_FC2]),
        .douta (fc2_weight_dout[15*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );

    // LM weight columns
    blk_mem_gen_lm_0 lm_weight_bram_0 (
        .clka  (clk),
        .ena   (lm_weight_en[0]),
        .addra (lm_weight_addr[0*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[0*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_1 lm_weight_bram_1 (
        .clka  (clk),
        .ena   (lm_weight_en[1]),
        .addra (lm_weight_addr[1*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[1*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_2 lm_weight_bram_2 (
        .clka  (clk),
        .ena   (lm_weight_en[2]),
        .addra (lm_weight_addr[2*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[2*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_3 lm_weight_bram_3 (
        .clka  (clk),
        .ena   (lm_weight_en[3]),
        .addra (lm_weight_addr[3*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[3*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_4 lm_weight_bram_4 (
        .clka  (clk),
        .ena   (lm_weight_en[4]),
        .addra (lm_weight_addr[4*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[4*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_5 lm_weight_bram_5 (
        .clka  (clk),
        .ena   (lm_weight_en[5]),
        .addra (lm_weight_addr[5*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[5*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_6 lm_weight_bram_6 (
        .clka  (clk),
        .ena   (lm_weight_en[6]),
        .addra (lm_weight_addr[6*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[6*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_7 lm_weight_bram_7 (
        .clka  (clk),
        .ena   (lm_weight_en[7]),
        .addra (lm_weight_addr[7*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[7*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_8 lm_weight_bram_8 (
        .clka  (clk),
        .ena   (lm_weight_en[8]),
        .addra (lm_weight_addr[8*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[8*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_9 lm_weight_bram_9 (
        .clka  (clk),
        .ena   (lm_weight_en[9]),
        .addra (lm_weight_addr[9*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[9*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_10 lm_weight_bram_10 (
        .clka  (clk),
        .ena   (lm_weight_en[10]),
        .addra (lm_weight_addr[10*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[10*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_11 lm_weight_bram_11 (
        .clka  (clk),
        .ena   (lm_weight_en[11]),
        .addra (lm_weight_addr[11*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[11*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_12 lm_weight_bram_12 (
        .clka  (clk),
        .ena   (lm_weight_en[12]),
        .addra (lm_weight_addr[12*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[12*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_13 lm_weight_bram_13 (
        .clka  (clk),
        .ena   (lm_weight_en[13]),
        .addra (lm_weight_addr[13*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[13*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_14 lm_weight_bram_14 (
        .clka  (clk),
        .ena   (lm_weight_en[14]),
        .addra (lm_weight_addr[14*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[14*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_15 lm_weight_bram_15 (
        .clka  (clk),
        .ena   (lm_weight_en[15]),
        .addra (lm_weight_addr[15*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[15*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_16 lm_weight_bram_16 (
        .clka  (clk),
        .ena   (lm_weight_en[16]),
        .addra (lm_weight_addr[16*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[16*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_17 lm_weight_bram_17 (
        .clka  (clk),
        .ena   (lm_weight_en[17]),
        .addra (lm_weight_addr[17*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[17*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_18 lm_weight_bram_18 (
        .clka  (clk),
        .ena   (lm_weight_en[18]),
        .addra (lm_weight_addr[18*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[18*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_19 lm_weight_bram_19 (
        .clka  (clk),
        .ena   (lm_weight_en[19]),
        .addra (lm_weight_addr[19*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[19*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_20 lm_weight_bram_20 (
        .clka  (clk),
        .ena   (lm_weight_en[20]),
        .addra (lm_weight_addr[20*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[20*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_21 lm_weight_bram_21 (
        .clka  (clk),
        .ena   (lm_weight_en[21]),
        .addra (lm_weight_addr[21*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[21*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_22 lm_weight_bram_22 (
        .clka  (clk),
        .ena   (lm_weight_en[22]),
        .addra (lm_weight_addr[22*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[22*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_23 lm_weight_bram_23 (
        .clka  (clk),
        .ena   (lm_weight_en[23]),
        .addra (lm_weight_addr[23*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[23*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_24 lm_weight_bram_24 (
        .clka  (clk),
        .ena   (lm_weight_en[24]),
        .addra (lm_weight_addr[24*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[24*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_25 lm_weight_bram_25 (
        .clka  (clk),
        .ena   (lm_weight_en[25]),
        .addra (lm_weight_addr[25*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[25*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );
    blk_mem_gen_lm_26 lm_weight_bram_26 (
        .clka  (clk),
        .ena   (lm_weight_en[26]),
        .addra (lm_weight_addr[26*LINEAR_ADDR_Q +: LINEAR_ADDR_Q]),
        .douta (lm_weight_dout[26*DATA_WIDTH +: DATA_WIDTH]),
        .dina  ('0),
        .wea   (1'b0)
    );

    always_comb begin
        for (int i = 0; i < N_EMBD; i++) begin
            embedding_vec[i*EMB_WIDTH +: EMB_WIDTH] =
                $signed(token_embedding[i*DATA_WIDTH +: DATA_WIDTH]) +
                $signed(position_embedding[i*DATA_WIDTH +: DATA_WIDTH]);
        end
    end

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

    linear_layer #(
        .IN_FEATURES(N_EMBD),
        .OUT_FEATURES(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .WEIGHT_INIT_FILE(ATTN_WQ_INIT_FILE)
    ) attn_q_linear (
        .clk(clk),
        .rst_l(rst_l),
        .start(q_start),
        .busy(q_busy),
        .valid_out(q_valid),
        .x_in(rms0_vec),
        .y_out(q_vec),
        .weight_bram_en(q_weight_en),
        .weight_bram_addr(q_weight_addr),
        .weight_bram_dout(q_weight_dout)
    );

    linear_layer #(
        .IN_FEATURES(N_EMBD),
        .OUT_FEATURES(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .WEIGHT_INIT_FILE(ATTN_WK_INIT_FILE)
    ) attn_k_linear (
        .clk(clk),
        .rst_l(rst_l),
        .start(k_start),
        .busy(k_busy),
        .valid_out(k_valid),
        .x_in(rms0_vec),
        .y_out(k_vec),
        .weight_bram_en(k_weight_en),
        .weight_bram_addr(k_weight_addr),
        .weight_bram_dout(k_weight_dout)
    );

    linear_layer #(
        .IN_FEATURES(N_EMBD),
        .OUT_FEATURES(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .WEIGHT_INIT_FILE(ATTN_WV_INIT_FILE)
    ) attn_v_linear (
        .clk(clk),
        .rst_l(rst_l),
        .start(v_start),
        .busy(v_busy),
        .valid_out(v_valid),
        .x_in(rms0_vec),
        .y_out(v_vec),
        .weight_bram_en(v_weight_en),
        .weight_bram_addr(v_weight_addr),
        .weight_bram_dout(v_weight_dout)
    );

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

    assign attn_value_feed_valid =
        (attn_value_feed_state == ST_VALUE_FEED_RUN);

    assign attn_value_feed_last =
        attn_value_feed_valid &&
        (attn_value_feed_count == ATTN_VALUE_FEED_CYCLES - 1);

    // The matmul unit enters ST_FLUSH after start. Wait two cycles before
    // supplying the first attention-value feed.
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            attn_value_feed_state <= ST_VALUE_FEED_IDLE;
            attn_value_feed_count <= '0;
        end else begin
            case (attn_value_feed_state)
                ST_VALUE_FEED_IDLE: begin
                    if (attn_value_start) begin
                        attn_value_feed_count <= '0;
                        attn_value_feed_state <= ST_VALUE_FEED_WAIT_1;
                    end
                end

                ST_VALUE_FEED_WAIT_1: begin
                    attn_value_feed_state <= ST_VALUE_FEED_WAIT_2;
                end

                ST_VALUE_FEED_WAIT_2: begin
                    attn_value_feed_count <= '0;
                    attn_value_feed_state <= ST_VALUE_FEED_RUN;
                end

                ST_VALUE_FEED_RUN: begin
                    if (attn_value_feed_count == ATTN_VALUE_FEED_CYCLES - 1) begin
                        attn_value_feed_state <= ST_VALUE_FEED_WAIT_RESULT;
                    end else begin
                        attn_value_feed_count <= attn_value_feed_count + 1'b1;
                    end
                end

                ST_VALUE_FEED_WAIT_RESULT: begin
                    if (attn_value_valid) begin
                        attn_value_feed_state <= ST_VALUE_FEED_IDLE;
                    end
                end

                default: begin
                    attn_value_feed_state <= ST_VALUE_FEED_IDLE;
                    attn_value_feed_count <= '0;
                end
            endcase
        end
    end

    // Feed A and B with the skew required by the horizontal systolic data
    // movement. At cycle t, head column dim receives value position t-dim.
    always_comb begin
        for (int head = 0; head < N_HEAD; head++) begin
            attn_value_a_feed[head] = '0;
            attn_value_b_feed[head] = '0;

            if (attn_value_feed_valid) begin
                if (attn_value_feed_count < BLOCK_SIZE) begin
                    attn_value_a_feed[head] =
                        attn_probs_head_signed[head][
                            attn_value_feed_count*DATA_WIDTH +: DATA_WIDTH];
                end

                for (int dim = 0; dim < HEAD_DIM; dim++) begin
                    if ((attn_value_feed_count >= dim) &&
                        ((attn_value_feed_count - dim) < BLOCK_SIZE)) begin
                        attn_value_b_feed[head][dim*DATA_WIDTH +: DATA_WIDTH] =
                            value_head_matrix[head][
                                (((attn_value_feed_count - dim)*HEAD_DIM + dim) * DATA_WIDTH)
                                +: DATA_WIDTH];
                    end
                end
            end
        end
    end

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
                .a_feed(attn_value_a_feed[attn_head_gen]),
                .b_feed(attn_value_b_feed[attn_head_gen]),
                .feed_valid(attn_value_feed_valid),
                .feed_last(attn_value_feed_last),
                .matrix_c(context_head_vec[attn_head_gen])
            );
        end
    endgenerate

    linear_layer #(
        .IN_FEATURES(N_EMBD),
        .OUT_FEATURES(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .WEIGHT_INIT_FILE(ATTN_WO_INIT_FILE)
    ) attn_wo_linear (
        .clk(clk),
        .rst_l(rst_l),
        .start(attn_wo_start),
        .busy(attn_wo_busy),
        .valid_out(attn_wo_valid),
        .x_in(attn_context_vec),
        .y_out(attn_wo_vec),
        .weight_bram_en(wo_weight_en),
        .weight_bram_addr(wo_weight_addr),
        .weight_bram_dout(wo_weight_dout)
    );

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

    linear_layer #(
        .IN_FEATURES(N_EMBD),
        .OUT_FEATURES(MLP_HIDDEN),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .WEIGHT_INIT_FILE(MLP_FC1_INIT_FILE)
    ) mlp_fc1_linear (
        .clk(clk),
        .rst_l(rst_l),
        .start(mlp_fc1_start),
        .busy(mlp_fc1_busy),
        .valid_out(mlp_fc1_valid),
        .x_in(rms1_vec),
        .y_out(mlp_fc1_vec),
        .weight_bram_en(fc1_weight_en),
        .weight_bram_addr(fc1_weight_addr),
        .weight_bram_dout(fc1_weight_dout)
    );

    relu #(
        .VECTOR_SIZE(MLP_HIDDEN),
        .DATA_WIDTH(DATA_WIDTH)
    ) mlp_relu_i (
        .x_in(mlp_fc1_vec),
        .x_out(mlp_relu_vec)
    );

    linear_layer #(
        .IN_FEATURES(MLP_HIDDEN),
        .OUT_FEATURES(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .WEIGHT_INIT_FILE(MLP_FC2_INIT_FILE)
    ) mlp_fc2_linear (
        .clk(clk),
        .rst_l(rst_l),
        .start(mlp_fc2_start),
        .busy(mlp_fc2_busy),
        .valid_out(mlp_fc2_valid),
        .x_in(mlp_relu_vec),
        .y_out(mlp_fc2_vec),
        .weight_bram_en(fc2_weight_en),
        .weight_bram_addr(fc2_weight_addr),
        .weight_bram_dout(fc2_weight_dout)
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

    linear_layer #(
        .IN_FEATURES(N_EMBD),
        .OUT_FEATURES(VOCAB_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .WEIGHT_INIT_FILE(LM_HEAD_INIT_FILE)
    ) lm_head_linear (
        .clk(clk),
        .rst_l(rst_l),
        .start(lm_head_start),
        .busy(lm_head_busy),
        .valid_out(lm_head_valid),
        .x_in(mlp_residual_vec),
        .y_out(lm_logits_vec),
        .weight_bram_en(lm_weight_en),
        .weight_bram_addr(lm_weight_addr),
        .weight_bram_dout(lm_weight_dout)
    );

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
        embed_start = 1'b0;
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
                if(start) embed_start = 1'b1;
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
