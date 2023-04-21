`timescale 1ns/1ps
module top(
    input clk,
    input rst,
    //input [31:0]inst,
    output [31:0]next_pc,
    output [63:0]alu_src1,
    output [63:0]alu_src2,
    output [63:0]x10,
    output ebreak
);
    ysyx_22050854_cpu inst_cpu(
        .clk(clk),
        .rst(rst),
        //.inst(inst),
        .next_pc(next_pc),
        .ebreak(ebreak),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .x10(x10)
    );

endmodule
