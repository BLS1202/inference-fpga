// Simulation-only replacements for the Vivado blk_mem_gen instances used by
// top_inference. Each model has a two-clock registered read response.

module blk_mem_gen_0 (
    input  logic        clka,
    input  logic        ena,
    input  logic [8:0]  addra,
    output logic [15:0] douta,
    input  logic [15:0] dina,
    input  logic        wea
);
    logic [15:0] mem [0:431];
    logic [8:0] addr_d1, addr_d2;
    logic en_d1, en_d2;
    initial $readmemh("microgpt/generated/wte_q12.hex", mem);
    always_ff @(posedge clka) begin
        en_d1 <= ena;
        en_d2 <= en_d1;
        addr_d1 <= addra;
        addr_d2 <= addr_d1;
        if (en_d2 && (addr_d2 < 432)) douta <= mem[addr_d2];
    end
endmodule

module blk_mem_gen_1 (
    input  logic        clka,
    input  logic        ena,
    input  logic [7:0]  addra,
    output logic [15:0] douta,
    input  logic [15:0] dina,
    input  logic        wea
);
    logic [15:0] mem [0:255];
    logic [7:0] addr_d1, addr_d2;
    logic en_d1, en_d2;
    initial $readmemh("microgpt/generated/wpe_q12.hex", mem);
    always_ff @(posedge clka) begin
        en_d1 <= ena;
        en_d2 <= en_d1;
        addr_d1 <= addra;
        addr_d2 <= addr_d1;
        if (en_d2) douta <= mem[addr_d2];
    end
endmodule

module bram_model_matrix #(
    parameter int ADDR_WIDTH = 8,
    parameter int DEPTH = 256,
    parameter string INIT_FILE = ""
) (
    input  logic                  clka,
    input  logic                  ena,
    input  logic [ADDR_WIDTH-1:0] addra,
    output logic [15:0]           douta,
    input  logic [15:0]           dina,
    input  logic                  wea
);
    logic [15:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] addr_d1, addr_d2;
    logic en_d1, en_d2;

    initial begin
        if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
    end

    always_ff @(posedge clka) begin
        en_d1 <= ena;
        en_d2 <= en_d1;
        addr_d1 <= addra;
        addr_d2 <= addr_d1;
        if (en_d2 && (addr_d2 < DEPTH)) douta <= mem[addr_d2];
    end
endmodule

module blk_mem_gen_q (
    input logic clka, input logic ena, input logic [7:0] addra,
    output logic [15:0] douta, input logic [15:0] dina, input logic wea
);
    bram_model_matrix #(.INIT_FILE("microgpt/generated/layer0_attn_wq_q12.hex"))
        model (.clka, .ena, .addra, .douta, .dina, .wea);
endmodule

module blk_mem_gen_k (
    input logic clka, input logic ena, input logic [7:0] addra,
    output logic [15:0] douta, input logic [15:0] dina, input logic wea
);
    bram_model_matrix #(.INIT_FILE("microgpt/generated/layer0_attn_wk_q12.hex"))
        model (.clka, .ena, .addra, .douta, .dina, .wea);
endmodule

module blk_mem_gen_v (
    input logic clka, input logic ena, input logic [7:0] addra,
    output logic [15:0] douta, input logic [15:0] dina, input logic wea
);
    bram_model_matrix #(.INIT_FILE("microgpt/generated/layer0_attn_wv_q12.hex"))
        model (.clka, .ena, .addra, .douta, .dina, .wea);
endmodule

module blk_mem_gen_wo (
    input logic clka, input logic ena, input logic [7:0] addra,
    output logic [15:0] douta, input logic [15:0] dina, input logic wea
);
    bram_model_matrix #(.INIT_FILE("microgpt/generated/layer0_attn_wo_q12.hex"))
        model (.clka, .ena, .addra, .douta, .dina, .wea);
endmodule

module blk_mem_gen_fc1 (
    input logic clka, input logic ena, input logic [9:0] addra,
    output logic [15:0] douta, input logic [15:0] dina, input logic wea
);
    bram_model_matrix #(.ADDR_WIDTH(10), .DEPTH(1024),
                        .INIT_FILE("microgpt/generated/layer0_mlp_fc1_q12.hex"))
        model (.clka, .ena, .addra, .douta, .dina, .wea);
endmodule

module blk_mem_gen_fc2 (
    input logic clka, input logic ena, input logic [9:0] addra,
    output logic [15:0] douta, input logic [15:0] dina, input logic wea
);
    bram_model_matrix #(.ADDR_WIDTH(10), .DEPTH(1024),
                        .INIT_FILE("microgpt/generated/layer0_mlp_fc2_q12.hex"))
        model (.clka, .ena, .addra, .douta, .dina, .wea);
endmodule

module blk_mem_gen_lm (
    input logic clka, input logic ena, input logic [8:0] addra,
    output logic [15:0] douta, input logic [15:0] dina, input logic wea
);
    bram_model_matrix #(.ADDR_WIDTH(9), .DEPTH(432),
                        .INIT_FILE("microgpt/generated/lm_head_q12.hex"))
        model (.clka, .ena, .addra, .douta, .dina, .wea);
endmodule
