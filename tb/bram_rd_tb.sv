`timescale 1ns/1ps

module systolic_bram_reader #(
    parameter int M = 4,
    parameter int K = 5,
    parameter int N = 3,
    parameter int DATA_WIDTH = 16,

    // Use the address width configured in the Vivado BRAM IP.
    // For a depth-32 BRAM, this is 5.
    parameter int BRAM_ADDR_WIDTH = 5
) (
    input  logic clk,
    input  logic rst_l,
    input  logic start,

    output logic busy,
    output logic feed_valid,
    output logic feed_last,

    output logic signed [M*DATA_WIDTH-1:0] a_feed,
    output logic signed [N*DATA_WIDTH-1:0] b_feed
);

    localparam int TOTAL_FEEDS = M + K + N - 2;
    localparam int FEED_COUNT_WIDTH =
        (TOTAL_FEEDS <= 1) ? 1 : $clog2(TOTAL_FEEDS);

    localparam logic [FEED_COUNT_WIDTH-1:0] LAST_FEED =
        TOTAL_FEEDS - 1;

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_RUN,
        ST_DRAIN,
        ST_DONE
    } state_t;

    state_t state;

    logic [FEED_COUNT_WIDTH-1:0] issue_count;
    logic [FEED_COUNT_WIDTH-1:0] issue_count_d1;
    logic [FEED_COUNT_WIDTH-1:0] issue_count_d2;

    logic issue_valid;
    logic issue_valid_d1;
    logic issue_valid_d2;

    logic issue_last;
    logic issue_last_d1;
    logic issue_last_d2;

    logic [BRAM_ADDR_WIDTH-1:0] a_addr [0:M-1];
    logic [BRAM_ADDR_WIDTH-1:0] b_addr [0:N-1];

    logic [DATA_WIDTH-1:0] a_dout [0:M-1];
    logic [DATA_WIDTH-1:0] b_dout [0:N-1];

    logic [M-1:0] a_enable;
    logic [N-1:0] b_enable;

    logic [M-1:0] a_req_valid;
    logic [M-1:0] a_req_valid_d1;
    logic [M-1:0] a_req_valid_d2;

    logic [N-1:0] b_req_valid;
    logic [N-1:0] b_req_valid_d1;
    logic [N-1:0] b_req_valid_d2;

    assign busy = (state != ST_IDLE);

    /*
    * BRAM request control.
    *
    * A BRAM organization:
    *
    *   A_BRAM[row][k] = A[row][k]
    *
    * B BRAM organization:
    *
    *   B_BRAM[col][k] = B[k][col]
    *
    * The address pattern is skewed to match the systolic array.
    */
    always_comb begin
        issue_valid = (state == ST_RUN);
        issue_last  = 1'b0;

        a_enable = '0;
        b_enable = '0;

        if (state == ST_RUN &&
            issue_count == LAST_FEED) begin
            issue_last = 1'b1;
        end

        /*
        * A-side reads:
        *
        *   A[row] = A[row][t-row]
        *
        * where t is the issued systolic-feed cycle.
        */
        for (int row = 0; row < M; row++) begin
            int a_index;

            a_index = int'(issue_count) - row;

            if ((a_index >= 0) && (a_index < K)) begin
                a_addr[row] = a_index[BRAM_ADDR_WIDTH-1:0];
                a_req_valid[row] = (state == ST_RUN);
            end else begin
                a_addr[row] = '0;
                a_req_valid[row] = 1'b0;
            end

            a_enable[row] = a_req_valid[row] ||
                             a_req_valid_d1[row] ||
                             a_req_valid_d2[row];
        end

        /*
        * B-side reads:
        *
        * B BRAM column col is read at matrix row:
        *
        *   k = t-col
        *
        * The delayed output is sent directly to the top of PE column col.
        */
        for (int col = 0; col < N; col++) begin
            int b_index;

            b_index = int'(issue_count) - col;

            if ((b_index >= 0) && (b_index < K)) begin
                b_addr[col] = b_index[BRAM_ADDR_WIDTH-1:0];
                b_req_valid[col] = (state == ST_RUN);
            end else begin
                b_addr[col] = '0;
                b_req_valid[col] = 1'b0;
            end

            b_enable[col] = b_req_valid[col] ||
                            b_req_valid_d1[col] ||
                            b_req_valid_d2[col];
        end
    end

    /*
    * Generate M A BRAMs.
    *
    * Each Vivado IP instance should be initialized with:
    *
    *   a_row_0.coe
    *   a_row_1.coe
    *   ...
    */
//    genvar a_bank;
//    generate
//        for (a_bank = 0; a_bank < M; a_bank++) begin : gen_a_bram

//            blk_mem_gen_1 a_bram (
//                .clka  (clk),
//                .ena   (a_enable),
//                .addra (a_addr[a_bank]),
//                .douta (a_dout[a_bank]),
//                .dina  ('0),
//                .wea   (1'b0)
//            );

//        end
//    endgenerate
    
    blk_mem_gen_0 a_bram1 (
                .clka  (clk),
                .ena   (a_enable[0]),
                .addra (a_addr[0]),
                .douta (a_dout[0]),
                .dina  ('0),
                .wea   (1'b0)
            );
            
    blk_mem_gen_1 a_bram2 (
                .clka  (clk),
                .ena   (a_enable[1]),
                .addra (a_addr[1]),
                .douta (a_dout[1]),
                .dina  ('0),
                .wea   (1'b0)
            );
    blk_mem_gen_2 a_bram3 (
                .clka  (clk),
                .ena   (a_enable[2]),
                .addra (a_addr[2]),
                .douta (a_dout[2]),
                .dina  ('0),
                .wea   (1'b0)
            );
    blk_mem_gen_3 a_bram4 (
                .clka  (clk),
                .ena   (a_enable[3]),
                .addra (a_addr[3]),
                .douta (a_dout[3]),
                .dina  ('0),
                .wea   (1'b0)
            );
    
    

    /*
    * Generate N B BRAMs.
    *
    * Each Vivado IP instance should be initialized with:
    *
    *   b_col_0.coe
    *   b_col_1.coe
    *   ...
    */

    
    blk_mem_gen_4 b_bram0 (
                .clka  (clk),
                .ena   (b_enable[0]),
                .addra (b_addr[0]),
                .douta (b_dout[0]),
                .dina  ('0),
                .wea   (1'b0)
            );
    blk_mem_gen_5 b_bram1 (
                .clka  (clk),
                .ena   (b_enable[1]),
                .addra (b_addr[1]),
                .douta (b_dout[1]),
                .dina  ('0),
                .wea   (1'b0)
            );
            
    blk_mem_gen_6 b_bram2 (
                .clka  (clk),
                .ena   (b_enable[2]),
                .addra (b_addr[2]),
                .douta (b_dout[2]),
                .dina  ('0),
                .wea   (1'b0)
            );


    /*
    * Two-cycle BRAM latency pipeline.
    */
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            issue_valid_d1 <= 1'b0;
            issue_valid_d2 <= 1'b0;

            issue_last_d1 <= 1'b0;
            issue_last_d2 <= 1'b0;

            issue_count_d1 <= '0;
            issue_count_d2 <= '0;

            a_req_valid_d1 <= '0;
            a_req_valid_d2 <= '0;
            b_req_valid_d1 <= '0;
            b_req_valid_d2 <= '0;
        end else begin
            issue_valid_d1 <= issue_valid;
            issue_valid_d2 <= issue_valid_d1;

            issue_last_d1 <= issue_last;
            issue_last_d2 <= issue_last_d1;

            issue_count_d1 <= issue_count;
            issue_count_d2 <= issue_count_d1;

            a_req_valid_d1 <= a_req_valid;
            a_req_valid_d2 <= a_req_valid_d1;
            b_req_valid_d1 <= b_req_valid;
            b_req_valid_d2 <= b_req_valid_d1;
        end
    end

    assign feed_valid = issue_valid_d2;
    assign feed_last  = issue_last_d2;

    /*
    * Form the delayed systolic feed vectors.
    */
    always_comb begin
        a_feed = '0;
        b_feed = '0;

        if (issue_valid_d2) begin

            /*
            * A data already corresponds to:
            *
            *   A[row][feed_cycle-row]
            */
            for (int row = 0; row < M; row++) begin
                int a_index;

                a_index = int'(issue_count_d2) - row;

                if ((a_index >= 0) && (a_index < K)) begin
                    a_feed[row*DATA_WIDTH +: DATA_WIDTH] =
                        a_dout[row];
                end
            end

            /*
            * Each B BRAM stores one complete matrix column:
            *
            *   B_BRAM[col][k] = B[k][col]
            */
            for (int col = 0; col < N; col++) begin
                int b_index;

                b_index = int'(issue_count_d2) - col;

                if ((b_index >= 0) && (b_index < K)) begin
                    b_feed[col*DATA_WIDTH +: DATA_WIDTH] =
                        b_dout[col];
                end
            end
        end
    end

    /*
    * Reader FSM.
    */
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state       <= ST_IDLE;
            issue_count <= '0;
        end else begin
            case (state)

                ST_IDLE: begin
                    if (start) begin
                        issue_count <= '0;
                        state       <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    if (issue_count == LAST_FEED) begin
                        state <= ST_DRAIN;
                    end else begin
                        issue_count <= issue_count + 1'b1;
                    end
                end

                ST_DRAIN: begin
                    /*
                    * Wait for the final two-cycle BRAM result.
                    */
                    if (!issue_valid_d1 && !issue_valid_d2) begin
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
