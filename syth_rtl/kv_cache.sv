module kv_cache #(
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int DATA_WIDTH = 16,
    parameter int POS_WIDTH = $clog2(BLOCK_SIZE)
) (
    input  logic clk,
    input  logic rst_l,
    input  logic clear,
    input  logic write_en,
    input  logic [POS_WIDTH-1:0] write_pos,
    input  logic signed [N_EMBD*DATA_WIDTH-1:0] key_in,
    input  logic signed [N_EMBD*DATA_WIDTH-1:0] value_in,
    output logic signed [BLOCK_SIZE*N_EMBD*DATA_WIDTH-1:0] keys_out,
    output logic signed [BLOCK_SIZE*N_EMBD*DATA_WIDTH-1:0] values_out
);

    logic signed [DATA_WIDTH-1:0] key_mem [0:BLOCK_SIZE-1][0:N_EMBD-1];
    logic signed [DATA_WIDTH-1:0] value_mem [0:BLOCK_SIZE-1][0:N_EMBD-1];

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            for (int pos = 0; pos < BLOCK_SIZE; pos++) begin
                for (int i = 0; i < N_EMBD; i++) begin
                    key_mem[pos][i] <= '0;
                    value_mem[pos][i] <= '0;
                end
            end
        end else if (clear) begin
            for (int pos = 0; pos < BLOCK_SIZE; pos++) begin
                for (int i = 0; i < N_EMBD; i++) begin
                    key_mem[pos][i] <= '0;
                    value_mem[pos][i] <= '0;
                end
            end
        end else if (write_en) begin
            for (int i = 0; i < N_EMBD; i++) begin
                key_mem[write_pos][i] <= key_in[i*DATA_WIDTH +: DATA_WIDTH];
                value_mem[write_pos][i] <= value_in[i*DATA_WIDTH +: DATA_WIDTH];
            end
        end
    end

    always_comb begin
        keys_out = '0;
        values_out = '0;

        for (int pos = 0; pos < BLOCK_SIZE; pos++) begin
            for (int i = 0; i < N_EMBD; i++) begin
                keys_out[((pos*N_EMBD + i) * DATA_WIDTH) +: DATA_WIDTH] = key_mem[pos][i];
                values_out[((pos*N_EMBD + i) * DATA_WIDTH) +: DATA_WIDTH] = value_mem[pos][i];
            end
        end
    end
endmodule : kv_cache
