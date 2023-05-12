/*
`timescale 1ns/1ps
module top_tb();

    reg clk,rst;
    initial begin
        clk = 0;
        forever
         #50 clk = ~clk;
    end

    initial begin
        rst = 0;
        #10 rst = 1;
        #10 rst = 0;
    end

    top inst_top_tb(
    .clk(clk),
    .rst(rst),
    inst(),
    .pc(32'h80000000),
    .x6(),
    .reg_wr()
);

endmodule
*/