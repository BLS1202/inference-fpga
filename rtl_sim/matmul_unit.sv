module matmul_unit #(
    parameter int M = 16,
    parameter int K = 16,
    parameter int N = 16,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 64,
    parameter int FRAC_BITS  = 12,
    parameter int LANES      = 16
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

    localparam int OUTPUTS = M * N;
    localparam int K_WIDTH = (K <= 1) ? 1 : $clog2(K);
    localparam int OUT_WIDTH = (OUTPUTS <= 1) ? 1 : $clog2(OUTPUTS);
    localparam logic signed [ACC_WIDTH-1:0] DATA_MAX =
        {{(ACC_WIDTH-DATA_WIDTH){1'b0}}, 1'b0, {(DATA_WIDTH-1){1'b1}}};
    localparam logic signed [ACC_WIDTH-1:0] DATA_MIN =
        {{(ACC_WIDTH-DATA_WIDTH){1'b1}}, 1'b1, {(DATA_WIDTH-1){1'b0}}};

    typedef enum logic {
        ST_IDLE,
        ST_RUN
    } state_t;

    state_t state;
    logic [K_WIDTH-1:0] k_idx;
    logic [OUT_WIDTH-1:0] output_base;

    logic signed [ACC_WIDTH-1:0] lane_acc [0:LANES-1];
    logic signed [ACC_WIDTH-1:0] lane_product [0:LANES-1];

    function automatic logic signed [DATA_WIDTH-1:0] get_a;
        input int output_index;
        input int k_index;
        int row_index;
        begin
            row_index = output_index / N;
            get_a = matrix_a[((row_index*K + k_index) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic logic signed [DATA_WIDTH-1:0] get_b;
        input int output_index;
        input int k_index;
        int col_index;
        begin
            col_index = output_index % N;
            get_b = matrix_b[((k_index*N + col_index) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic logic signed [DATA_WIDTH-1:0] sat_data;
        input logic signed [ACC_WIDTH-1:0] value;
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
        for (int lane = 0; lane < LANES; lane++) begin
            lane_product[lane] = '0;

            if ((int'(output_base) + lane) < OUTPUTS) begin
                lane_product[lane] =
                    $signed(get_a(int'(output_base) + lane, int'(k_idx))) *
                    $signed(get_b(int'(output_base) + lane, int'(k_idx)));
            end
        end
    end

    assign busy = (state == ST_RUN);

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state       <= ST_IDLE;
            k_idx       <= '0;
            output_base <= '0;
            matrix_c    <= '0;
            valid_out   <= 1'b0;

            for (int lane = 0; lane < LANES; lane++) begin
                lane_acc[lane] <= '0;
            end
        end else begin
            valid_out <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        state       <= ST_RUN;
                        k_idx       <= '0;
                        output_base <= '0;

                        for (int lane = 0; lane < LANES; lane++) begin
                            lane_acc[lane] <= '0;
                        end
                    end
                end

                ST_RUN: begin
                    if (int'(k_idx) == (K - 1)) begin
                        for (int lane = 0; lane < LANES; lane++) begin
                            if ((int'(output_base) + lane) < OUTPUTS) begin
                                matrix_c[((int'(output_base) + lane) * DATA_WIDTH) +: DATA_WIDTH]
                                    <= sat_data((lane_acc[lane] + lane_product[lane]) >>> FRAC_BITS);
                            end
                            lane_acc[lane] <= '0;
                        end

                        if ((int'(output_base) + LANES) >= OUTPUTS) begin
                            state <= ST_IDLE;
                            valid_out <= 1'b1;
                        end else begin
                            output_base <= OUT_WIDTH'(int'(output_base) + LANES);
                            k_idx <= '0;
                        end
                    end else begin
                        for (int lane = 0; lane < LANES; lane++) begin
                            lane_acc[lane] <= lane_acc[lane] + lane_product[lane];
                        end
                        k_idx <= k_idx + 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
