`timescale 1ns/1ps
module ysyx_22050854_RegisterFile  (
  input clk,
  input [63:0] wdata,
  input [4:0] waddr,
  input wen,
  input [4:0] raddra,
  input [4:0] raddrb,
  output [63:0] rdata1,
  output [63:0] rdata2
);
  reg [63:0] rf [31:0];
  always @(posedge clk) begin
    if(wen) rf[waddr] <= wdata;
    end

   always @(*) begin
      rf[5'b0] = 64'b0;
      rf[5'd1] = 64'd15;
  end 
  assign rdata1 = rf[raddra];
  assign rdata2 = rf[raddrb];
endmodule
