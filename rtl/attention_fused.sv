// Fused attention softmax and value accumulation.
// It avoids materializing prob[t] = exp[t] / sum_exp for every position.
// Instead, it computes weighted_value[d] / sum_exp once per head dimension.
module attention_fused #(
    parameter int BLOCK_SIZE = 16,
    parameter int HEAD_DIM = 4,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12,
    parameter int EXP_ADDR_WIDTH = 12,
    parameter int EXP_LUT_SIZE = 1 << EXP_ADDR_WIDTH,
    parameter string EXP_INIT_FILE = "exp_lut.mem"
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,
    input  logic [$clog2(BLOCK_SIZE)-1:0] pos_id,
    output logic busy,
    output logic valid_out,
    input  logic signed [BLOCK_SIZE*DATA_WIDTH-1:0] logits,
    input  logic signed [BLOCK_SIZE*HEAD_DIM*DATA_WIDTH-1:0] values,
    output logic signed [HEAD_DIM*DATA_WIDTH-1:0] context_out
);

    localparam int IDX_WIDTH = (BLOCK_SIZE <= 1) ? 1 : $clog2(BLOCK_SIZE);
    localparam int ACC_IDX_WIDTH = (HEAD_DIM <= 1) ? 1 : $clog2(HEAD_DIM);
    localparam logic signed [DATA_WIDTH-1:0] EXP_MIN_INPUT =
        -((1 <<< 3) <<< FRAC_BITS);

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_FIND_MAX,
        ST_EXP_SUM,
        ST_WEIGHT_ACC,
        ST_DIV_START,
        ST_DIV_WAIT,
        ST_DONE
    } state_t;

    state_t state;
    logic [IDX_WIDTH-1:0] index;
    logic [IDX_WIDTH-1:0] valid_position;
    logic signed [DATA_WIDTH-1:0] logit_arr [0:BLOCK_SIZE-1];
    logic signed [DATA_WIDTH-1:0] max_logit;
    logic [DATA_WIDTH-1:0] exp_arr [0:BLOCK_SIZE-1];
    logic [31:0] exp_sum;

    logic signed [ACC_WIDTH-1:0] value_acc [0:HEAD_DIM-1];
    logic signed [ACC_WIDTH-1:0] value_acc_next [0:HEAD_DIM-1];
    logic signed [2*DATA_WIDTH-1:0] weighted_product [0:HEAD_DIM-1];

    logic div_start;
    logic [HEAD_DIM-1:0] div_busy;
    logic [HEAD_DIM-1:0] div_done;
    logic signed [ACC_WIDTH-1:0] div_numerator [0:HEAD_DIM-1];
    logic signed [DATA_WIDTH-1:0] div_quotient [0:HEAD_DIM-1];

    logic [DATA_WIDTH-1:0] exp_lut [0:EXP_LUT_SIZE-1];

    assign busy = (state != ST_IDLE);
    assign valid_out = (state == ST_DONE);
    assign div_start = (state == ST_DIV_START);

    initial begin
        if (EXP_INIT_FILE != "")
            $readmemh(EXP_INIT_FILE, exp_lut);
    end

    always_comb begin
        for (int i = 0; i < BLOCK_SIZE; i++)
            logit_arr[i] = logits[i*DATA_WIDTH +: DATA_WIDTH];
    end

    function automatic [EXP_ADDR_WIDTH-1:0] exp_addr(
        input logic signed [DATA_WIDTH-1:0] delta
    );
        logic signed [DATA_WIDTH-1:0] clipped;
        logic [DATA_WIDTH-1:0] magnitude;
        logic [DATA_WIDTH+EXP_ADDR_WIDTH-1:0] scaled;
        begin
            if (delta >= 0)
                clipped = '0;
            else if (delta < EXP_MIN_INPUT)
                clipped = EXP_MIN_INPUT;
            else
                clipped = delta;

            magnitude = $unsigned(-clipped);
            scaled = {{EXP_ADDR_WIDTH{1'b0}}, magnitude} *
                     EXP_LUT_SIZE'(EXP_LUT_SIZE - 1);
            exp_addr = (scaled >>> (FRAC_BITS + 3));
        end
    endfunction

    always_comb begin
        for (int d = 0; d < HEAD_DIM; d++) begin
            weighted_product[d] = $signed(exp_arr[index]) *
                                  $signed(values[((index*HEAD_DIM + d)*DATA_WIDTH) +: DATA_WIDTH]);
            value_acc_next[d] = value_acc[d] +
                                (weighted_product[d] >>> FRAC_BITS);
        end
    end

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_IDLE;
            index <= '0;
            valid_position <= '0;
            max_logit <= '0;
            exp_sum <= '0;
            context_out <= '0;

            for (int i = 0; i < BLOCK_SIZE; i++)
                exp_arr[i] <= '0;
            for (int d = 0; d < HEAD_DIM; d++) begin
                value_acc[d] <= '0;
                div_numerator[d] <= '0;
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        index <= '0;
                        valid_position <= pos_id;
                        max_logit <= logit_arr[0];
                        state <= ST_FIND_MAX;
                    end
                end

                ST_FIND_MAX: begin
                    if (logit_arr[index] > max_logit)
                        max_logit <= logit_arr[index];

                    if (index == BLOCK_SIZE - 1) begin
                        index <= '0;
                        exp_sum <= '0;
                        state <= ST_EXP_SUM;
                    end else begin
                        index <= index + 1'b1;
                    end
                end

                ST_EXP_SUM: begin
                    if (index <= valid_position)
                        exp_arr[index] <= exp_lut[exp_addr(logit_arr[index] - max_logit)];
                    else
                        exp_arr[index] <= '0;

                    if (index <= valid_position)
                        exp_sum <= exp_sum + exp_lut[exp_addr(logit_arr[index] - max_logit)];

                    if (index == BLOCK_SIZE - 1) begin
                        index <= '0;
                        for (int d = 0; d < HEAD_DIM; d++)
                            value_acc[d] <= '0;
                        state <= ST_WEIGHT_ACC;
                    end else begin
                        index <= index + 1'b1;
                    end
                end

                ST_WEIGHT_ACC: begin
                    for (int d = 0; d < HEAD_DIM; d++)
                        value_acc[d] <= value_acc_next[d];

                    if (index == valid_position) begin
                        for (int d = 0; d < HEAD_DIM; d++)
                            div_numerator[d] <= value_acc_next[d];
                        state <= ST_DIV_START;
                    end else begin
                        index <= index + 1'b1;
                    end
                end

                ST_DIV_START: begin
                    state <= ST_DIV_WAIT;
                end

                ST_DIV_WAIT: begin
                    if (&div_done) begin
                        for (int d = 0; d < HEAD_DIM; d++)
                            context_out[d*DATA_WIDTH +: DATA_WIDTH] <= div_quotient[d];
                        state <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    genvar div_gen;
    generate
        for (div_gen = 0; div_gen < HEAD_DIM; div_gen++) begin : gen_attention_div
            sat_div16_engine attention_div_i (
                .clk(clk),
                .rst_l(rst_l),
                .start(div_start),
                .numerator(div_numerator[div_gen]),
                .denominator(exp_sum),
                .busy(div_busy[div_gen]),
                .done(div_done[div_gen]),
                .quotient(div_quotient[div_gen])
            );
        end
    endgenerate
endmodule

module sat_div16_engine (
    input  logic clk,
    input  logic rst_l,
    input  logic start,
    input  logic signed [63:0] numerator,
    input  logic [31:0] denominator,
    output logic busy,
    output logic done,
    output logic signed [15:0] quotient
);
    logic [63:0] num_reg;
    logic [31:0] denom_reg;
    logic [64:0] rem_reg;
    logic [63:0] quot_reg;
    logic [6:0] bit_reg;
    logic neg_reg;
    logic [64:0] rem_next;
    logic [63:0] quot_next;
    logic signed [64:0] signed_quot_next;

    function automatic signed [15:0] sat16(input logic signed [64:0] value);
        begin
            if (value > 65'sd32767)
                sat16 = 16'sd32767;
            else if (value < -65'sd32768)
                sat16 = 16'sh8000;
            else
                sat16 = value[15:0];
        end
    endfunction

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            busy <= 1'b0;
            done <= 1'b0;
            quotient <= '0;
            num_reg <= '0;
            denom_reg <= '0;
            rem_reg <= '0;
            quot_reg <= '0;
            bit_reg <= '0;
            neg_reg <= 1'b0;
        end else begin
            done <= 1'b0;
            if (!busy) begin
                if (start) begin
                    busy <= 1'b1;
                    neg_reg <= numerator[63];
                    num_reg <= numerator[63] ? (~numerator + 64'd1) : numerator[63:0];
                    denom_reg <= (denominator == 0) ? 32'd1 : denominator;
                    rem_reg <= '0;
                    quot_reg <= '0;
                    bit_reg <= 7'd31;
                end
            end else begin
                rem_next = {rem_reg[63:0], num_reg[bit_reg]};
                quot_next = quot_reg;
                if (rem_next >= {33'd0, denom_reg}) begin
                    rem_next = rem_next - {33'd0, denom_reg};
                    quot_next[bit_reg] = 1'b1;
                end
                rem_reg <= rem_next;
                quot_reg <= quot_next;

                if (bit_reg == 0) begin
                    signed_quot_next = $signed({1'b0, quot_next});
                    if (neg_reg)
                        signed_quot_next = -signed_quot_next;
                    quotient <= sat16(signed_quot_next);
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    bit_reg <= bit_reg - 1'b1;
                end
            end
        end
    end
endmodule
