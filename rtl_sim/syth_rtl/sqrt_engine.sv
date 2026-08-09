module sqrt_int_fsm #(
    parameter int WIDTH = 16
) (
    input  logic             clk,
    input  logic             rst_l,
    input  logic             start,
    input  logic [WIDTH-1:0] rad,
    output logic             busy,
    output logic             valid,
    output logic [WIDTH-1:0] root,
    output logic [WIDTH-1:0] rem
);

    localparam int ITER = WIDTH >> 1;
    localparam int CW   = (ITER <= 1) ? 1 : $clog2(ITER);
    localparam logic [CW-1:0] ITER_LAST = CW'(ITER - 1);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_INIT,
        ST_ITER,
        ST_DONE
    } state_t;

    state_t state_reg, state_next;

    logic [WIDTH-1:0] x_reg, x_next;
    logic [WIDTH-1:0] q_reg, q_next;
    logic [WIDTH:0]   rem_reg, rem_next;
    logic [CW-1:0]    i_reg, i_next;

    logic [WIDTH:0] rem_shift;
    logic [WIDTH:0] trial_value;
    logic [WIDTH-1:0] q_shift;

    always_comb begin
        state_next = state_reg;

        x_next  = x_reg;
        q_next  = q_reg;
        rem_next = rem_reg;
        i_next  = i_reg;

        busy  = 1'b0;
        valid = 1'b0;

        q_shift = q_reg << 1;
        rem_shift = {rem_reg[WIDTH-2:0], x_reg[WIDTH-1:WIDTH-2]};
        trial_value = {q_shift, 1'b1};

        case (state_reg)
            ST_IDLE: begin
                if (start)
                    state_next = ST_INIT;
            end

            ST_INIT: begin
                busy    = 1'b1;
                x_next  = rad;
                q_next  = '0;
                rem_next = '0;
                i_next  = '0;
                state_next = ST_ITER;
            end

            ST_ITER: begin
                busy = 1'b1;

                x_next = {x_reg[WIDTH-3:0], 2'b0};

                if (rem_shift >= trial_value) begin
                    rem_next = rem_shift - trial_value;
                    q_next = q_shift | {{(WIDTH-1){1'b0}}, 1'b1};
                end else begin
                    rem_next = rem_shift;
                    q_next = q_shift;
                end

                if (i_reg == ITER_LAST) begin
                    state_next = ST_DONE;
                end else begin
                    i_next = i_reg + 1'b1;
                end
            end

            ST_DONE: begin
                valid = 1'b1;
                state_next = ST_IDLE;
            end

            default: begin
                state_next = ST_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state_reg <= ST_IDLE;
            x_reg     <= '0;
            q_reg     <= '0;
            rem_reg   <= '0;
            i_reg     <= '0;
            root      <= '0;
            rem       <= '0;
        end else begin
            state_reg <= state_next;
            x_reg     <= x_next;
            q_reg     <= q_next;
            rem_reg   <= rem_next;
            i_reg     <= i_next;

            if (state_reg == ST_DONE) begin
                root <= q_reg;
                rem  <= rem_reg[WIDTH-1:0];
            end else if (state_reg == ST_ITER && i_reg == ITER_LAST) begin
                root <= q_next;
                rem  <= rem_next[WIDTH-1:0];
            end
        end
    end

endmodule: sqrt_int_fsm
