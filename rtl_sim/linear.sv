module linear_layer #(
    parameter int IN_FEATURES  = 16,
    parameter int OUT_FEATURES = 16,
    parameter int DATA_WIDTH   = 16,
    parameter int ACC_WIDTH    = 64,
    parameter int FRAC_BITS    = 12,
    parameter int ADDR_WIDTH   = (IN_FEATURES*OUT_FEATURES <= 1) ? 1 : $clog2(IN_FEATURES*OUT_FEATURES)
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,
    output logic busy,
    output logic valid_out,
    input  logic signed [IN_FEATURES*DATA_WIDTH-1:0] x_in,
    output logic signed [OUT_FEATURES*DATA_WIDTH-1:0] y_out,

    output logic weight_bram_en,
    output logic [ADDR_WIDTH-1:0] weight_bram_addr,
    input  logic [DATA_WIDTH-1:0] weight_bram_dout
);

    typedef enum logic [2:0] {
        ST_IDLE, ST_READ, ST_DRAIN, ST_START_MATMUL, ST_WAIT_RESULT
    } state_t;
    state_t state;

    localparam int TOTAL_WEIGHTS = IN_FEATURES * OUT_FEATURES;
    localparam int INDEX_WIDTH = (TOTAL_WEIGHTS <= 1) ? 1 : $clog2(TOTAL_WEIGHTS);

    logic [INDEX_WIDTH-1:0] issue_index;
    logic [INDEX_WIDTH-1:0] issue_index_d1;
    logic [INDEX_WIDTH-1:0] issue_index_d2;
    logic request_valid_d1;
    logic request_valid_d2;

    logic signed [IN_FEATURES*OUT_FEATURES*DATA_WIDTH-1:0] weight_matrix;
    logic signed [OUT_FEATURES*DATA_WIDTH-1:0] matmul_out;
    logic matmul_start;
    logic matmul_busy;
    logic matmul_valid;

    assign busy = (state != ST_IDLE);
    assign weight_bram_en = (state == ST_READ) || request_valid_d1 ||
                            request_valid_d2;
    assign weight_bram_addr = issue_index;
    assign matmul_start = (state == ST_START_MATMUL);

    matmul_unit #(
        .M(OUT_FEATURES), .K(IN_FEATURES), .N(1),
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH), .FRAC_BITS(FRAC_BITS)
    ) matmul_i (
        .clk(clk), .rst_l(rst_l), .start(matmul_start), .busy(matmul_busy),
        .valid_out(matmul_valid), .matrix_a(weight_matrix), .matrix_b(x_in),
        .matrix_c(matmul_out)
    );

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_IDLE;
            issue_index <= '0;
            issue_index_d1 <= '0;
            issue_index_d2 <= '0;
            request_valid_d1 <= 1'b0;
            request_valid_d2 <= 1'b0;
            weight_matrix <= '0;
            y_out <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            request_valid_d1 <= (state == ST_READ);
            request_valid_d2 <= request_valid_d1;
            issue_index_d1 <= issue_index;
            issue_index_d2 <= issue_index_d1;

            if (request_valid_d2)
                weight_matrix[issue_index_d2*DATA_WIDTH +: DATA_WIDTH] <= weight_bram_dout;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        issue_index <= '0;
                        state <= ST_READ;
                    end
                end
                ST_READ: begin
                    if (issue_index == TOTAL_WEIGHTS - 1)
                        state <= ST_DRAIN;
                    else
                        issue_index <= issue_index + 1'b1;
                end
                ST_DRAIN: begin
                    if (request_valid_d2 && issue_index_d2 == TOTAL_WEIGHTS - 1)
                        state <= ST_START_MATMUL;
                end
                ST_START_MATMUL: state <= ST_WAIT_RESULT;
                ST_WAIT_RESULT: begin
                    if (matmul_valid) begin
                        y_out <= matmul_out;
                        valid_out <= 1'b1;
                        state <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
