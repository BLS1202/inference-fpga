//`timescale 1ns/1ps

// Nexys A7 hardware UART echo top.
// Receives one UART byte from the USB-UART bridge and sends the same byte back.
//
// For the current 20 ns / 50 MHz project clock and 115200 baud:
//   CLKS_PER_BIT = 50_000_000 / 115200 ~= 434
module nexys_a7_uart_echo_top #(
    parameter int CLKS_PER_BIT = 434
) (
    input  logic        CLK100MHZ,
    input  logic [1:0]  sw,
    input  logic        btnc,
    input  logic        UART_TXD_IN,
    output logic        UART_RXD_OUT,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [7:0]  an,
    output logic [15:0] LED
);

    typedef enum logic [1:0] {
        ST_WAIT_RX,
        ST_SEND,
        ST_WAIT_TX
    } state_t;

    state_t state;

    logic [1:0] reset_sync;
    logic rst_l;

    logic uart_rx_valid;
    logic [7:0] uart_rx_data;
    logic uart_rx_busy;
    logic uart_frame_error;

    logic uart_tx_valid;
    logic [7:0] uart_tx_data;
    logic uart_tx_ready;
    logic uart_tx_busy;
    logic uart_tx_done;

    logic [7:0] last_rx_data;
    logic [7:0] last_tx_data;
    logic [15:0] sevenseg_value;
    
    logic clk_50mhz, clk_locked;
    assign clk_locked = 0;
    clk_wiz_0 clk_wiz_i (
        .clk_in1(CLK100MHZ),
        .reset(sw[1]),
        .clk_out1(clk_50mhz),
        .locked(clk_locked)
    );

    always_ff @(posedge clk_50mhz or posedge sw[1]) begin
        if (sw[1]) begin
            reset_sync <= 2'b00;
        end else begin
            reset_sync <= {reset_sync[0], 1'b1};
        end
    end

    assign rst_l = reset_sync[1];

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_rx_i (
        .clk(clk_50mhz),
        .rst_l(rst_l),
        .rx(UART_TXD_IN),
        .rx_valid(uart_rx_valid),
        .rx_data(uart_rx_data),
        .rx_busy(uart_rx_busy),
        .frame_error(uart_frame_error)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_i (
        .clk(clk_50mhz),
        .rst_l(rst_l),
        .tx_valid(uart_tx_valid),
        .tx_data(uart_tx_data),
        .tx(UART_RXD_OUT),
        .tx_ready(uart_tx_ready),
        .tx_busy(uart_tx_busy),
        .tx_done(uart_tx_done)
    );

    sevenseg sevenseg_i (
        .clk   (clk_50mhz),
        .rst_l (rst_l),
        .value (sevenseg_value),
        .seg   (seg),
        .dp    (dp),
        .an    (an)
    );

    always_ff @(posedge clk_50mhz or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_WAIT_RX;
            uart_tx_valid <= 1'b0;
            uart_tx_data <= '0;
            last_rx_data <= '0;
            last_tx_data <= '0;
        end else begin
            uart_tx_valid <= 1'b0;

            case (state)
                ST_WAIT_RX: begin
                    if (uart_rx_valid && !uart_frame_error) begin
                        last_rx_data <= uart_rx_data;
                        uart_tx_data <= uart_rx_data;
                        state <= ST_SEND;
                    end
                end

                ST_SEND: begin
                    if (uart_tx_ready) begin
                        uart_tx_valid <= 1'b1;
                        last_tx_data <= uart_tx_data;
                        state <= ST_WAIT_TX;
                    end
                end

                ST_WAIT_TX: begin
                    if (uart_tx_done)
                        state <= ST_WAIT_RX;
                end

                default: begin
                    state <= ST_WAIT_RX;
                end
            endcase
        end
    end

    always_comb begin
        sevenseg_value = {last_tx_data, last_rx_data};

        LED = '0;
        LED[0] = uart_rx_busy;
        LED[1] = uart_rx_valid;
        LED[2] = uart_tx_busy;
        LED[3] = uart_tx_done;
        LED[4] = uart_frame_error;
        LED[6:5] = state;
        LED[15:8] = last_rx_data;
    end
endmodule : nexys_a7_uart_echo_top
