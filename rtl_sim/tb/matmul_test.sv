`timescale 1ns/1ps

module matmul_test #(
    parameter int M = 4,
    parameter int K = 5,
    parameter int N = 3,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12
) (
    input  logic        CLK100MHZ,
    input  logic [1:0]  sw,
    output logic [15:0] LED,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [7:0]  an,
    output logic        UART_RXD_OUT
);

    logic sim_clk;
    logic rst_l;
    logic start_pulse;

    logic reader_busy;
    logic reader_feed_valid;
    logic reader_feed_last;
    logic signed [M*DATA_WIDTH-1:0] a_feed;
    logic signed [N*DATA_WIDTH-1:0] b_feed;

    logic matmul_busy;
    logic matmul_valid;
    logic signed [M*N*DATA_WIDTH-1:0] matrix_c;

    // Self-contained simulation clock: 100 MHz.
    initial begin
        sim_clk = 1'b0;
        forever #5 sim_clk = ~sim_clk;
    end

    // Self-contained reset and start sequence.
    initial begin
        rst_l = 1'b0;
        start_pulse = 1'b0;

        #20;
        rst_l = 1'b1;

        #20;
        start_pulse = 1'b1;
        #10;
        start_pulse = 1'b0;
    end

    systolic_bram_reader #(
        .M(M),
        .K(K),
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(5)
    ) bram_reader_i (
        .clk        (sim_clk),
        .rst_l      (rst_l),
        .start      (start_pulse),
        .busy       (reader_busy),
        .feed_valid (reader_feed_valid),
        .feed_last  (reader_feed_last),
        .a_feed     (a_feed),
        .b_feed     (b_feed)
    );

    matmul_unit #(
        .M(M),
        .K(K),
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) matmul_i (
        .clk        (sim_clk),
        .rst_l      (rst_l),
        .start      (start_pulse),
        .busy       (matmul_busy),
        .valid_out  (matmul_valid),
        .a_feed     (a_feed),
        .b_feed     (b_feed),
        .feed_valid (reader_feed_valid),
        .feed_last  (reader_feed_last),
        .matrix_c   (matrix_c)
    );

    always_comb begin
        LED = '0;
        LED[0] = reader_busy;
        LED[1] = matmul_busy;
        LED[2] = reader_feed_valid;
        LED[3] = matmul_valid;
        LED[15:4] = matrix_c[11:0];

        seg = 7'b1111111;
        dp = 1'b1;
        an = 8'b11111111;
        UART_RXD_OUT = 1'b0;
    end

endmodule
