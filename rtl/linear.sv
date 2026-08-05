module linear_layer #(
    parameter int IN_FEATURES = 16,
    parameter int OUT_FEATURES = 16,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12,
    parameter string WEIGHT_INIT_FILE = ""
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,

    output logic busy,
    output logic valid_out,

    input  logic signed [IN_FEATURES*DATA_WIDTH-1:0] x_in,
    output logic signed [OUT_FEATURES*DATA_WIDTH-1:0] y_out
);

    logic signed [IN_FEATURES*OUT_FEATURES*DATA_WIDTH-1:0] weight_matrix;
    logic signed [OUT_FEATURES*DATA_WIDTH-1:0] matmul_out;
    logic signed [DATA_WIDTH-1:0] weight_mem [0:OUT_FEATURES*IN_FEATURES-1];

    initial begin
        if (WEIGHT_INIT_FILE != "") begin
            $readmemh(WEIGHT_INIT_FILE, weight_mem);
        end
    end

    always_comb begin
        for (int out_idx = 0; out_idx < OUT_FEATURES; out_idx++) begin
            for (int in_idx = 0; in_idx < IN_FEATURES; in_idx++) begin
                weight_matrix[((in_idx*OUT_FEATURES + out_idx) * DATA_WIDTH) +: DATA_WIDTH] =
                    weight_mem[(out_idx*IN_FEATURES) + in_idx];
            end
        end
    end

    matmul_unit #(
        .M(1),
        .K(IN_FEATURES),
        .N(OUT_FEATURES),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) matmul_i (
        .clk(clk),
        .rst_l(rst_l),
        .start(start),
        .busy(busy),
        .valid_out(valid_out),
        .matrix_a(x_in),
        .matrix_b(weight_matrix),
        .matrix_c(matmul_out)
    );

    assign y_out = matmul_out;
endmodule : linear_layer
