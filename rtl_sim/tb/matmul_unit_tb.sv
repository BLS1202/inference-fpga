module matmul_unit_tb #(
    parameter int M = 2,
    parameter int K = 3,
    parameter int N = 2,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12
);

    logic clk;
    logic rst_l;
    logic start;
    logic busy;
    logic valid_out;

    logic signed [M*K*DATA_WIDTH-1:0] matrix_a;
    logic signed [K*N*DATA_WIDTH-1:0] matrix_b;
    logic signed [M*N*DATA_WIDTH-1:0] matrix_c;

    logic signed [DATA_WIDTH-1:0] mat_a_mem [0:M*K-1];
    logic signed [DATA_WIDTH-1:0] mat_b_mem [0:K*N-1];
    logic signed [DATA_WIDTH-1:0] mat_c_expected_mem [0:M*N-1];

    string mat_a_file;
    string mat_b_file;
    string mat_c_file;

    matmul_unit #(
        .M(M),
        .K(K),
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk(clk),
        .rst_l(rst_l),
        .start(start),
        .busy(busy),
        .valid_out(valid_out),
        .matrix_a(matrix_a),
        .matrix_b(matrix_b),
        .matrix_c(matrix_c)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function automatic signed [DATA_WIDTH-1:0] get_c;
        input int row;
        input int col;
        begin
            get_c = matrix_c[((row*N + col) * DATA_WIDTH) +: DATA_WIDTH];
        end
    endfunction

    function automatic signed [DATA_WIDTH-1:0] sat16;
        input logic signed [ACC_WIDTH-1:0] value;
        begin
            if (value > 32767) begin
                sat16 = 16'sd32767;
            end else if (value < -32768) begin
                sat16 = -16'sd32768;
            end else begin
                sat16 = value[DATA_WIDTH-1:0];
            end
        end
    endfunction

    function automatic signed [DATA_WIDTH-1:0] calculate_c;
        input int row;
        input int col;
        logic signed [ACC_WIDTH-1:0] acc;
        begin
            acc = '0;

            for (int kk = 0; kk < K; kk++) begin
                acc += $signed(mat_a_mem[row*K + kk]) * $signed(mat_b_mem[kk*N + col]);
            end

            calculate_c = sat16(acc >>> FRAC_BITS);
        end
    endfunction

    task automatic pack_inputs;
        begin
            matrix_a = '0;
            matrix_b = '0;

            for (int i = 0; i < M*K; i++) begin
                matrix_a[i*DATA_WIDTH +: DATA_WIDTH] = mat_a_mem[i];
            end

            for (int i = 0; i < K*N; i++) begin
                matrix_b[i*DATA_WIDTH +: DATA_WIDTH] = mat_b_mem[i];
            end
        end
    endtask

    task automatic check_outputs;
        logic signed [DATA_WIDTH-1:0] actual;
        logic signed [DATA_WIDTH-1:0] expected_from_file;
        logic signed [DATA_WIDTH-1:0] expected_calculated;
        begin
            for (int row = 0; row < M; row++) begin
                for (int col = 0; col < N; col++) begin
                    actual = get_c(row, col);
                    expected_from_file = mat_c_expected_mem[row*N + col];
                    expected_calculated = calculate_c(row, col);

                    if (expected_from_file !== expected_calculated) begin
                        $fatal(
                            1,
                            "expected C[%0d][%0d] file mismatch: file 0x%04h (%0d), calculated 0x%04h (%0d)",
                            row,
                            col,
                            expected_from_file,
                            expected_from_file,
                            expected_calculated,
                            expected_calculated
                        );
                    end

                    if (actual !== expected_calculated) begin
                        $fatal(
                            1,
                            "C[%0d][%0d] mismatch: got 0x%04h (%0d), expected 0x%04h (%0d)",
                            row,
                            col,
                            actual,
                            actual,
                            expected_calculated,
                            expected_calculated
                        );
                    end
                end
            end
        end
    endtask

    task automatic print_matrix_c;
        logic signed [DATA_WIDTH-1:0] value;
        begin
            $display("Calculated matrix C from DUT:");
            for (int row = 0; row < M; row++) begin
                $write("  ");
                for (int col = 0; col < N; col++) begin
                    value = get_c(row, col);
                    $write("0x%04h(%0d) ", value, value);
                end
                $write("\n");
            end
        end
    endtask

    initial begin
        if ($test$plusargs("VCD")) begin
            $dumpfile("build/verilator/matmul_unit_tb/matmul_unit_tb.vcd");
            $dumpvars(0, matmul_unit_tb);
        end

        if (!$value$plusargs("MAT_A=%s", mat_a_file)) begin
            mat_a_file = "generated/matmul/mat_a.mem";
        end
        if (!$value$plusargs("MAT_B=%s", mat_b_file)) begin
            mat_b_file = "generated/matmul/mat_b.mem";
        end
        if (!$value$plusargs("MAT_C=%s", mat_c_file)) begin
            mat_c_file = "generated/matmul/mat_c_expected.mem";
        end

        $readmemh(mat_a_file, mat_a_mem);
        $readmemh(mat_b_file, mat_b_mem);
        $readmemh(mat_c_file, mat_c_expected_mem);

        rst_l = 1'b0;
        start = 1'b0;
        pack_inputs();

        repeat (2) @(posedge clk);
        rst_l = 1'b1;

        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        for (int cycles = 0; !valid_out && cycles < 1000; cycles++) begin
            @(posedge clk);
        end
        if (!valid_out) begin
            $fatal(1, "timed out waiting for valid_out");
        end
        
        print_matrix_c();
        check_outputs();

        $display("matmul_unit_tb passed M=%0d K=%0d N=%0d", M, K, N);
        $finish;
    end
endmodule : matmul_unit_tb
