`timescale 1ns/1ps
module top(
    input clk,
    input rst,
    //input suspend,
    output timer_interrupt,
    output [63:0]x10,
    output ebreak
);
    ysyx_22050854_cpu inst_cpu(
        .clk(clk),
        .rst(rst),
        //.suspend(suspend),
        .timer_interrupt(timer_interrupt),
        .ebreak(ebreak),
        .x10(x10)
    );

endmodule
