module relu #(
    parameter int VECTOR_SIZE = 64,
    parameter int DATA_WIDTH = 16
) (
    input  logic signed [VECTOR_SIZE*DATA_WIDTH-1:0] x_in,
    output logic signed [VECTOR_SIZE*DATA_WIDTH-1:0] x_out
);

    always_comb begin
        x_out = '0;

        for (int i = 0; i < VECTOR_SIZE; i++) begin
            if ($signed(x_in[i*DATA_WIDTH +: DATA_WIDTH]) > 0) begin
                x_out[i*DATA_WIDTH +: DATA_WIDTH] = x_in[i*DATA_WIDTH +: DATA_WIDTH];
            end else begin
                x_out[i*DATA_WIDTH +: DATA_WIDTH] = '0;
            end
        end
    end
endmodule : relu
