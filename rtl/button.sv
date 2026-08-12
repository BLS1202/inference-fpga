// Synchronize and debounce an active-high push button.
// pressed is the debounced level; pressed_pulse is a one-clock rising pulse.
module button #(
    parameter int DEBOUNCE_CLKS = 1_000_000
) (
    input  logic clk,
    input  logic rst_l,
    input  logic button_in,
    output logic pressed,
    output logic pressed_pulse
);

    localparam int COUNT_WIDTH =
        (DEBOUNCE_CLKS <= 1) ? 1 : $clog2(DEBOUNCE_CLKS);
    localparam logic [COUNT_WIDTH-1:0] COUNT_MAX =
        COUNT_WIDTH'(DEBOUNCE_CLKS - 1);

    logic button_meta;
    logic button_sync;
    logic button_sync_prev;
    logic pressed_prev;
    logic [COUNT_WIDTH-1:0] count;

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            button_meta <= 1'b0;
            button_sync <= 1'b0;
        end else begin
            button_meta <= button_in;
            button_sync <= button_meta;
        end
    end

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            button_sync_prev <= 1'b0;
            pressed_prev <= 1'b0;
            pressed <= 1'b0;
            pressed_pulse <= 1'b0;
            count <= '0;
        end else begin
            pressed_pulse <= 1'b0;
            button_sync_prev <= button_sync;
            pressed_prev <= pressed;

            if (button_sync == pressed) begin
                count <= '0;
            end else if (button_sync != button_sync_prev) begin
                count <= '0;
            end else if (count == COUNT_MAX) begin
                pressed <= button_sync;
                count <= '0;
            end else begin
                count <= count + 1'b1;
            end

            if (!pressed_prev && pressed)
                pressed_pulse <= 1'b1;
        end
    end
endmodule : button
