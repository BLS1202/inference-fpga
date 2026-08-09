`timescale 1ns/1ps

// Reads one token-embedding row and one position-embedding row from
// synchronous BRAMs, one feature per cycle.
module embedding_bram_reader #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int DATA_WIDTH = 16,
    parameter int BRAM_ADDR_WIDTH = 12,
    parameter int TOKEN_ID_WIDTH = (VOCAB_SIZE <= 1) ? 1 : $clog2(VOCAB_SIZE),
    parameter int POS_ID_WIDTH = (BLOCK_SIZE <= 1) ? 1 : $clog2(BLOCK_SIZE)
) (
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [TOKEN_ID_WIDTH-1:0] token_id,
    input logic [POS_ID_WIDTH-1:0] pos_id,

    output logic token_bram_en,
    output logic [BRAM_ADDR_WIDTH-1:0] token_bram_addr,
    input logic [DATA_WIDTH-1:0] token_bram_dout,

    output logic pos_bram_en,
    output logic [BRAM_ADDR_WIDTH-1:0] pos_bram_addr,
    input logic [DATA_WIDTH-1:0] pos_bram_dout,

    output logic busy,
    output logic valid_out,
    output logic signed [N_EMBD*DATA_WIDTH-1:0] token_embedding,
    output logic signed [N_EMBD*DATA_WIDTH-1:0] position_embedding
);

    localparam int INDEX_WIDTH = (N_EMBD <= 1) ? 1 : $clog2(N_EMBD);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_READ,
        ST_DRAIN,
        ST_DONE
    } state_t;

    state_t state;

    logic [INDEX_WIDTH-1:0] issue_index;
    logic [INDEX_WIDTH-1:0] issue_index_d1;
    logic [INDEX_WIDTH-1:0] issue_index_d2;

    logic [BRAM_ADDR_WIDTH-1:0] token_base_addr;
    logic [BRAM_ADDR_WIDTH-1:0] pos_base_addr;

    logic request_valid_d1;
    logic request_valid_d2;

    assign busy = (state != ST_IDLE);

    // Keep ena asserted for the request cycle and two additional cycles.
    // This allows the final requested word to propagate through a BRAM with
    // two-cycle read latency after the FSM enters ST_DRAIN.
    assign token_bram_en = (state == ST_READ) ||
                           request_valid_d1 || request_valid_d2;
    assign pos_bram_en   = (state == ST_READ) ||
                           request_valid_d1 || request_valid_d2;

    assign token_bram_addr = token_base_addr + issue_index;
    assign pos_bram_addr   = pos_base_addr + issue_index;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            issue_index <= '0;
            issue_index_d1 <= '0;
            issue_index_d2 <= '0;

            token_base_addr <= '0;
            pos_base_addr <= '0;

            request_valid_d1 <= 1'b0;
            request_valid_d2 <= 1'b0;

            valid_out <= 1'b0;
            token_embedding <= '0;
            position_embedding <= '0;
        end else begin
            valid_out <= 1'b0;

            request_valid_d1 <= (state == ST_READ);
            request_valid_d2 <= request_valid_d1;
            issue_index_d1 <= issue_index;
            issue_index_d2 <= issue_index_d1;

            // Capture one feature from each BRAM when the two-cycle response
            // is valid.
            if (request_valid_d2) begin
                token_embedding[issue_index_d2*DATA_WIDTH +: DATA_WIDTH] <=
                    token_bram_dout;
                position_embedding[issue_index_d2*DATA_WIDTH +: DATA_WIDTH] <=
                    pos_bram_dout;

                if (issue_index_d2 == N_EMBD - 1) begin
                    valid_out <= 1'b1;
                    state <= ST_DONE;
                end
            end

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        token_base_addr <= token_id * N_EMBD;
                        pos_base_addr <= pos_id * N_EMBD;
                        issue_index <= '0;
                        state <= ST_READ;
                    end
                end

                ST_READ: begin
                    if (issue_index == N_EMBD - 1) begin
                        state <= ST_DRAIN;
                    end else begin
                        issue_index <= issue_index + 1'b1;
                    end
                end

                ST_DRAIN: begin
                    // Wait for the final delayed BRAM response. The
                    // response pipeline advances independently of this FSM.
                end

                ST_DONE: begin
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
