//`default_nettype none

module sevenseg (
    input  logic        clk,
    input  logic        rst_l,
    input  logic [31:0] value,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [7:0]  an
);

    logic [17:0] refresh_count;
    logic [2:0]  digit_select;
    logic [3:0]  digit_value;

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l)
            refresh_count <= '0;
        else
            refresh_count <= refresh_count + 1'b1;
    end

    assign digit_select = refresh_count[17:15];

    always_comb begin
        case (digit_select)
            3'd0: begin
                digit_value = value[3:0];
                an = 8'b1111_1110;
            end
            3'd1: begin
                digit_value = value[7:4];
                an = 8'b1111_1101;
            end
            3'd2: begin
                digit_value = value[11:8];
                an = 8'b1111_1011;
            end
            3'd3: begin
                digit_value = value[15:12];
                an = 8'b1111_0111;
            end
            3'd4: begin
                digit_value = value[19:16];
                an = 8'b1110_1111;
            end
            3'd5: begin
                digit_value = value[23:20];
                an = 8'b1101_1111;
            end
            3'd6: begin
                digit_value = value[27:24];
                an = 8'b1011_1111;
            end
            default: begin
                digit_value = value[31:28];
                an = 8'b0111_1111;
            end
        endcase

        // Active-low segment encoding in abcdefg order.
        case (digit_value)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
        endcase

        dp = 1'b1;
    end

endmodule: sevenseg

`default_nettype wire
