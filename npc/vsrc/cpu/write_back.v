//`timescale 1ns/1ps
module ysyx_22050854_write_back(
    input clk,
    input MemtoReg,
    input RegWr,
    input [63:0]alu_out,
    input [63:0]mem_data,
    input [4:0]rd
);
    wire [63:0]wb_data;
    ysyx_22050854_MuxKey #(2,1,64) sel_wbsrc (wb_data, MemtoReg, {
        1'b0,alu_out,
        1'b1,mem_data
    });

/*     ysyx_22050854_RegisterFile inst_wb(
    .clk(clk),
    .wdata(wb_data),
    .waddr(rd),
    .wen(RegWr),
    .raddra(),
    .raddrb(),
    .rdata1(),
    .rdata2()     
    ); */

endmodule

