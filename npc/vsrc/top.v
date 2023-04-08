`timescale 1ns/1ps
module top(
    input clk,
    input rst,
    input [31:0]inst,
    output [31:0]pc,
    output [63:0]x10,
    output [63:0]x5,
    output ebreak
);
    ysyx_22050854_cpu inst_cpu(
        .clk(clk),
        .rst(rst),
        .inst(inst),
        .pc(pc),
        .ebreak(ebreak),
        .x5(x5),
        .x10(x10)
    );

endmodule
