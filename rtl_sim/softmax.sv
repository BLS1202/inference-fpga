module softmax_unit #(
    parameter int VECTOR_SIZE = 27,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 32,
    parameter int FRAC_BITS = 12,
    parameter int EXP_ADDR_WIDTH = 12,
    parameter int EXP_LUT_SIZE = 1 << EXP_ADDR_WIDTH,
    parameter string EXP_INIT_FILE = "microgpt/generated/exp_q12.hex"
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,

    output logic busy,
    output logic valid_out,

    input  logic signed [VECTOR_SIZE*DATA_WIDTH-1:0] logits,
    output logic [VECTOR_SIZE*DATA_WIDTH-1:0] probs
);

    typedef enum logic [2:0] {
        IDLE,
        FIND_MAX,
        EXP_LOOKUP,
        SUM_EXP,
        DIVIDE,
        DONE
    } state_t;

    localparam int IDX_WIDTH = $clog2(VECTOR_SIZE + 1);
    localparam int ARRAY_IDX_WIDTH = (VECTOR_SIZE <= 1) ? 1 : $clog2(VECTOR_SIZE);
    localparam int SCALED_WIDTH = DATA_WIDTH + EXP_ADDR_WIDTH;
    localparam logic [IDX_WIDTH-1:0] VECTOR_SIZE_VALUE = IDX_WIDTH'(VECTOR_SIZE);
    localparam logic [IDX_WIDTH-1:0] VECTOR_LAST_VALUE = IDX_WIDTH'(VECTOR_SIZE - 1);
    localparam logic signed [DATA_WIDTH-1:0] EXP_MIN_INPUT = -((1 <<< 3) <<< FRAC_BITS);

    state_t state;
    logic [IDX_WIDTH-1:0] idx;
    logic [ARRAY_IDX_WIDTH-1:0] array_idx;

    logic signed [DATA_WIDTH-1:0] logit_arr [0:VECTOR_SIZE-1];
    logic signed [DATA_WIDTH-1:0] max_val;
    logic [DATA_WIDTH-1:0] exp_arr [0:VECTOR_SIZE-1];
    logic [ACC_WIDTH-1:0] exp_sum;
    logic [DATA_WIDTH-1:0] exp_lut [0:EXP_LUT_SIZE-1];

    assign array_idx = idx[ARRAY_IDX_WIDTH-1:0];

    assign busy = (state != IDLE);

    initial begin
        if (EXP_INIT_FILE != "") begin
            $readmemh(EXP_INIT_FILE, exp_lut);
        end
    end

    always_comb begin
        for (int i = 0; i < VECTOR_SIZE; i++) begin
            logit_arr[i] = logits[i*DATA_WIDTH +: DATA_WIDTH];
        end
    end

    function automatic [EXP_ADDR_WIDTH-1:0] shifted_to_exp_addr;
        input signed [DATA_WIDTH-1:0] shifted_value;
        logic signed [DATA_WIDTH-1:0] clipped;
        logic [DATA_WIDTH-1:0] magnitude;
        logic [SCALED_WIDTH-1:0] scaled;
        logic [SCALED_WIDTH-1:0] shifted_addr;
        localparam logic [SCALED_WIDTH-1:0] LUT_LAST_VALUE =
            SCALED_WIDTH'(EXP_LUT_SIZE - 1);
        begin
            if (shifted_value > 0) begin
                clipped = '0;
            end else if (shifted_value < EXP_MIN_INPUT) begin
                clipped = EXP_MIN_INPUT;
            end else begin
                clipped = shifted_value;
            end

            magnitude = $unsigned(-clipped);
            scaled = {{EXP_ADDR_WIDTH{1'b0}}, magnitude} * LUT_LAST_VALUE;
            shifted_addr = scaled >>> (FRAC_BITS + 3);
            shifted_to_exp_addr = shifted_addr[EXP_ADDR_WIDTH-1:0];
        end
    endfunction

    function automatic [DATA_WIDTH-1:0] div_q12;
        input [DATA_WIDTH-1:0] numerator;
        input [ACC_WIDTH-1:0] denominator;
        logic [ACC_WIDTH+FRAC_BITS-1:0] scaled_num;
        logic [ACC_WIDTH+FRAC_BITS-1:0] quotient;
        begin
            if (denominator == '0) begin
                div_q12 = '0;
            end else begin
                scaled_num =
                    {{(ACC_WIDTH+FRAC_BITS-DATA_WIDTH){1'b0}}, numerator} << FRAC_BITS;
                quotient = scaled_num /
                    {{FRAC_BITS{1'b0}}, denominator};
                div_q12 = quotient[DATA_WIDTH-1:0];
            end
        end
    endfunction

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
            idx <= '0;
            max_val <= '0;
            exp_sum <= '0;
            valid_out <= 1'b0;
            probs <= '0;

            for (int i = 0; i < VECTOR_SIZE; i++) begin
                exp_arr[i] <= '0;
            end
        end else begin
            valid_out <= 1'b0;

            case (state)
                IDLE: begin
                    idx <= '0;
                    exp_sum <= '0;

                    if (start) begin
                        max_val <= logit_arr[0];
                        idx <= IDX_WIDTH'(1);
                        state <= FIND_MAX;
                    end
                end

                FIND_MAX: begin
                    if (idx == VECTOR_SIZE_VALUE) begin
                        idx <= '0;
                        state <= EXP_LOOKUP;
                    end else begin
                        if (logit_arr[array_idx] > max_val) begin
                            max_val <= logit_arr[array_idx];
                        end
                        idx <= idx + 1'b1;
                    end
                end

                EXP_LOOKUP: begin
                    exp_arr[array_idx] <= exp_lut[
                        shifted_to_exp_addr(logit_arr[array_idx] - max_val)
                    ];

                    if (idx == VECTOR_LAST_VALUE) begin
                        idx <= '0;
                        exp_sum <= '0;
                        state <= SUM_EXP;
                    end else begin
                        idx <= idx + 1'b1;
                    end
                end

                SUM_EXP: begin
                    exp_sum <= exp_sum +
                        {{(ACC_WIDTH-DATA_WIDTH){1'b0}}, exp_arr[array_idx]};

                    if (idx == VECTOR_LAST_VALUE) begin
                        idx <= '0;
                        state <= DIVIDE;
                    end else begin
                        idx <= idx + 1'b1;
                    end
                end

                DIVIDE: begin
                    probs[array_idx*DATA_WIDTH +: DATA_WIDTH] <=
                        div_q12(exp_arr[array_idx], exp_sum);

                    if (idx == VECTOR_LAST_VALUE) begin
                        state <= DONE;
                    end else begin
                        idx <= idx + 1'b1;
                    end
                end

                DONE: begin
                    valid_out <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule : softmax_unit
