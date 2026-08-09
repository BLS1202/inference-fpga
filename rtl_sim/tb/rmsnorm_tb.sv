module rmsnorm_tb #(
    parameter int N_EMBD = 16,
    parameter int IN_WIDTH = 16,
    parameter int OUT_WIDTH = 16,
    parameter int FRAC_BITS = 12,
    parameter int EPS_Q24 = 168
);
    logic clk, rst_l, valid_in, valid_out;
    logic signed [N_EMBD*IN_WIDTH-1:0] x_in;
    logic signed [N_EMBD*OUT_WIDTH-1:0] x_out;
    logic signed [IN_WIDTH-1:0] input_mem [0:N_EMBD-1];
    logic signed [OUT_WIDTH-1:0] expected_mem [0:N_EMBD-1];
    string input_file, expected_file;

    rmsnorm #(.N_EMBD(N_EMBD), .IN_WIDTH(IN_WIDTH), .OUT_WIDTH(OUT_WIDTH),
              .FRAC_BITS(FRAC_BITS), .EPS_Q24(EPS_Q24)) dut (.*);

    initial begin clk = 0; forever #5 clk = ~clk; end

    task automatic pack_input;
        for (int i = 0; i < N_EMBD; i++) x_in[i*IN_WIDTH +: IN_WIDTH] = input_mem[i];
    endtask

    task automatic print_output;
        logic signed [OUT_WIDTH-1:0] value;
        begin
            $display("Calculated RMSNorm output from DUT:");
            $write("  ");
            for (int i = 0; i < N_EMBD; i++) begin
                value = x_out[i*OUT_WIDTH +: OUT_WIDTH];
                $write("0x%04h(%0d) ", value, value);
            end
            $display("");
        end
    endtask

    task automatic check_output;
        logic signed [OUT_WIDTH-1:0] actual;
        begin
            for (int i = 0; i < N_EMBD; i++) begin
                actual = x_out[i*OUT_WIDTH +: OUT_WIDTH];
                if (actual !== expected_mem[i]) begin
                    $fatal(
                        1,
                        "RMSNorm mismatch at index %0d: got 0x%04h (%0d), expected 0x%04h (%0d)",
                        i,
                        actual,
                        actual,
                        expected_mem[i],
                        expected_mem[i]
                    );
                end
            end
        end
    endtask

    initial begin
        if ($test$plusargs("VCD")) begin
            $dumpfile("build/verilator/rmsnorm_tb/rmsnorm_tb.vcd");
            $dumpvars(0, rmsnorm_tb);
        end
        if (!$value$plusargs("INPUT=%s", input_file)) input_file = "generated/rmsnorm/rmsnorm_input.mem";
        if (!$value$plusargs("EXPECTED=%s", expected_file)) expected_file = "generated/rmsnorm/rmsnorm_expected.mem";
        $readmemh(input_file, input_mem);
        $readmemh(expected_file, expected_mem);
        rst_l = 0; valid_in = 0; x_in = '0;
        repeat (2) @(posedge clk);
        rst_l = 1;
        @(negedge clk);
        pack_input();
        valid_in = 1;
        @(negedge clk);
        valid_in = 0;
        for (int cycles = 0; !valid_out && cycles < 1000; cycles++) @(posedge clk);
        if (!valid_out) $fatal(1, "timed out waiting for valid_out");

        // valid_out is combinational from state==S5, while x_out is written
        // on the clock edge leaving S5. Sample after that update completes.
        @(negedge clk);

        print_output();
        check_output();
        $display("rmsnorm_tb passed N_EMBD=%0d", N_EMBD);
        $finish;
    end
endmodule
