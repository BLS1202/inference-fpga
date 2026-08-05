module embedding_rom #(
    parameter int ROWS = 1,
    parameter int COLS = 16,
    parameter int DATA_WIDTH = 16,
    parameter string INIT_FILE = ""
) (
    input  logic                             clk,
    input  logic                             rst_n,
    input  logic                             valid_in,
    input  logic [$clog2(ROWS)-1:0]          row_idx,
    output logic                             valid_out,
    output logic signed [COLS*DATA_WIDTH-1:0] row_data
);

    logic signed [DATA_WIDTH-1:0] mem [0:ROWS*COLS-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            row_data <= '0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                for (int col = 0; col < COLS; col++) begin
                    row_data[col*DATA_WIDTH +: DATA_WIDTH] <= mem[(row_idx * COLS) + col];
                end
            end
        end
    end
endmodule
