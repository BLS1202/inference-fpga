module embedding_lookup_tb;
    localparam int VOCAB_SIZE = 27;
    localparam int BLOCK_SIZE = 16;
    localparam int N_EMBD = 16;
    localparam int DATA_WIDTH = 16;
    localparam int SUM_WIDTH = 18;
    localparam int NUM_CASES = 4;

    logic clk;
    logic rst_n;
    logic valid_in;
    logic [$clog2(VOCAB_SIZE)-1:0] token_id;
    logic [$clog2(BLOCK_SIZE)-1:0] pos_id;
    logic valid_out;
    logic signed [N_EMBD*SUM_WIDTH-1:0] embedding;

    int case_token [0:NUM_CASES-1];
    int case_pos [0:NUM_CASES-1];
    int case_expected [0:NUM_CASES-1][0:N_EMBD-1];

    embedding_lookup #(
        .WTE_INIT_FILE("microgpt/generated/wte_q12.hex"),
        .WPE_INIT_FILE("microgpt/generated/wpe_q12.hex")
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .token_id(token_id),
        .pos_id(pos_id),
        .valid_out(valid_out),
        .embedding(embedding)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        int fd;
        int scanned;

        fd = $fopen("microgpt/generated/embedding_lookup_cases.txt", "r");
        if (fd == 0) begin
            $fatal(1, "failed to open embedding lookup case file");
        end

        for (int c = 0; c < NUM_CASES; c++) begin
            scanned = $fscanf(
                fd,
                "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
                case_token[c],
                case_pos[c],
                case_expected[c][0],
                case_expected[c][1],
                case_expected[c][2],
                case_expected[c][3],
                case_expected[c][4],
                case_expected[c][5],
                case_expected[c][6],
                case_expected[c][7],
                case_expected[c][8],
                case_expected[c][9],
                case_expected[c][10],
                case_expected[c][11],
                case_expected[c][12],
                case_expected[c][13],
                case_expected[c][14],
                case_expected[c][15]
            );
            if (scanned != 18) begin
                $fatal(1, "malformed embedding lookup case %0d, scanned %0d fields", c, scanned);
            end
        end
        $fclose(fd);

        rst_n = 1'b0;
        valid_in = 1'b0;
        token_id = '0;
        pos_id = '0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        for (int c = 0; c < NUM_CASES; c++) begin
            @(negedge clk);
            valid_in = 1'b1;
            token_id = case_token[c][$clog2(VOCAB_SIZE)-1:0];
            pos_id = case_pos[c][$clog2(BLOCK_SIZE)-1:0];

            @(posedge clk);
            #1;
            if (!valid_out) begin
                $fatal(1, "valid_out was low for case %0d", c);
            end
            for (int i = 0; i < N_EMBD; i++) begin
                if ($signed(embedding[i*SUM_WIDTH +: SUM_WIDTH]) != case_expected[c][i]) begin
                    $fatal(
                        1,
                        "case %0d elem %0d mismatch: got %0d expected %0d",
                        c,
                        i,
                        $signed(embedding[i*SUM_WIDTH +: SUM_WIDTH]),
                        case_expected[c][i]
                    );
                end
            end
            valid_in = 1'b0;
        end

        $display("embedding_lookup_tb passed");
        $finish;
    end
endmodule
