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
    output logic end_token,

    // Current core FSM state for hardware/debug display.
    output logic [5:0] debug_state
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
    localparam int CACHE_PART_WIDTH = (BLOCK_SIZE*N_EMBD*DATA_WIDTH) / 8;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p0;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p1;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p2;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p3;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p4;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p5;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p6;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] k_cache_p7;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p0;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p1;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p2;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p3;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p4;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p5;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p6;
    (* keep = "true" *) logic signed [CACHE_PART_WIDTH-1:0] v_cache_p7;

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
    localparam int TOKEN_ADDR_WIDTH = (VOCAB_SIZE*N_EMBD <= 1) ? 1 : $clog2(VOCAB_SIZE*N_EMBD);
    localparam int POS_ADDR_WIDTH = (BLOCK_SIZE*N_EMBD <= 1) ? 1 : $clog2(BLOCK_SIZE*N_EMBD);
    localparam int QKV_ADDR_WIDTH = (N_EMBD*N_EMBD <= 1) ? 1 : $clog2(N_EMBD*N_EMBD);
    localparam int FC1_ADDR_WIDTH = (N_EMBD*MLP_HIDDEN <= 1) ? 1 : $clog2(N_EMBD*MLP_HIDDEN);
    localparam int FC2_ADDR_WIDTH = (MLP_HIDDEN*N_EMBD <= 1) ? 1 : $clog2(MLP_HIDDEN*N_EMBD);
    localparam int LM_ADDR_WIDTH = (N_EMBD*VOCAB_SIZE <= 1) ? 1 : $clog2(N_EMBD*VOCAB_SIZE);

    logic token_bram_en;
    logic [TOKEN_ADDR_WIDTH-1:0] token_bram_addr;
    logic [DATA_WIDTH-1:0] token_bram_dout;
    logic pos_bram_en;
    logic [POS_ADDR_WIDTH-1:0] pos_bram_addr;
    logic [DATA_WIDTH-1:0] pos_bram_dout;

    logic q_bram_en;
    logic [QKV_ADDR_WIDTH-1:0] q_bram_addr;
    logic [DATA_WIDTH-1:0] q_bram_dout;
    logic k_bram_en;
    logic [QKV_ADDR_WIDTH-1:0] k_bram_addr;
    logic [DATA_WIDTH-1:0] k_bram_dout;
    logic v_bram_en;
    logic [QKV_ADDR_WIDTH-1:0] v_bram_addr;
    logic [DATA_WIDTH-1:0] v_bram_dout;
    logic wo_bram_en;
    logic [QKV_ADDR_WIDTH-1:0] wo_bram_addr;
    logic [DATA_WIDTH-1:0] wo_bram_dout;
    logic fc1_bram_en;
    logic [FC1_ADDR_WIDTH-1:0] fc1_bram_addr;
    logic [DATA_WIDTH-1:0] fc1_bram_dout;
    logic fc2_bram_en;
    logic [FC2_ADDR_WIDTH-1:0] fc2_bram_addr;
    logic [DATA_WIDTH-1:0] fc2_bram_dout;
    logic lm_bram_en;
    logic [LM_ADDR_WIDTH-1:0] lm_bram_addr;
    logic [DATA_WIDTH-1:0] lm_bram_dout;

    // One shared BRAM tile reader and one shared 16-lane matmul are reused
    // by all linear projections.  The reader address is widened to the
    // largest weight-memory address and narrowed at each BRAM port below.
    localparam int MAX_WEIGHT_ADDR_WIDTH = FC2_ADDR_WIDTH;
    logic shared_reader_start;
    logic shared_reader_busy;
    logic shared_reader_valid;
    logic shared_reader_en;
    logic [MAX_WEIGHT_ADDR_WIDTH-1:0] shared_reader_addr;
    logic [MAX_WEIGHT_ADDR_WIDTH-1:0] shared_base_addr;
    logic [MAX_WEIGHT_ADDR_WIDTH-1:0] shared_row_stride;
    logic [MAX_WEIGHT_ADDR_WIDTH-1:0] shared_col_offset;
    logic [$clog2(N_EMBD+1)-1:0] shared_valid_rows;
    logic [DATA_WIDTH-1:0] shared_reader_dout;
    logic signed [N_EMBD*N_EMBD*DATA_WIDTH-1:0] shared_weight_tile;

    logic shared_matmul_start;
    logic shared_matmul_busy;
    logic shared_matmul_valid;
    logic signed [N_EMBD*N_EMBD*DATA_WIDTH-1:0] shared_matrix_a;
    logic signed [N_EMBD*DATA_WIDTH-1:0] shared_matrix_b;
    logic signed [N_EMBD*DATA_WIDTH-1:0] shared_matrix_c;
    logic shared_tile_loaded;

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
    matmul_op_t reader_op;
    logic [5:0] shared_row_base;
    logic [5:0] shared_col_base;
    logic signed [ACC_WIDTH-1:0] fc2_acc [0:N_EMBD-1];

    function automatic logic signed [ACC_WIDTH-1:0] extend_data(
        input logic signed [DATA_WIDTH-1:0] value
    );
        begin
            extend_data = {{(ACC_WIDTH-DATA_WIDTH){value[DATA_WIDTH-1]}}, value};
        end
    endfunction

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

    localparam int SELECT_INDEX_WIDTH = (VOCAB_SIZE <= 1) ? 1 : $clog2(VOCAB_SIZE);
    logic [SELECT_INDEX_WIDTH-1:0] select_index;
    logic [TOKEN_WIDTH-1:0] selected_token_reg;
    logic signed [DATA_WIDTH-1:0] selected_value_reg;

    assign q_bram_en   = shared_reader_en && (reader_op == OP_Q);
    assign k_bram_en   = shared_reader_en && (reader_op == OP_K);
    assign v_bram_en   = shared_reader_en && (reader_op == OP_V);
    assign wo_bram_en  = shared_reader_en && (reader_op == OP_WO);
    assign fc1_bram_en = shared_reader_en && (reader_op == OP_FC1);
    assign fc2_bram_en = shared_reader_en && (reader_op == OP_FC2);
    assign lm_bram_en  = shared_reader_en && (reader_op == OP_LM);

    assign q_bram_addr   = QKV_ADDR_WIDTH'(shared_reader_addr);
    assign k_bram_addr   = QKV_ADDR_WIDTH'(shared_reader_addr);
    assign v_bram_addr   = QKV_ADDR_WIDTH'(shared_reader_addr);
    assign wo_bram_addr  = QKV_ADDR_WIDTH'(shared_reader_addr);
    assign fc1_bram_addr = FC1_ADDR_WIDTH'(shared_reader_addr);
    assign fc2_bram_addr = FC2_ADDR_WIDTH'(shared_reader_addr);
    assign lm_bram_addr  = LM_ADDR_WIDTH'(shared_reader_addr);

    always_comb begin
        case (reader_op)
            OP_Q:       shared_reader_dout = q_bram_dout;
            OP_K:       shared_reader_dout = k_bram_dout;
            OP_V:       shared_reader_dout = v_bram_dout;
            OP_WO:      shared_reader_dout = wo_bram_dout;
            OP_FC1:     shared_reader_dout = fc1_bram_dout;
            OP_FC2:     shared_reader_dout = fc2_bram_dout;
            OP_LM:      shared_reader_dout = lm_bram_dout;
            default:    shared_reader_dout = '0;
        endcase
    end




    assign busy = (state != ST_IDLE);
    assign valid_out = (state == ST_DONE);
    assign k_cache_p0 = keys_cache[0*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign k_cache_p1 = keys_cache[1*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign k_cache_p2 = keys_cache[2*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign k_cache_p3 = keys_cache[3*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign k_cache_p4 = keys_cache[4*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign k_cache_p5 = keys_cache[5*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign k_cache_p6 = keys_cache[6*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign k_cache_p7 = keys_cache[7*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p0 = values_cache[0*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p1 = values_cache[1*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p2 = values_cache[2*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p3 = values_cache[3*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p4 = values_cache[4*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p5 = values_cache[5*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p6 = values_cache[6*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];
    assign v_cache_p7 = values_cache[7*CACHE_PART_WIDTH +: CACHE_PART_WIDTH];

    embedding_lookup #(
        .VOCAB_SIZE(VOCAB_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .N_EMBD(N_EMBD),
        .DATA_WIDTH(DATA_WIDTH),
        .SUM_WIDTH(EMB_WIDTH),
        .TOKEN_ADDR_WIDTH(TOKEN_ADDR_WIDTH),
        .POS_ADDR_WIDTH(POS_ADDR_WIDTH)
    ) embedding_lookup_i (
        .clk(clk),
        .rst_n(rst_l),
        .valid_in(embed_valid_in),
        .token_id(token_id),
        .pos_id(pos_id),
        .token_bram_en(token_bram_en),
        .token_bram_addr(token_bram_addr),
        .token_bram_dout(token_bram_dout),
        .pos_bram_en(pos_bram_en),
        .pos_bram_addr(pos_bram_addr),
        .pos_bram_dout(pos_bram_dout),
        .valid_out(embed_valid_out),
        .embedding(embedding_vec)
    );

    blk_mem_gen_0 token_embedding_bram (
        .clka(clk), .ena(token_bram_en), .addra(token_bram_addr),
        .douta(token_bram_dout), .dina('0), .wea(1'b0)
    );

    blk_mem_gen_1 position_embedding_bram (
        .clka(clk), .ena(pos_bram_en), .addra(pos_bram_addr),
        .douta(pos_bram_dout), .dina('0), .wea(1'b0)
    );

    blk_mem_gen_q q_weight_bram (
        .clka(clk), .ena(q_bram_en), .addra(q_bram_addr),
        .douta(q_bram_dout), .dina('0), .wea(1'b0)
    );
    blk_mem_gen_k k_weight_bram (
        .clka(clk), .ena(k_bram_en), .addra(k_bram_addr),
        .douta(k_bram_dout), .dina('0), .wea(1'b0)
    );
    blk_mem_gen_v v_weight_bram (
        .clka(clk), .ena(v_bram_en), .addra(v_bram_addr),
        .douta(v_bram_dout), .dina('0), .wea(1'b0)
    );
    blk_mem_gen_wo wo_weight_bram (
        .clka(clk), .ena(wo_bram_en), .addra(wo_bram_addr),
        .douta(wo_bram_dout), .dina('0), .wea(1'b0)
    );
    blk_mem_gen_fc1 fc1_weight_bram (
        .clka(clk), .ena(fc1_bram_en), .addra(fc1_bram_addr),
        .douta(fc1_bram_dout), .dina('0), .wea(1'b0)
    );
    blk_mem_gen_fc2 fc2_weight_bram (
        .clka(clk), .ena(fc2_bram_en), .addra(fc2_bram_addr),
        .douta(fc2_bram_dout), .dina('0), .wea(1'b0)
    );
    blk_mem_gen_lm lm_weight_bram (
        .clka(clk), .ena(lm_bram_en), .addra(lm_bram_addr),
        .douta(lm_bram_dout), .dina('0), .wea(1'b0)
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

    bram_tile_reader #(
        .DATA_WIDTH(DATA_WIDTH),
        .TILE_ROWS(N_EMBD),
        .TILE_COLS(N_EMBD),
        .ADDR_WIDTH(MAX_WEIGHT_ADDR_WIDTH)
    ) shared_weight_reader_i (
        .clk(clk),
        .rst_l(rst_l),
        .start(shared_reader_start),
        .base_addr(shared_base_addr),
        .row_stride(shared_row_stride),
        .col_offset(shared_col_offset),
        .valid_rows(shared_valid_rows),
        .bram_en(shared_reader_en),
        .bram_addr(shared_reader_addr),
        .bram_dout(shared_reader_dout),
        .busy(shared_reader_busy),
        .valid_out(shared_reader_valid),
        .tile_matrix(shared_weight_tile)
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

    always_comb begin
        reader_op = OP_NONE;
        case (state)
            ST_ATTN_Q:   reader_op = OP_Q;
            ST_ATTN_K:   reader_op = OP_K;
            ST_ATTN_V:   reader_op = OP_V;
            ST_ATTN_WO:  reader_op = OP_WO;
            ST_MLP_FC1:  reader_op = OP_FC1;
            ST_MLP_FC2:  reader_op = OP_FC2;
            ST_LM_HEAD:  reader_op = OP_LM;
            default:     reader_op = OP_NONE;
        endcase
    end

    // All supported projections are read as 16x16 tiles.  FC2 advances
    // across the 64 input columns; FC1 and LM advance across output rows.
    always_comb begin
        shared_base_addr = '0;
        shared_row_stride = N_EMBD;
        shared_col_offset = '0;
        shared_valid_rows = N_EMBD;

        case (reader_op)
            OP_Q, OP_K, OP_V, OP_WO:
                shared_base_addr = shared_row_base * N_EMBD;
            OP_FC1:
                shared_base_addr = shared_row_base * N_EMBD;
            OP_FC2: begin
                shared_base_addr = shared_row_base * MLP_HIDDEN;
                shared_row_stride = MLP_HIDDEN;
                shared_col_offset = shared_col_base;
            end
            OP_LM:
                shared_base_addr = shared_row_base * N_EMBD;
            default: begin
                shared_base_addr = '0;
            end
        endcase

        if ((reader_op == OP_LM) && (shared_row_base == 6'd16))
            shared_valid_rows = VOCAB_SIZE - 16;
    end

    always_comb begin
        shared_matrix_a = shared_weight_tile;
        shared_matrix_b = '0;

        case (shared_op)
            OP_Q, OP_K, OP_V:
                shared_matrix_b = rms0_vec;
            OP_WO:
                shared_matrix_b = attn_context_vec;
            OP_FC1:
                shared_matrix_b = rms1_vec;
            OP_FC2:
                for (int i = 0; i < N_EMBD; i++) begin
                    shared_matrix_b[i*DATA_WIDTH +: DATA_WIDTH] =
                        mlp_relu_vec[(int'(shared_col_base) + i)*DATA_WIDTH +: DATA_WIDTH];
                end
            OP_LM:
                shared_matrix_b = mlp_residual_vec;
            default:
                shared_matrix_b = '0;
        endcase
    end

    assign shared_reader_start =
        (reader_op != OP_NONE) &&
        !shared_reader_busy &&
        !shared_reader_valid &&
        !shared_tile_loaded &&
        !shared_matmul_busy &&
        !shared_matmul_valid;

    assign shared_matmul_start =
        shared_tile_loaded &&
        !shared_matmul_busy &&
        !shared_matmul_valid;

    assign q_busy       = shared_matmul_busy && (shared_op == OP_Q);
    assign k_busy       = shared_matmul_busy && (shared_op == OP_K);
    assign v_busy       = shared_matmul_busy && (shared_op == OP_V);
    assign attn_wo_busy = shared_matmul_busy && (shared_op == OP_WO);
    assign mlp_fc1_busy = shared_matmul_busy && (shared_op == OP_FC1);
    assign mlp_fc2_busy = shared_matmul_busy && (shared_op == OP_FC2);
    assign lm_head_busy = shared_matmul_busy && (shared_op == OP_LM);

    assign q_valid       = shared_matmul_valid && (shared_op == OP_Q);
    assign k_valid       = shared_matmul_valid && (shared_op == OP_K);
    assign v_valid       = shared_matmul_valid && (shared_op == OP_V);
    assign attn_wo_valid = shared_matmul_valid && (shared_op == OP_WO);
    assign mlp_fc1_valid = shared_matmul_valid &&
                           (shared_op == OP_FC1) &&
                           (shared_row_base == 6'd48);
    assign mlp_fc2_valid = shared_matmul_valid &&
                           (shared_op == OP_FC2) &&
                           (shared_col_base == 6'd48);
    assign lm_head_valid = shared_matmul_valid &&
                           (shared_op == OP_LM) &&
                           (shared_row_base == 6'd16);

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            shared_op        <= OP_NONE;
            shared_row_base  <= '0;
            shared_col_base  <= '0;
            shared_tile_loaded <= 1'b0;
            q_vec            <= '0;
            k_vec            <= '0;
            v_vec            <= '0;
            attn_wo_vec      <= '0;
            mlp_fc1_vec      <= '0;
            mlp_fc2_vec      <= '0;
            lm_logits_vec    <= '0;
            for (int i = 0; i < N_EMBD; i++)
                fc2_acc[i] <= '0;
        end else begin
            if (shared_reader_start) begin
                shared_op <= reader_op;
                shared_tile_loaded <= 1'b0;
            end

            if (shared_reader_valid)
                shared_tile_loaded <= 1'b1;

            if (shared_matmul_start)
                shared_tile_loaded <= 1'b0;

            if (shared_matmul_valid) begin
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
                            if ((int'(shared_row_base) + i) < MLP_HIDDEN)
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
                                    sat16(fc2_acc[i] +
                                          extend_data($signed(shared_matrix_c[i*DATA_WIDTH +: DATA_WIDTH])));
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

            if (state == ST_RMS0 && rms0_valid_out) begin
                shared_row_base <= '0;
                shared_col_base <= '0;
            end
            if (state == ST_RMS1 && rms1_valid_out) begin
                shared_row_base <= '0;
                shared_col_base <= '0;
            end
            if (state == ST_MLP_RELU) begin
                shared_row_base <= '0;
                shared_col_base <= '0;
                for (int i = 0; i < N_EMBD; i++)
                    fc2_acc[i] <= '0;
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
    assign attn_value_head_busy = attn_softmax_head_busy;
    assign attn_value_head_valid = attn_softmax_head_valid;

    generate
        for (attn_head_gen = 0; attn_head_gen < N_HEAD; attn_head_gen++) begin : gen_attention_softmax_value
            attention_fused #(
                .BLOCK_SIZE(BLOCK_SIZE),
                .HEAD_DIM(HEAD_DIM),
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(ACC_WIDTH),
                .FRAC_BITS(FRAC_BITS),
                .EXP_INIT_FILE(EXP_INIT_FILE)
            ) attn_fused_i (
                .clk(clk),
                .rst_l(rst_l),
                .start(attn_softmax_start),
                .pos_id(pos_id),
                .busy(attn_softmax_head_busy[attn_head_gen]),
                .valid_out(attn_softmax_head_valid[attn_head_gen]),
                .logits(attn_logits_head[attn_head_gen]),
                .values(value_head_matrix[attn_head_gen]),
                .context_out(context_head_vec[attn_head_gen])
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

    // TALOS-style final token weighting: output unnormalized exp weights.
    // Argmax and cumulative-weight sampling do not require division by sum.
    categorical_weights #(
        .VECTOR_SIZE(VOCAB_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .EXP_INIT_FILE(EXP_INIT_FILE)
    ) final_weights_i (
        .clk(clk),
        .rst_l(rst_l),
        .start(final_softmax_start),
        .busy(final_softmax_busy),
        .valid_out(final_softmax_valid),
        .logits(lm_logits_vec),
        .weights(final_probs_vec)
    );

    assign logits_out = lm_logits_vec;
    assign probs_out = final_probs_vec;
    assign next_token = selected_token_reg;
    assign end_token = (selected_token_reg == TOKEN_WIDTH'(VOCAB_SIZE - 1));
    assign debug_state = state;

    // Registered sequential argmax. This replaces the long combinational
    // priority-comparator chain with one comparison per clock.
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            select_index <= '0;
            selected_token_reg <= '0;
            selected_value_reg <= '0;
        end else begin
            if ((state == ST_SOFTMAX) && final_softmax_valid) begin
                selected_token_reg <= '0;
                selected_value_reg <= $signed(final_probs_vec[0 +: DATA_WIDTH]);
                select_index <= (VOCAB_SIZE <= 1) ? '0 : SELECT_INDEX_WIDTH'(1);
            end else if (state == ST_SELECT_TOKEN) begin
                if ($signed(final_probs_vec[select_index*DATA_WIDTH +: DATA_WIDTH]) >
                    selected_value_reg) begin
                    selected_value_reg <=
                        $signed(final_probs_vec[select_index*DATA_WIDTH +: DATA_WIDTH]);
                    selected_token_reg <= TOKEN_WIDTH'(select_index);
                end

                if (select_index != VOCAB_SIZE - 1)
                    select_index <= select_index + 1'b1;
            end
        end
    end


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
                if (attn_softmax_valid) nState = ST_ATTN_WO;
                else nState = ST_ATTN_SOFTMAX;
            end

            ST_ATTN_VALUE: begin
                nState = ST_ATTN_WO;
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
                if (select_index == VOCAB_SIZE - 1)
                    nState = ST_DONE;
                else
                    nState = ST_SELECT_TOKEN;
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
                // Attention value accumulation is fused into the softmax head.
            end

            ST_ATTN_VALUE: begin
                // Retained as a compatibility state; fused attention already completed.
            end

            ST_ATTN_WO: begin
                // The shared weight scheduler starts from the state itself.
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
