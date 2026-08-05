module rmsnorm #(
    parameter int N_EMBD = 16,
    parameter int IN_WIDTH = 16,
    parameter int OUT_WIDTH = 16,
    parameter int FRAC_BITS = 12,
    parameter int EPS_Q24 = 168
) (
    input  logic clk,
    input  logic rst_l,

    input  logic valid_in,
    input  logic signed [N_EMBD*IN_WIDTH-1:0] x_in,

    output logic valid_out,
    output logic signed [N_EMBD*OUT_WIDTH-1:0] x_out
);

    localparam int SQUARE_WIDTH = 2 * IN_WIDTH;
    localparam int SUM_WIDTH    = SQUARE_WIDTH + $clog2(N_EMBD);
    localparam logic [SUM_WIDTH-1:0] N_EMBD_VALUE = SUM_WIDTH'(N_EMBD);
    localparam logic [SUM_WIDTH-1:0] EPS_VALUE = SUM_WIDTH'(EPS_Q24);

    logic signed [IN_WIDTH-1:0] x[N_EMBD];
    logic [SQUARE_WIDTH-1:0] square[N_EMBD];

    logic [SUM_WIDTH-1:0] sum1[N_EMBD/2];
    logic [SUM_WIDTH-1:0] sum2[N_EMBD/4];
    logic [SUM_WIDTH-1:0] sum3[N_EMBD/8];
    logic [SUM_WIDTH-1:0] fin_sum;

    logic start, busy, valid;
    logic [SUM_WIDTH-1:0] rad, root, rem;

    enum logic [2:0] {IDLE, S1, S2, S3, S4, SQRT, S5} state, nState;

    genvar i;
    generate
        for (i = 0; i < N_EMBD; i++) begin : unpack_and_square
            always_comb begin
                square[i] = $unsigned(
                    $signed({{IN_WIDTH{x[i][IN_WIDTH-1]}}, x[i]}) *
                    $signed({{IN_WIDTH{x[i][IN_WIDTH-1]}}, x[i]})
                );
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            for (int k = 0; k < N_EMBD; k++) begin
                x[k] <= '0;
            end
        end else if (state == IDLE && valid_in) begin
            for (int k = 0; k < N_EMBD; k++) begin
                x[k] <= $signed(x_in[k*IN_WIDTH +: IN_WIDTH]);
            end
        end
    end

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
        end else begin
            state <= nState;
        end
    end

    always_comb begin
        nState = state;
        unique case (state)
            IDLE: begin
                if (valid_in) nState = S1;
                else nState = IDLE;
            end
            S1: nState = S2;
            S2: nState = S3;
            S3: nState = S4;
            S4: nState = SQRT;
            SQRT: begin
                if (valid) nState = S5;
                else nState = SQRT;
            end
            S5: nState = IDLE;
            default: nState = IDLE;
        endcase
    end

    always_comb begin
        valid_out = (state == S5);
        start = (state == SQRT);
    end

    genvar j;
    generate
        for (j = 0; j < N_EMBD/2; j++) begin : sum_stage1
            always_ff @(posedge clk or negedge rst_l) begin
                if (!rst_l) sum1[j] <= '0;
                else if (state == S1) begin
                    sum1[j] <=
                        {{(SUM_WIDTH-SQUARE_WIDTH){1'b0}}, square[2*j]} +
                        {{(SUM_WIDTH-SQUARE_WIDTH){1'b0}}, square[2*j + 1]};
                end
            end
        end

        for (j = 0; j < N_EMBD/4; j++) begin : sum_stage2
            always_ff @(posedge clk or negedge rst_l) begin
                if (!rst_l) sum2[j] <= '0;
                else if (state == S2) sum2[j] <= sum1[2*j] + sum1[2*j + 1];
            end
        end

        for (j = 0; j < N_EMBD/8; j++) begin : sum_stage3
            always_ff @(posedge clk or negedge rst_l) begin
                if (!rst_l) sum3[j] <= '0;
                else if (state == S3) sum3[j] <= sum2[2*j] + sum2[2*j + 1];
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            fin_sum <= '0;
        end else if (state == S4) begin
            fin_sum <= sum3[0] + sum3[1];
        end
    end

    assign rad = (fin_sum / N_EMBD_VALUE) + EPS_VALUE;

    sqrt_int_fsm #(
        .WIDTH(SUM_WIDTH)
    ) sqrt_unit (
        .clk(clk),
        .rst_l(rst_l),
        .start(start),
        .rad(rad),
        .busy(busy),
        .valid(valid),
        .root(root),
        .rem(rem)
    );

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            x_out <= '0;
        end else if (state == S5) begin
            for (int k = 0; k < N_EMBD; k++) begin
                if (root == '0) begin
                    x_out[k*OUT_WIDTH +: OUT_WIDTH] <= '0;
                end else begin
                    x_out[k*OUT_WIDTH +: OUT_WIDTH] <= sat_out(
                        ($signed({{(SUM_WIDTH+1-IN_WIDTH){x[k][IN_WIDTH-1]}}, x[k]}) <<< FRAC_BITS) /
                        $signed({1'b0, root})
                    );
                end
            end
        end
    end

    function automatic logic signed [OUT_WIDTH-1:0] sat_out;
        input logic signed [SUM_WIDTH:0] value;
        logic signed [SUM_WIDTH:0] max_out;
        logic signed [SUM_WIDTH:0] min_out;
        begin
            max_out = {{(SUM_WIDTH+1-OUT_WIDTH){1'b0}}, 1'b0, {(OUT_WIDTH-1){1'b1}}};
            min_out = {{(SUM_WIDTH+1-OUT_WIDTH){1'b1}}, 1'b1, {(OUT_WIDTH-1){1'b0}}};

            if (value > max_out) begin
                sat_out = {1'b0, {(OUT_WIDTH-1){1'b1}}};
            end else if (value < min_out) begin
                sat_out = {1'b1, {(OUT_WIDTH-1){1'b0}}};
            end else begin
                sat_out = value[OUT_WIDTH-1:0];
            end
        end
    endfunction

endmodule: rmsnorm
