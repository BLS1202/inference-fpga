// Reads one row-major weight tile from a synchronous BRAM.
// The BRAM is assumed to have a two-clock read latency.
module bram_tile_reader #(
    parameter int DATA_WIDTH = 16,
    parameter int TILE_ROWS  = 16,
    parameter int TILE_COLS  = 16,
    parameter int ADDR_WIDTH = 10
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,

    input  logic [ADDR_WIDTH-1:0] base_addr,
    input  logic [ADDR_WIDTH-1:0] row_stride,
    input  logic [ADDR_WIDTH-1:0] col_offset,
    input  logic [$clog2(TILE_ROWS+1)-1:0] valid_rows,

    output logic bram_en,
    output logic [ADDR_WIDTH-1:0] bram_addr,
    input  logic [DATA_WIDTH-1:0] bram_dout,

    output logic busy,
    output logic valid_out,
    output logic signed [TILE_ROWS*TILE_COLS*DATA_WIDTH-1:0] tile_matrix
);

    localparam int TOTAL_WORDS = TILE_ROWS * TILE_COLS;
    localparam int INDEX_WIDTH = (TOTAL_WORDS <= 1) ? 1 : $clog2(TOTAL_WORDS);

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
    logic request_valid_d1;
    logic request_valid_d2;

    logic [ADDR_WIDTH-1:0] base_addr_reg;
    logic [ADDR_WIDTH-1:0] row_stride_reg;
    logic [ADDR_WIDTH-1:0] col_offset_reg;
    logic [$clog2(TILE_ROWS+1)-1:0] valid_rows_reg;
    integer address_value;
    integer address_row;

    assign busy = (state != ST_IDLE);

    // Keep ENA high while the last two issued addresses are returning.
    assign bram_en = (state == ST_READ) || request_valid_d1 || request_valid_d2;

    always_comb begin
        address_row = int'(issue_index) / TILE_COLS;
        if (address_row >= int'(valid_rows_reg))
            address_row = int'(valid_rows_reg) - 1;
        if (address_row < 0)
            address_row = 0;

        address_value = int'(base_addr_reg) +
                        address_row * int'(row_stride_reg) +
                        int'(col_offset_reg) +
                        (int'(issue_index) % TILE_COLS);
        bram_addr = ADDR_WIDTH'(address_value);
    end

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state           <= ST_IDLE;
            issue_index     <= '0;
            issue_index_d1  <= '0;
            issue_index_d2  <= '0;
            request_valid_d1 <= 1'b0;
            request_valid_d2 <= 1'b0;
            base_addr_reg   <= '0;
            row_stride_reg  <= '0;
            col_offset_reg  <= '0;
            valid_rows_reg  <= TILE_ROWS;
            tile_matrix     <= '0;
            valid_out       <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            request_valid_d1 <= (state == ST_READ);
            request_valid_d2 <= request_valid_d1;
            issue_index_d1   <= issue_index;
            issue_index_d2   <= issue_index_d1;

            if (request_valid_d2) begin
                tile_matrix[(int'(issue_index_d2) * DATA_WIDTH) +: DATA_WIDTH]
                    <= bram_dout;
            end

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        base_addr_reg  <= base_addr;
                        row_stride_reg <= row_stride;
                        col_offset_reg <= col_offset;
                        valid_rows_reg <= valid_rows;
                        issue_index    <= '0;
                        state          <= ST_READ;
                    end
                end

                ST_READ: begin
                    if (int'(issue_index) == TOTAL_WORDS - 1) begin
                        state <= ST_DRAIN;
                    end else begin
                        issue_index <= issue_index + 1'b1;
                    end
                end

                ST_DRAIN: begin
                    if (request_valid_d2 &&
                        int'(issue_index_d2) == TOTAL_WORDS - 1) begin
                        valid_out <= 1'b1;
                        state <= ST_DONE;
                    end
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
