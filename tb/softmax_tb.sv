module softmax_tb #(
    parameter int VECTOR_SIZE = 16,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH = 32,
    parameter int FRAC_BITS = 12,
    parameter int EXP_ADDR_WIDTH = 12,
    parameter int EXP_LUT_SIZE = 1 << EXP_ADDR_WIDTH,
    parameter string EXP_INIT_FILE = "generated/softmax/exp_lut.mem"
);
    logic clk, rst_l, start, busy, valid_out;
    logic signed [VECTOR_SIZE*DATA_WIDTH-1:0] logits;
    logic [VECTOR_SIZE*DATA_WIDTH-1:0] probs;
    logic signed [DATA_WIDTH-1:0] logits_mem [0:VECTOR_SIZE-1];
    logic [DATA_WIDTH-1:0] expected_mem [0:VECTOR_SIZE-1];
    string logits_file, expected_file, lut_file;

    softmax_unit #(.VECTOR_SIZE(VECTOR_SIZE), .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
                   .FRAC_BITS(FRAC_BITS), .EXP_ADDR_WIDTH(EXP_ADDR_WIDTH),
                   .EXP_LUT_SIZE(EXP_LUT_SIZE), .EXP_INIT_FILE(EXP_INIT_FILE)) dut (.*);

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        if ($test$plusargs("VCD")) begin
            $dumpfile("build/verilator/softmax_tb/softmax_tb.vcd");
            $dumpvars(0, softmax_tb);
        end
        if (!$value$plusargs("LOGITS=%s", logits_file)) logits_file = "generated/softmax/softmax_logits.mem";
        if (!$value$plusargs("EXPECTED=%s", expected_file)) expected_file = "generated/softmax/softmax_expected.mem";
        if (!$value$plusargs("LUT=%s", lut_file)) lut_file = "generated/softmax/exp_lut.mem";
        $readmemh(logits_file, logits_mem);
        $readmemh(expected_file, expected_mem);
        $readmemh(lut_file, dut.exp_lut);
        logits = '0;
        for (int i = 0; i < VECTOR_SIZE; i++) logits[i*DATA_WIDTH +: DATA_WIDTH] = logits_mem[i];
        rst_l = 0; start = 0;
        repeat (2) @(posedge clk);
        rst_l = 1;
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        for (int cycles = 0; !valid_out && cycles < 1000; cycles++) @(posedge clk);
        if (!valid_out) $fatal(1, "timed out waiting for valid_out");
        for (int i = 0; i < VECTOR_SIZE; i++) begin
            logic [DATA_WIDTH-1:0] actual;
            actual = probs[i*DATA_WIDTH +: DATA_WIDTH];
            $write("prob[%0d]=0x%04h (%0d) ", i, actual, actual);
            if (actual !== expected_mem[i])
                $fatal(1, "softmax mismatch at index %0d: got 0x%04h expected 0x%04h", i, actual, expected_mem[i]);
        end
        $display("");
        $display("softmax_tb passed VECTOR_SIZE=%0d", VECTOR_SIZE);
        $finish;
    end
endmodule
