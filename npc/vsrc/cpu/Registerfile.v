//`timescale 1ns/1ps
module ysyx_22050854_RegisterFile  (
  input clk,
  input [63:0] wdata,
  input [4:0] waddr,
  input wen,
  input [4:0] raddra,
  input [4:0] raddrb,
  output reg[63:0] rdata1,
  output reg[63:0] rdata2,

  input [4:0]test_addr1,
  input [4:0]test_addr2,
  output reg[63:0]test_rdata1,
  output reg[63:0]test_rdata2
);
  reg [63:0] rf [31:0];
  always @(posedge clk) begin
    if(wen) rf[waddr] <= wdata;
  end

/*   always @(*) begin
      rf[5'b0] = 64'b0;
  end */

  always@(*)begin
    if(raddra==5'd0)
      rdata1 = 64'd0;
    else
      rdata1 = rf[raddra];
  end

  always@(*)begin
    if(raddrb==5'd0)
      rdata2 = 64'd0;
    else
      rdata2 = rf[raddrb];
  end

  always@(*)begin
    if(test_addr1==5'd0)
      test_rdata1 = 64'd0;
    else
      test_rdata1 = rf[test_addr1];
  end

  always@(*)begin
    if(test_addr2==5'd0)
      test_rdata2 = 64'd0;
    else
      test_rdata2 = rf[test_addr2];
  end

endmodule
