`timescale 1ns/1ps

// Debug testbench for the shared 16-lane matmul used by the Q projection.
module shared_matmul_tb;

    localparam int M = 16;
    localparam int K = 16;
    localparam int N = 1;
    localparam int DATA_WIDTH = 16;
    localparam int ACC_WIDTH = 64;
    localparam int FRAC_BITS = 12;

    logic clk;
    logic rst_l;
    logic start;
    logic busy;
    logic valid_out;

    logic signed [M*K*DATA_WIDTH-1:0] matrix_a;
    logic signed [K*N*DATA_WIDTH-1:0] matrix_b;
    logic signed [M*N*DATA_WIDTH-1:0] matrix_c;

    logic [DATA_WIDTH-1:0] matrix_a_mem [0:M*K-1];
    logic [DATA_WIDTH-1:0] matrix_b_mem [0:K*N-1];

    logic [DATA_WIDTH-1:0] expected [0:M*N-1];

    string matrix_a_file;
    string matrix_b_file;

    matmul_unit #(
        .M(M),
        .K(K),
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .LANES(16)
    ) dut (
        .clk       (clk),
        .rst_l     (rst_l),
        .start     (start),
        .busy      (busy),
        .valid_out (valid_out),
        .matrix_a  (matrix_a),
        .matrix_b  (matrix_b),
        .matrix_c  (matrix_c)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        if (!$value$plusargs("MATRIX_A=%s", matrix_a_file))
            matrix_a_file = "microgpt/generated/layer0_attn_wq_q12.hex";
        if (!$value$plusargs("MATRIX_B=%s", matrix_b_file))
            matrix_b_file = "generated/reference/intermediates/rms0.mem";

        $readmemh(matrix_a_file, matrix_a_mem);
        $readmemh(matrix_b_file, matrix_b_mem);

        matrix_a = '0;
        matrix_b = '0;
        for (int i = 0; i < M*K; i++)
            matrix_a[i*DATA_WIDTH +: DATA_WIDTH] = matrix_a_mem[i];
        for (int i = 0; i < K*N; i++)
            matrix_b[i*DATA_WIDTH +: DATA_WIDTH] = matrix_b_mem[i];

        // Expected outputs from integer Q4.12 accumulation followed by >>> 12.
        expected[0]  = 16'hfb98;
        expected[1]  = 16'h10da;
        expected[2]  = 16'h0523;
        expected[3]  = 16'hf9a6;
        expected[4]  = 16'h021e;
        expected[5]  = 16'hff05;
        expected[6]  = 16'h086b;
        expected[7]  = 16'hf88d;
        expected[8]  = 16'hec3a;
        expected[9]  = 16'hf5ff;
        expected[10] = 16'h0e3d;
        expected[11] = 16'h08c3;
        expected[12] = 16'h026d;
        expected[13] = 16'h05e6;
        expected[14] = 16'he609;
        expected[15] = 16'hf0b1;

        rst_l = 1'b0;
        start = 1'b0;
        repeat (2) @(posedge clk);
        rst_l = 1'b1;

        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        @(posedge valid_out);
        #1;
        $display("Final shared matmul output:");
        for (int lane = 0; lane < M; lane++) begin
            $display("lane %0d: 0x%04h (%0d)", lane,
                     matrix_c[lane*DATA_WIDTH +: DATA_WIDTH],
                     $signed(matrix_c[lane*DATA_WIDTH +: DATA_WIDTH]));
            if (matrix_c[lane*DATA_WIDTH +: DATA_WIDTH] !== expected[lane])
                $fatal(1, "lane %0d mismatch", lane);
        end

        $display("shared_matmul_tb PASS");
        repeat (2) @(posedge clk);
        $finish;
    end

    // Values shown here are the products and accumulators consumed on the
    // current k_idx cycle, before the sequential update at that clock edge.
    always @(posedge clk) begin
        if (rst_l && (dut.state == 2'd2)) begin
            $write("k_idx=%0d product:", dut.k_idx);
            for (int lane = 0; lane < M; lane++)
                $write(" %0d", $signed(dut.lane_product[lane]));
            $display("");

            $write("k_idx=%0d acc_before:", dut.k_idx);
            for (int lane = 0; lane < M; lane++)
                $write(" %0d", $signed(dut.lane_acc[lane]));
            $display("");
        end
    end

endmodule
