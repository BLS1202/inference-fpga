package fixed_point_utils;

    function automatic signed [15:0] sat16;
        input signed [63:0] value;
        begin
            if (value > 64'sd32767) begin
                sat16 = 16'sd32767;
            end else if (value < -64'sd32768) begin
                sat16 = -16'sd32768;
            end else begin
                sat16 = value[15:0];
            end
        end
    endfunction

    function automatic signed [15:0] sat_add16;
        input signed [15:0] a;
        input signed [15:0] b;
        logic signed [16:0] sum;
        begin
            sum = $signed(a) + $signed(b);

            if (sum > 17'sd32767) begin
                sat_add16 = 16'sd32767;
            end else if (sum < -17'sd32768) begin
                sat_add16 = -16'sd32768;
            end else begin
                sat_add16 = sum[15:0];
            end
        end
    endfunction

    function automatic signed [15:0] sat_sub16;
        input signed [15:0] a;
        input signed [15:0] b;
        logic signed [16:0] diff;
        begin
            diff = $signed(a) - $signed(b);

            if (diff > 17'sd32767) begin
                sat_sub16 = 16'sd32767;
            end else if (diff < -17'sd32768) begin
                sat_sub16 = -16'sd32768;
            end else begin
                sat_sub16 = diff[15:0];
            end
        end
    endfunction

    function automatic signed [15:0] mul_q12;
        input signed [15:0] a;
        input signed [15:0] b;
        logic signed [63:0] product;
        begin
            product = $signed(a) * $signed(b);
            mul_q12 = sat16(product >>> 12);
        end
    endfunction

    function automatic signed [15:0] acc_to_q12;
        input signed [63:0] acc;
        begin
            acc_to_q12 = sat16(acc >>> 12);
        end
    endfunction

    function automatic signed [15:0] div_q12;
        input signed [15:0] numerator;
        input signed [15:0] denominator;
        logic signed [63:0] scaled_num;
        begin
            if (denominator == 16'sd0) begin
                div_q12 = '0;
            end else begin
                scaled_num =
                    $signed({{48{numerator[15]}}, numerator}) <<< 12;
                div_q12 = sat16(
                    scaled_num /
                    $signed({{48{denominator[15]}}, denominator})
                );
            end
        end
    endfunction

    function automatic signed [15:0] relu16;
        input signed [15:0] value;
        begin
            if (value > 16'sd0) begin
                relu16 = value;
            end else begin
                relu16 = 16'sd0;
            end
        end
    endfunction

    function automatic signed [15:0] mask_future_logit;
        input logic is_valid_position;
        input signed [15:0] value;
        begin
            if (is_valid_position) begin
                mask_future_logit = value;
            end else begin
                mask_future_logit = -16'sd32768;
            end
        end
    endfunction

endpackage : fixed_point_utils
