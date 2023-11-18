module ysyx_22050854_RegisterFile  (
  input clock,
  input [63:0] wdata,
  input reg[4:0] waddr,
  input wen,
  input [4:0] raddra,
  input [4:0] raddrb,
  output reg[63:0] rdata1,
  output reg[63:0] rdata2
);
  reg [63:0] rf [31:0];
  always @(posedge clock) begin
    if(waddr==5'd0)
      rf[waddr] <= 64'd0;
    else begin
      if(wen) begin
        rf[waddr] <= wdata;
      end
    end
  end

  import "DPI-C" function void set_gpr_ptr(input logic [63:0] a []);
  initial set_gpr_ptr(rf);  // rf为通用寄存器的二维数组变量
  
  always @(*) begin
    rf[5'b0] = 64'b0;
  end

  always@(*)begin
    if(raddra == 5'd0)
      rdata1 = 64'd0;
    else
      rdata1 = rf[raddra];
  end

  always@(*)begin
    if(raddrb == 5'd0)
      rdata2 = 64'd0;
    else
      rdata2 = rf[raddrb];
  end

  wire [63:0]x10;
  assign x10 = rf[10];
  wire [31:0]x10_32;
  assign x10_32 = x10[31:0];
  import "DPI-C" function void get_x10_value(int x10_32);
  always@(*) get_x10_value(x10_32);

endmodule


