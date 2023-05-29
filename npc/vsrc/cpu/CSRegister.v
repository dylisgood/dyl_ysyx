module ysyx_22050854_CSregister  (
  input clk,
  input [63:0] wdata,
  input [11:0] waddr,
  input wen,
  input ren,
  input [4:0] raddra,
  output [63:0] rdata
);
  reg [63:0] csrf [3:0];
  reg [4:0]csr_num;

  ysyx_22050854_MuxKey #(4,12,5) gen_csraddr (csr_num,waddr,{
    12'h0,5'd2,  //mstatus
    12'h5,5'd0,  //mtvec
    12'h41,5'd1, //mepc
    12'h42,5'd3  //mcause
  });

  always @(posedge clk) begin
    if(wen) csrf[waddr] <= wdata;
  end

  assign rdata = ren ? rf[raddra] : 64'd0;
endmodule
