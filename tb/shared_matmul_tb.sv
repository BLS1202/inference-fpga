`timescale 1ns/1ps

// Vivado simulation testbench for the single shared matmul unit.
//
// blk_mem_gen_0 must contain matrix A in row-major order:
//   A[row*K + col]
// blk_mem_gen_1 must contain matrix B in row-major order:
//   B[row*N + col]
// Both IPs are read-only, 16-bit, synchronous BRAMs.  Configure their
// read latency to two cycles and give matrix A a depth of at least M*K.
module shared_matmul_tb;

    localparam int M = 16;
    localparam int K = 16;
    localparam int N = 1;

    localparam int DATA_WIDTH = 16;
    localparam int ACC_WIDTH  = 64;
    localparam int FRAC_BITS  = 12;

    localparam int A_WORDS = M * K;
    localparam int B_WORDS = K * N;
    localparam int A_ADDR_WIDTH = (A_WORDS <= 1) ? 1 : $clog2(A_WORDS);
    localparam int B_ADDR_WIDTH = (B_WORDS <= 1) ? 1 : $clog2(B_WORDS);
    localparam int INDEX_WIDTH = (A_WORDS <= 1) ? 1 : $clog2(A_WORDS);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_A_READ,
        ST_A_DRAIN,
        ST_B_READ,
        ST_B_DRAIN,
        ST_START_MATMUL,
        ST_WAIT_MATMUL,
        ST_DONE
    } state_t;

    logic clk;
    logic rst_l;

    logic a_bram_en;
    logic [A_ADDR_WIDTH-1:0] a_bram_addr;
    logic [DATA_WIDTH-1:0] a_bram_dout;

    logic b_bram_en;
    logic [B_ADDR_WIDTH-1:0] b_bram_addr;
    logic [DATA_WIDTH-1:0] b_bram_dout;

    // These declarations match the usual blk_mem_gen single-port interface.
    // The actual memory contents come from each IP's COE initialization.
    blk_mem_gen_0 matrix_a_bram (
        .clka  (clk),
        .ena   (a_bram_en),
        .addra (a_bram_addr),
        .douta (a_bram_dout),
        .dina  ('0),
        .wea   (1'b0)
    );

    blk_mem_gen_1 matrix_b_bram (
        .clka  (clk),
        .ena   (b_bram_en),
        .addra (b_bram_addr),
        .douta (b_bram_dout),
        .dina  ('0),
        .wea   (1'b0)
    );

    logic signed [M*K*DATA_WIDTH-1:0] matrix_a;
    logic signed [K*N*DATA_WIDTH-1:0] matrix_b;
    logic signed [M*N*DATA_WIDTH-1:0] matrix_c;

    logic matmul_start;
    logic matmul_busy;
    logic matmul_valid;

    state_t state;
    logic [INDEX_WIDTH-1:0] issue_index;
    logic [INDEX_WIDTH-1:0] issue_index_d1;
    logic [INDEX_WIDTH-1:0] issue_index_d2;
    logic request_valid_d1;
    logic request_valid_d2;

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
        .start     (matmul_start),
        .busy      (matmul_busy),
        .valid_out (matmul_valid),
        .matrix_a  (matrix_a),
        .matrix_b  (matrix_b),
        .matrix_c  (matrix_c)
    );

    assign matmul_start = (state == ST_START_MATMUL);

    // Keep BRAM enable asserted while the final two-cycle read is returning.
    assign a_bram_en = (state == ST_A_READ) || request_valid_d1 ||
                       request_valid_d2;
    assign b_bram_en = (state == ST_B_READ) || request_valid_d1 ||
                       request_valid_d2;

    assign a_bram_addr = issue_index[A_ADDR_WIDTH-1:0];
    assign b_bram_addr = issue_index[B_ADDR_WIDTH-1:0];

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state            <= ST_IDLE;
            issue_index      <= '0;
            issue_index_d1   <= '0;
            issue_index_d2   <= '0;
            request_valid_d1 <= 1'b0;
            request_valid_d2 <= 1'b0;
            matrix_a         <= '0;
            matrix_b         <= '0;
        end else begin
            request_valid_d1 <= (state == ST_A_READ) || (state == ST_B_READ);
            request_valid_d2 <= request_valid_d1;
            issue_index_d1   <= issue_index;
            issue_index_d2   <= issue_index_d1;

            // The delayed index identifies the BRAM word visible on douta.
            if (request_valid_d2) begin
                if (state == ST_A_READ || state == ST_A_DRAIN) begin
                    matrix_a[issue_index_d2*DATA_WIDTH +: DATA_WIDTH] <= a_bram_dout;
                end else if (state == ST_B_READ || state == ST_B_DRAIN) begin
                    matrix_b[issue_index_d2*DATA_WIDTH +: DATA_WIDTH] <= b_bram_dout;
                end
            end

            case (state)
                ST_IDLE: begin
                    issue_index <= '0;
                    state <= ST_A_READ;
                end

                ST_A_READ: begin
                    if (issue_index == A_WORDS-1) begin
                        state <= ST_A_DRAIN;
                    end else begin
                        issue_index <= issue_index + 1'b1;
                    end
                end

                ST_A_DRAIN: begin
                    if (request_valid_d2 && issue_index_d2 == A_WORDS-1) begin
                        issue_index <= '0;
                        state <= ST_B_READ;
                    end
                end

                ST_B_READ: begin
                    if (issue_index == B_WORDS-1) begin
                        state <= ST_B_DRAIN;
                    end else begin
                        issue_index <= issue_index + 1'b1;
                    end
                end

                ST_B_DRAIN: begin
                    if (request_valid_d2 && issue_index_d2 == B_WORDS-1) begin
                        state <= ST_START_MATMUL;
                    end
                end

                ST_START_MATMUL: state <= ST_WAIT_MATMUL;

                ST_WAIT_MATMUL: begin
                    if (matmul_valid)
                        state <= ST_DONE;
                end

                ST_DONE: begin
                    $display("Shared matmul BRAM read test completed");
                    for (int row = 0; row < M; row++) begin
                        $display("C[%0d] = 0x%04h (%0d)", row,
                                 matrix_c[row*DATA_WIDTH +: DATA_WIDTH],
                                 $signed(matrix_c[row*DATA_WIDTH +: DATA_WIDTH]));
                    end
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    initial begin
        rst_l = 1'b0;
        repeat (4) @(posedge clk);
        rst_l = 1'b1;
        wait (state == ST_DONE);
        repeat (2) @(posedge clk);
        $finish;
    end

endmodule
