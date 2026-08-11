// Generates unnormalized categorical weights for token selection.
// The common normalization denominator is omitted intentionally.
module categorical_weights #(
    parameter int VECTOR_SIZE = 27,
    parameter int DATA_WIDTH = 16,
    parameter int FRAC_BITS = 12,
    parameter int EXP_ADDR_WIDTH = 12,
    parameter int EXP_LUT_SIZE = 1 << EXP_ADDR_WIDTH,
    parameter string EXP_INIT_FILE = "exp_lut.mem"
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,
    output logic busy,
    output logic valid_out,
    input  logic signed [VECTOR_SIZE*DATA_WIDTH-1:0] logits,
    output logic [VECTOR_SIZE*DATA_WIDTH-1:0] weights
);
    localparam int IDX_WIDTH = (VECTOR_SIZE <= 1) ? 1 : $clog2(VECTOR_SIZE);
    localparam logic signed [DATA_WIDTH-1:0] EXP_MIN_INPUT =
        -((1 <<< 3) <<< FRAC_BITS);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_FIND_MAX,
        ST_EXP_ADDR,
        ST_EXP_READ,
        ST_EXP_WRITE,
        ST_DONE
    } state_t;
    state_t state;
    logic [IDX_WIDTH-1:0] index;
    logic signed [DATA_WIDTH-1:0] logit_arr [0:VECTOR_SIZE-1];
    logic signed [DATA_WIDTH-1:0] max_logit;
    logic [DATA_WIDTH-1:0] exp_lut [0:EXP_LUT_SIZE-1];
    logic [EXP_ADDR_WIDTH-1:0] exp_lut_addr_reg;
    logic [DATA_WIDTH-1:0] exp_value_reg;

    assign busy = (state != ST_IDLE);
    assign valid_out = (state == ST_DONE);

    initial begin
        if (EXP_INIT_FILE != "")
            $readmemh(EXP_INIT_FILE, exp_lut);
    end

    always_comb begin
        for (int i = 0; i < VECTOR_SIZE; i++)
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
            exp_addr = scaled >>> (FRAC_BITS + 3);
        end
    endfunction

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_IDLE;
            index <= '0;
            max_logit <= '0;
            exp_lut_addr_reg <= '0;
            exp_value_reg <= '0;
            weights <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        index <= '0;
                        max_logit <= logit_arr[0];
                        state <= ST_FIND_MAX;
                    end
                end
                ST_FIND_MAX: begin
                    if (logit_arr[index] > max_logit)
                        max_logit <= logit_arr[index];
                    if (index == VECTOR_SIZE - 1) begin
                        index <= '0;
                        state <= ST_EXP_ADDR;
                    end else begin
                        index <= index + 1'b1;
                    end
                end

                // Stage 1: calculate and register the exponential LUT address.
                ST_EXP_ADDR: begin
                    exp_lut_addr_reg <= exp_addr(logit_arr[index] - max_logit);
                    state <= ST_EXP_READ;
                end

                // Stage 2: register the LUT output.
                ST_EXP_READ: begin
                    exp_value_reg <= exp_lut[exp_lut_addr_reg];
                    state <= ST_EXP_WRITE;
                end

                // Stage 3: write the registered value to the selected token.
                ST_EXP_WRITE: begin
                    weights[index*DATA_WIDTH +: DATA_WIDTH] <= exp_value_reg;
                    if (index == VECTOR_SIZE - 1) begin
                        state <= ST_DONE;
                    end else begin
                        index <= index + 1'b1;
                        state <= ST_EXP_ADDR;
                    end
                end
                ST_DONE: begin
                    valid_out <= 1'b1;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
