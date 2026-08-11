// Reusable matrix-multiply unit with LANES parallel MACs.
// Matrix storage is row-major for matrix_a and matrix_b:
// C[row,col] = sum_k A[row,k] * B[k,col].
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

    typedef enum logic [2:0] {ST_IDLE, ST_LOAD, ST_RUN, ST_WRITE, ST_DONE} state_t;
    state_t state;
    logic [K_WIDTH-1:0] k_idx;
    logic [OUT_WIDTH-1:0] output_base;

    logic signed [ACC_WIDTH-1:0] lane_acc [0:LANES-1];
    logic signed [ACC_WIDTH-1:0] lane_product [0:LANES-1];

    // Capture both operands before starting the MAC loop. This removes the
    // direct path from an upstream result register into the multiplier array.
    logic signed [M*K*DATA_WIDTH-1:0] matrix_a_reg;
    logic signed [K*N*DATA_WIDTH-1:0] matrix_b_reg;

    // Eight partitioned views of matrix A for waveform inspection.
    localparam int A_PART_ROWS = (M + 7) / 8;
    localparam int A_PART_WIDTH = A_PART_ROWS * K * DATA_WIDTH;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part0;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part1;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part2;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part3;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part4;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part5;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part6;
    (* keep = "true" *) logic signed [A_PART_WIDTH-1:0] matrix_a_part7;

    always_comb begin
        matrix_a_part0 = '0;
        matrix_a_part1 = '0;
        matrix_a_part2 = '0;
        matrix_a_part3 = '0;
        matrix_a_part4 = '0;
        matrix_a_part5 = '0;
        matrix_a_part6 = '0;
        matrix_a_part7 = '0;
        for (int row = 0; row < M; row++) begin
            case (row / A_PART_ROWS)
                0: matrix_a_part0[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                1: matrix_a_part1[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                2: matrix_a_part2[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                3: matrix_a_part3[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                4: matrix_a_part4[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                5: matrix_a_part5[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                6: matrix_a_part6[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                7: matrix_a_part7[(row % A_PART_ROWS)*K*DATA_WIDTH +: K*DATA_WIDTH] = matrix_a_reg[row*K*DATA_WIDTH +: K*DATA_WIDTH];
                default: begin end
            endcase
        end
    end

    function automatic logic signed [DATA_WIDTH-1:0] get_a(
        input int output_index,
        input int k_index
    );
        int row_index;
        begin
            row_index = output_index / N;
            case (row_index / A_PART_ROWS)
                0: get_a = matrix_a_part0[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                1: get_a = matrix_a_part1[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                2: get_a = matrix_a_part2[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                3: get_a = matrix_a_part3[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                4: get_a = matrix_a_part4[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                5: get_a = matrix_a_part5[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                6: get_a = matrix_a_part6[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                7: get_a = matrix_a_part7[((row_index % A_PART_ROWS)*K + k_index)*DATA_WIDTH +: DATA_WIDTH];
                default: get_a = '0;
            endcase
        end
    endfunction

    function automatic logic signed [DATA_WIDTH-1:0] get_b(
        input int output_index,
        input int k_index
    );
        int col_index;
        begin
            col_index = output_index % N;
            get_b = matrix_b_reg[((k_index*N + col_index) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic logic signed [DATA_WIDTH-1:0] sat_data(
        input logic signed [ACC_WIDTH-1:0] value
    );
        begin
            if (value > DATA_MAX)
                sat_data = {1'b0, {(DATA_WIDTH-1){1'b1}}};
            else if (value < DATA_MIN)
                sat_data = {1'b1, {(DATA_WIDTH-1){1'b0}}};
            else
                sat_data = value[DATA_WIDTH-1:0];
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

    // The unit is occupied while loading operands as well as while running
    // the MAC loop.
    assign busy = (state != ST_IDLE);

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state       <= ST_IDLE;
            k_idx       <= '0;
            output_base <= '0;
            matrix_c    <= '0;
            matrix_a_reg <= '0;
            matrix_b_reg <= '0;
            valid_out   <= 1'b0;
            for (int lane = 0; lane < LANES; lane++)
                lane_acc[lane] <= '0;
        end else begin
            valid_out <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        matrix_a_reg <= matrix_a;
                        matrix_b_reg <= matrix_b;
                        state       <= ST_LOAD;
                    end
                end

                ST_LOAD: begin
                    // The operand registers were loaded on the start edge.
                    // This state gives the registered values a full cycle
                    // before the first multiplier evaluation is captured.
                    state       <= ST_RUN;
                    k_idx       <= '0;
                    output_base <= '0;
                    for (int lane = 0; lane < LANES; lane++)
                        lane_acc[lane] <= '0;
                end

                ST_RUN: begin
                    if (int'(k_idx) == K - 1) begin
                        // Complete the final accumulation before writing the
                        // output register on the next clock.
                        for (int lane = 0; lane < LANES; lane++) begin
                            lane_acc[lane] <= lane_acc[lane] + lane_product[lane];
                        end
                        state <= ST_WRITE;
                    end else begin
                        for (int lane = 0; lane < LANES; lane++)
                            lane_acc[lane] <= lane_acc[lane] + lane_product[lane];
                        k_idx <= k_idx + 1'b1;
                    end
                end

                ST_WRITE: begin
                    for (int lane = 0; lane < LANES; lane++) begin
                        if ((int'(output_base) + lane) < OUTPUTS) begin
                            matrix_c[((int'(output_base) + lane) * DATA_WIDTH) +: DATA_WIDTH]
                                <= sat_data(lane_acc[lane] >>> FRAC_BITS);
                        end
                        lane_acc[lane] <= '0;
                    end

                    if ((int'(output_base) + LANES) >= OUTPUTS) begin
                        state <= ST_DONE;
                    end else begin
                        output_base <= OUT_WIDTH'(int'(output_base) + LANES);
                        k_idx <= '0;
                        state <= ST_RUN;
                    end
                end

                ST_DONE: begin
                    valid_out <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
