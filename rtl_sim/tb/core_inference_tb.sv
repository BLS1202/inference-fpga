module core_inference_tb #(
    parameter int VOCAB_SIZE = 27,
    parameter int BLOCK_SIZE = 16,
    parameter int N_EMBD = 16,
    parameter int N_HEAD = 4,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 64,
    parameter int FRAC_BITS = 12,
    parameter int TOKEN_WIDTH = $clog2(VOCAB_SIZE),
    parameter int POS_WIDTH = $clog2(BLOCK_SIZE),
    parameter int NUM_TOKENS = 5
);
    logic clk;
    logic rst_l;
    logic start;
    logic [TOKEN_WIDTH-1:0] token_id;
    logic [POS_WIDTH-1:0] pos_id;
    logic clear_kv_cache;
    logic busy;
    logic valid_out;
    logic signed [VOCAB_SIZE*DATA_WIDTH-1:0] logits_out;
    logic [VOCAB_SIZE*DATA_WIDTH-1:0] probs_out;
    logic [TOKEN_WIDTH-1:0] next_token;
    logic end_token;

    logic [TOKEN_WIDTH-1:0] input_tokens [0:NUM_TOKENS-1];
    string token_file;

    top_inference #(
        .VOCAB_SIZE(VOCAB_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .N_EMBD(N_EMBD),
        .N_HEAD(N_HEAD),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .TOKEN_WIDTH(TOKEN_WIDTH),
        .POS_WIDTH(POS_WIDTH)
    ) dut (
        .clk(clk),
        .rst_l(rst_l),
        .start(start),
        .token_id(token_id),
        .pos_id(pos_id),
        .clear_kv_cache(clear_kv_cache),
        .busy(busy),
        .valid_out(valid_out),
        .logits_out(logits_out),
        .probs_out(probs_out),
        .next_token(next_token),
        .end_token(end_token)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic print_result;
        begin
            $display("Core inference completed:");
            $display("  input token : %0d", token_id);
            $display("  input pos   : %0d", pos_id);
            $display("  next token  : %0d", next_token);
            $display("  end token   : %0b", end_token);
            $display("  busy        : %0b", busy);
        end
    endtask

    initial begin
        if ($test$plusargs("VCD")) begin
            $dumpfile("build/verilator/core_inference_tb/core_inference_tb.vcd");
            $dumpvars(0, core_inference_tb);
        end

        if (!$value$plusargs("TOKENS=%s", token_file)) begin
            token_file = "generated/reference/input_tokens.mem";
        end
        $readmemh(token_file, input_tokens);

        for (int i = 0; i < NUM_TOKENS; i++) begin
            if (int'(input_tokens[i]) >= VOCAB_SIZE) begin
                $fatal(1, "input token %0d at position %0d is out of range", input_tokens[i], i);
            end
        end

        token_id = '0;
        pos_id = '0;
        rst_l = 1'b0;
        start = 1'b0;
        clear_kv_cache = 1'b0;

        repeat (2) @(posedge clk);
        rst_l = 1'b1;

        // Clear the cache before starting a new sequence.
        @(negedge clk);
        clear_kv_cache = 1'b1;
        @(negedge clk);
        clear_kv_cache = 1'b0;

        // Replay a fixed token sequence. This keeps Python and RTL inputs
        // identical while reference-output comparison is developed later.
        for (int step = 0; step < NUM_TOKENS; step++) begin
            token_id = input_tokens[step];
            pos_id = POS_WIDTH'(step);

            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            for (int cycles = 0; !valid_out && cycles < 100000; cycles++) begin
                @(posedge clk);
            end
            if (!valid_out) begin
                $fatal(1, "timed out waiting for valid_out at step %0d", step);
            end

            // Wait until x_out/probabilities are stable after the DONE edge.
            @(negedge clk);
            print_result();

            if (step < NUM_TOKENS - 1) begin
                // The core leaves ST_DONE on the next rising edge. Wait for
                // that transition before launching the next request.
                @(posedge clk);
            end
        end

        $display("core_inference_tb smoke test passed for %0d tokens", NUM_TOKENS);
        $finish;
    end
endmodule
