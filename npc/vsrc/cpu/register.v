module register  (
  input clk,
  input [63:0] wdata,
  input [4:0] waddr,
  input wen,
  input ren,
  input [4:0] raddra,
  output [63:0] rdata
);
  reg [63:0] rf [31:0];
  always @(posedge clk) begin
    if(wen) rf[waddr] <= wdata;
  end

   always @(*) begin
      rf[5'b0] = 64'b0;
  end 
  assign rdata = ren ? rf[raddra] : 64'd0;
endmodule
