`timescale 1ns/1ps

module uart_echo #(
    parameter int CLKS_PER_BIT = 16
) (
    input  logic clk,
    input  logic rst_l,
    input  logic uart_rx_i,
    output logic uart_tx_o
);

    typedef enum logic [1:0] {
        ST_WAIT_RX,
        ST_SEND,
        ST_WAIT_TX
    } state_t;

    state_t state;
    logic rx_valid;
    logic [7:0] rx_data;
    logic rx_busy;
    logic frame_error;
    logic tx_valid;
    logic [7:0] tx_data;
    logic tx_ready;
    logic tx_busy;
    logic tx_done;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) echo_rx_i (
        .clk(clk),
        .rst_l(rst_l),
        .rx(uart_rx_i),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .frame_error(frame_error)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) echo_tx_i (
        .clk(clk),
        .rst_l(rst_l),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx(uart_tx_o),
        .tx_ready(tx_ready),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= ST_WAIT_RX;
            tx_valid <= 1'b0;
            tx_data <= '0;
        end else begin
            tx_valid <= 1'b0;

            case (state)
                ST_WAIT_RX: begin
                    if (rx_valid && !frame_error) begin
                        tx_data <= rx_data;
                        state <= ST_SEND;
                    end
                end

                ST_SEND: begin
                    if (tx_ready) begin
                        tx_valid <= 1'b1;
                        state <= ST_WAIT_TX;
                    end
                end

                ST_WAIT_TX: begin
                    if (tx_done)
                        state <= ST_WAIT_RX;
                end

                default: begin
                    state <= ST_WAIT_RX;
                end
            endcase
        end
    end
endmodule : uart_echo

module uart_echo_tb #(
    parameter int CLKS_PER_BIT = 16
);

    logic clk;
    logic rst_l;
    logic host_to_fpga;
    logic fpga_to_host;

    logic host_tx_valid;
    logic [7:0] host_tx_data;
    logic host_tx_ready;
    logic host_tx_busy;
    logic host_tx_done;

    logic host_rx_valid;
    logic [7:0] host_rx_data;
    logic host_rx_busy;
    logic host_frame_error;
    logic tb_error;

    logic [7:0] test_bytes [0:7];

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) host_tx_i (
        .clk(clk),
        .rst_l(rst_l),
        .tx_valid(host_tx_valid),
        .tx_data(host_tx_data),
        .tx(host_to_fpga),
        .tx_ready(host_tx_ready),
        .tx_busy(host_tx_busy),
        .tx_done(host_tx_done)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) host_rx_i (
        .clk(clk),
        .rst_l(rst_l),
        .rx(fpga_to_host),
        .rx_valid(host_rx_valid),
        .rx_data(host_rx_data),
        .rx_busy(host_rx_busy),
        .frame_error(host_frame_error)
    );

    uart_echo #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst_l(rst_l),
        .uart_rx_i(host_to_fpga),
        .uart_tx_o(fpga_to_host)
    );

    task automatic send_byte(input logic [7:0] data);
        begin
            while (!host_tx_ready)
                @(posedge clk);
            @(negedge clk);
            host_tx_data = data;
            host_tx_valid = 1'b1;
            @(negedge clk);
            host_tx_valid = 1'b0;
            @(posedge host_tx_done);
            @(posedge clk);
        end
    endtask

    task automatic wait_echo(output logic [7:0] data);
        begin
            for (int cycles = 0; !host_rx_valid && cycles < 10000; cycles++)
                @(posedge clk);
            if (!host_rx_valid) begin
                tb_error = 1'b1;
                data = '0;
            end else begin
                if (host_frame_error)
                    tb_error = 1'b1;
                data = host_rx_data;
                @(posedge clk);
            end
        end
    endtask

    initial begin
        if ($test$plusargs("VCD")) begin
            $dumpfile("build/verilator/uart_echo_tb/uart_echo_tb.vcd");
            $dumpvars(0, uart_echo_tb);
        end

        test_bytes[0] = 8'h00;
        test_bytes[1] = 8'h01;
        test_bytes[2] = 8'h1a;
        test_bytes[3] = 8'h55;
        test_bytes[4] = 8'haa;
        test_bytes[5] = 8'hff;
        test_bytes[6] = 8'h10;
        test_bytes[7] = 8'h0d;

        rst_l = 1'b0;
        host_tx_valid = 1'b0;
        host_tx_data = '0;
        tb_error = 1'b0;

        repeat (5) @(posedge clk);
        rst_l = 1'b1;
        repeat (5) @(posedge clk);

        for (int i = 0; i < 8; i++) begin
            logic [7:0] echoed;
            send_byte(test_bytes[i]);
            wait_echo(echoed);
            if (echoed != test_bytes[i])
                tb_error = 1'b1;
        end

        repeat (10) @(posedge clk);
        $finish;
    end
endmodule : uart_echo_tb
