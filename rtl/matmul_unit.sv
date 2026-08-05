module matmul_unit #(
    parameter int M = 16,
    parameter int K = 16,
    parameter int N = 16,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 64,
    parameter int FRAC_BITS  = 12
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,

    output logic busy,
    output logic valid_out,

    input  logic signed [M*K*DATA_WIDTH-1:0] matrix_a,
    input  logic signed [K*N*DATA_WIDTH-1:0] matrix_b,

    output logic signed [M*N*DATA_WIDTH-1:0] matrix_c
);

    // The final valid input cycle is followed by a separate capture cycle.
    localparam int LAST_CYCLE  = M + N + K - 3;
    localparam int CYCLE_WIDTH = $clog2(LAST_CYCLE + 2);
    localparam logic signed [ACC_WIDTH-1:0] DATA_MAX =
        {{(ACC_WIDTH-DATA_WIDTH){1'b0}}, 1'b0, {(DATA_WIDTH-1){1'b1}}};
    localparam logic signed [ACC_WIDTH-1:0] DATA_MIN =
        {{(ACC_WIDTH-DATA_WIDTH){1'b1}}, 1'b1, {(DATA_WIDTH-1){1'b0}}};

    logic [CYCLE_WIDTH-1:0] cycle_count;
    logic pe_en;
    logic pe_flush;

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_FLUSH,
        ST_RUN,
        ST_CAPTURE
    } state_t;

    state_t state;

    logic signed [DATA_WIDTH-1:0] a_bus [0:M-1][0:N];
    logic signed [DATA_WIDTH-1:0] b_bus [0:M][0:N-1];
    logic signed [ACC_WIDTH-1:0] acc [0:M-1][0:N-1];

    assign pe_en    = (state == ST_RUN);
    assign pe_flush = (state == ST_FLUSH);
    assign busy     = (state != ST_IDLE);

    function automatic signed [DATA_WIDTH-1:0] get_a;
        input int row;
        input int col;
        begin
            get_a = matrix_a[((row*K + col) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic signed [DATA_WIDTH-1:0] get_b;
        input int row;
        input int col;
        begin
            get_b = matrix_b[((row*N + col) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic signed [DATA_WIDTH-1:0] sat_data;
        input signed [ACC_WIDTH-1:0] value;
        begin
            if (value > DATA_MAX) begin
                sat_data = {1'b0, {(DATA_WIDTH-1){1'b1}}};
            end else if (value < DATA_MIN) begin
                sat_data = {1'b1, {(DATA_WIDTH-1){1'b0}}};
            end else begin
                sat_data = value[DATA_WIDTH-1:0];
            end
        end
    endfunction

    always_comb begin
        for (int row = 0; row < M; row++) begin
            int a_k;

            a_k = int'(cycle_count) - row;
            if (a_k >= 0 && a_k < K) begin
                a_bus[row][0] = get_a(row, a_k);
            end else begin
                a_bus[row][0] = '0;
            end
        end

        for (int col = 0; col < N; col++) begin
            int b_k;

            b_k = int'(cycle_count) - col;
            if (b_k >= 0 && b_k < K) begin
                b_bus[0][col] = get_b(b_k, col);
            end else begin
                b_bus[0][col] = '0;
            end
        end
    end

    genvar row_gen;
    genvar col_gen;
    generate
        for (row_gen = 0; row_gen < M; row_gen++) begin : gen_row
            for (col_gen = 0; col_gen < N; col_gen++) begin : gen_col
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_i (
                    .clk(clk),
                    .rst_l(rst_l),
                    .en(pe_en),
                    .flush(pe_flush),
                    .a_in(a_bus[row_gen][col_gen]),
                    .b_in(b_bus[row_gen][col_gen]),
                    .a_out(a_bus[row_gen][col_gen+1]),
                    .b_out(b_bus[row_gen+1][col_gen]),
                    .acc_out(acc[row_gen][col_gen])
                );
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            cycle_count <= '0;
            state <= ST_IDLE;
            valid_out <= 1'b0;
            matrix_c <= '0;
        end else begin
            valid_out <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        state <= ST_FLUSH;
                    end
                end

                ST_FLUSH: begin
                    // PEs see flush=1 for this complete clock cycle.
                    cycle_count <= '0;
                    state <= ST_RUN;
                end

                ST_RUN: begin
                    if (cycle_count == LAST_CYCLE[CYCLE_WIDTH-1:0]) begin
                        // The final product is accumulated on this edge.
                        // Read acc only in ST_CAPTURE on the next edge.
                        state <= ST_CAPTURE;
                    end else begin
                        cycle_count <= cycle_count + 1'b1;
                    end
                end

                ST_CAPTURE: begin
                    for (int row = 0; row < M; row++) begin
                        for (int col = 0; col < N; col++) begin
                            matrix_c[((row*N + col) * DATA_WIDTH) +: DATA_WIDTH] <=
                                sat_data(acc[row][col] >>> FRAC_BITS);
                        end
                    end

                    valid_out <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule : matmul_unit


module pe #(
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 64
) (
    input  logic clk,
    input  logic rst_l,
    input  logic en,
    input  logic flush,

    input  logic signed [DATA_WIDTH-1:0] a_in,
    input  logic signed [DATA_WIDTH-1:0] b_in,

    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic signed [DATA_WIDTH-1:0] b_out,
    output logic signed [ACC_WIDTH-1:0] acc_out
);

    logic signed [(2*DATA_WIDTH)-1:0] mul_result;

    assign mul_result = $signed(a_in) * $signed(b_in);

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            a_out <= '0;
            b_out <= '0;
            acc_out <= '0;
        end else if (flush) begin
            a_out <= '0;
            b_out <= '0;
            acc_out <= '0;
        end else if (en) begin
            a_out <= a_in;
            b_out <= b_in;
            acc_out <= acc_out +
                {{(ACC_WIDTH-(2*DATA_WIDTH)){mul_result[(2*DATA_WIDTH)-1]}}, mul_result};
        end
    end
endmodule : pe
