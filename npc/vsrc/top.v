`timescale 1ns/1ps
module top(
    input clk,
    input rst,
    input [31:0]inst,
    output [31:0]pc,
    output [63:0]x6,
    //output [63:0]x5,
    output ebreak
);
    ysyx_22050854_cpu inst_cpu(
        .clk(clk),
        .rst(rst),
        .inst(inst),
        .pc(pc),
        .ebreak(ebreak)
    );

/*     ysyx_22050854_RegisterFile read_x6(
        .clk(clk),
        .wdata(),
        .waddr(),
        .wen(1'b0),        
        .raddra(5'b00110),
        .raddrb(5'b00101),
        .rdata1(x6),
        .rdata2(x5)      
    ); */
   register i_re2 (
  .clk(clk),
  .wdata(),
  .waddr(),
  .wen(1'd0),
  .ren(1'd1),
  .raddra(5'd6),
  .rdata(x6)
);

endmodule
