module linear_layer #(
    parameter int IN_FEATURES  = 16,
    parameter int OUT_FEATURES = 16,
    parameter int DATA_WIDTH   = 16,
    parameter int ACC_WIDTH    = 64,
    parameter int FRAC_BITS    = 12,
    parameter int ADDR_WIDTH   = (IN_FEATURES <= 1) ? 1 : $clog2(IN_FEATURES),
    parameter string WEIGHT_INIT_FILE = ""
) (
    input logic clk,
    input logic rst_l,
    input logic start,

    output logic busy,
    output logic valid_out,

    input logic signed [IN_FEATURES*DATA_WIDTH-1:0] x_in,
    output logic signed [OUT_FEATURES*DATA_WIDTH-1:0] y_out,

    // One external BRAM is used for each output column.
    output logic [OUT_FEATURES-1:0] weight_bram_en,
    output logic [OUT_FEATURES*ADDR_WIDTH-1:0] weight_bram_addr,
    input logic [OUT_FEATURES*DATA_WIDTH-1:0] weight_bram_dout
);

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_WAIT_FLUSH_1,
        ST_WAIT_FLUSH_2,
        ST_READ,
        ST_DRAIN,
        ST_WAIT_RESULT
    } state_t;

    state_t state;

    logic [ADDR_WIDTH-1:0] issue_index;
    logic [ADDR_WIDTH-1:0] issue_index_d1;
    logic [ADDR_WIDTH-1:0] issue_index_d2;

    logic request_valid_d1;
    logic request_valid_d2;

    logic matmul_start;
    logic matmul_feed_valid;
    logic matmul_feed_last;

    logic signed [DATA_WIDTH-1:0] a_feed;
    logic signed [OUT_FEATURES*DATA_WIDTH-1:0] b_feed;

    logic signed [OUT_FEATURES*DATA_WIDTH-1:0] matmul_matrix_c;
    logic matmul_busy;
    logic matmul_valid;

    assign busy = (state != ST_IDLE);

    // Keep BRAM enable asserted for the request cycle and two response
    // cycles. The final address remains held while in ST_DRAIN.
    always_comb begin
        for (int col = 0; col < OUT_FEATURES; col++) begin
            weight_bram_en[col] =
                (state == ST_READ) ||
                request_valid_d1 ||
                request_valid_d2;

            weight_bram_addr[col*ADDR_WIDTH +: ADDR_WIDTH] = issue_index;
        end
    end

    // Data returned from the two-cycle BRAM pipeline is presented to the
    // systolic array as one activation and one complete weight row.
    always_comb begin
        a_feed = '0;
        b_feed = '0;

        if (request_valid_d2) begin
            a_feed = x_in[issue_index_d2*DATA_WIDTH +: DATA_WIDTH];
            b_feed = weight_bram_dout;
        end
    end

    assign matmul_feed_valid = request_valid_d2;
    assign matmul_feed_last =
        request_valid_d2 && (issue_index_d2 == IN_FEATURES - 1);

    assign matmul_start = (state == ST_IDLE) && start;

    matmul_unit #(
        .M         (1),
        .K         (IN_FEATURES),
        .N         (OUT_FEATURES),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) matmul_i (
        .clk        (clk),
        .rst_l      (rst_l),
        .start      (matmul_start),
        .busy       (matmul_busy),
        .valid_out  (matmul_valid),
        .a_feed     (a_feed),
        .b_feed     (b_feed),
        .feed_valid (matmul_feed_valid),
        .feed_last  (matmul_feed_last),
        .matrix_c   (matmul_matrix_c)
    );

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_IDLE;

            issue_index    <= '0;
            issue_index_d1 <= '0;
            issue_index_d2 <= '0;

            request_valid_d1 <= 1'b0;
            request_valid_d2 <= 1'b0;

            valid_out <= 1'b0;
            y_out     <= '0;
        end else begin
            valid_out <= 1'b0;

            request_valid_d1 <= (state == ST_READ);
            request_valid_d2 <= request_valid_d1;

            issue_index_d1 <= issue_index;
            issue_index_d2 <= issue_index_d1;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        issue_index <= '0;
                        state <= ST_WAIT_FLUSH_1;
                    end
                end

                // Allow matmul_unit to complete its flush sequence before
                // the first weight request is issued.
                ST_WAIT_FLUSH_1: begin
                    state <= ST_WAIT_FLUSH_2;
                end

                ST_WAIT_FLUSH_2: begin
                    issue_index <= '0;
                    state <= ST_READ;
                end

                ST_READ: begin
                    if (issue_index == IN_FEATURES - 1) begin
                        state <= ST_DRAIN;
                    end else begin
                        issue_index <= issue_index + 1'b1;
                    end
                end

                ST_DRAIN: begin
                    if (request_valid_d2 &&
                        issue_index_d2 == IN_FEATURES - 1) begin
                        state <= ST_WAIT_RESULT;
                    end
                end

                ST_WAIT_RESULT: begin
                    if (matmul_valid) begin
                        y_out <= matmul_matrix_c;
                        valid_out <= 1'b1;
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
