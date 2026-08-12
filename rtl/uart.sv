// Simple 8-N-1 UART receiver and transmitter.
// Set CLKS_PER_BIT to clk_hz / baud_rate, e.g. 100_000_000 / 115200 = 868.

module uart_rx #(
    parameter int CLKS_PER_BIT = 868
) (
    input  logic       clk,
    input  logic       rst_l,
    input  logic       rx,

    output logic       rx_valid,
    output logic [7:0] rx_data,
    output logic       rx_busy,
    output logic       frame_error
);

    localparam int COUNTER_WIDTH =
        (CLKS_PER_BIT <= 2) ? 1 : $clog2(CLKS_PER_BIT);
    localparam logic [COUNTER_WIDTH-1:0] HALF_BIT =
        COUNTER_WIDTH'((CLKS_PER_BIT - 1) / 2);
    localparam logic [COUNTER_WIDTH-1:0] FULL_BIT =
        COUNTER_WIDTH'(CLKS_PER_BIT - 1);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_START,
        ST_DATA,
        ST_STOP,
        ST_DONE
    } state_t;

    state_t state;
    logic rx_meta;
    logic rx_sync;
    logic [COUNTER_WIDTH-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] rx_shift;

    assign rx_busy = (state != ST_IDLE);

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state       <= ST_IDLE;
            clk_count   <= '0;
            bit_index   <= '0;
            rx_shift    <= '0;
            rx_data     <= '0;
            rx_valid    <= 1'b0;
            frame_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    clk_count   <= '0;
                    bit_index   <= '0;
                    frame_error <= 1'b0;

                    if (!rx_sync)
                        state <= ST_START;
                end

                ST_START: begin
                    if (clk_count == HALF_BIT) begin
                        clk_count <= '0;
                        if (!rx_sync) begin
                            state <= ST_DATA;
                        end else begin
                            state <= ST_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_DATA: begin
                    if (clk_count == FULL_BIT) begin
                        clk_count <= '0;
                        rx_shift[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin
                            bit_index <= '0;
                            state <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_STOP: begin
                    if (clk_count == FULL_BIT) begin
                        clk_count <= '0;
                        rx_data <= rx_shift;
                        rx_valid <= rx_sync;
                        frame_error <= !rx_sync;
                        state <= ST_DONE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
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
endmodule : uart_rx

module uart_tx #(
    parameter int CLKS_PER_BIT = 868
) (
    input  logic       clk,
    input  logic       rst_l,
    input  logic       tx_valid,
    input  logic [7:0] tx_data,

    output logic       tx,
    output logic       tx_ready,
    output logic       tx_busy,
    output logic       tx_done
);

    localparam int COUNTER_WIDTH =
        (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);
    localparam logic [COUNTER_WIDTH-1:0] FULL_BIT =
        COUNTER_WIDTH'(CLKS_PER_BIT - 1);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_START,
        ST_DATA,
        ST_STOP,
        ST_DONE
    } state_t;

    state_t state;
    logic [COUNTER_WIDTH-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] tx_shift;

    assign tx_ready = (state == ST_IDLE);
    assign tx_busy = !tx_ready;

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state     <= ST_IDLE;
            clk_count <= '0;
            bit_index <= '0;
            tx_shift  <= '0;
            tx        <= 1'b1;
            tx_done   <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    tx <= 1'b1;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (tx_valid) begin
                        tx_shift <= tx_data;
                        state <= ST_START;
                    end
                end

                ST_START: begin
                    tx <= 1'b0;
                    if (clk_count == FULL_BIT) begin
                        clk_count <= '0;
                        state <= ST_DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_DATA: begin
                    tx <= tx_shift[bit_index];
                    if (clk_count == FULL_BIT) begin
                        clk_count <= '0;

                        if (bit_index == 3'd7) begin
                            bit_index <= '0;
                            state <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_STOP: begin
                    tx <= 1'b1;
                    if (clk_count == FULL_BIT) begin
                        clk_count <= '0;
                        state <= ST_DONE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_DONE: begin
                    tx_done <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule : uart_tx
