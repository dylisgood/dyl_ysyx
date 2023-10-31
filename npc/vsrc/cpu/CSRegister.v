module ysyx_22050854_CSRegister  (
  input clock,
  input reset,
  input [63:0] wdata1,
  input [63:0] wdata2,
  input [11:0] waddr1,
  input [11:0] waddr2,
  input wen,
  input wen2,
  input ren,
  input [11:0] raddr,
  output [63:0] rdata,
  output reg timer_interrupt
);
  reg [63:0] csrf [31:0]; //define 32 cs register
  wire [4:0]csr_addr1;
  wire [4:0]csr_addr2;
  wire [4:0]csr_raddr;
  import "DPI-C" function void set_csr_ptr(input logic [63:0] a []);
  initial set_csr_ptr(csrf);  // rf为通用寄存器的二维数组变量

  ysyx_22050854_MuxKey #(6,12,5) gen_csraddr1 (csr_addr1,waddr1,{
    12'h300,5'd2,  //mstatus
    12'h305,5'd0,  //mtvec
    12'h341,5'd1,  //mepc
    12'h342,5'd3,  //mcause
    12'h304,5'd4,  //mie
    12'h344,5'd5   //mip
  });

  ysyx_22050854_MuxKey #(6,12,5) gen_csraddr2 (csr_addr2,waddr2,{
    12'h300,5'd2,  //mstatus
    12'h305,5'd0,  //mtvec
    12'h341,5'd1, //mepc
    12'h342,5'd3, //mcause
    12'h304,5'd4,  //mie
    12'h344,5'd5   //mip
  });

  ysyx_22050854_MuxKey #(6,12,5) gen_csr_raddr (csr_raddr,raddr,{
    12'h300,5'd2,  //mstatus
    12'h305,5'd0,  //mtvec
    12'h341,5'd1, //mepc
    12'h342,5'd3, //mcause
    12'h304,5'd4,  //mie
    12'h344,5'd5   //mip
  });

  assign rdata = ren ? csrf[csr_raddr] : 64'd0;  //read csr

  always @(posedge clock) begin        //write csrs
    if(wen)
      csrf[csr_addr1] <= wdata1;
    if(wen2)
      csrf[csr_addr2] <= wdata2;
  end

  reg [63:0]mtime;
  reg [63:0]mtimecmp;
  //计时器逻辑，每个周期自增
  always @(posedge clock) begin
    if(reset)
      mtime <= 64'd0;
    else
      mtime <= mtime + 1'd1;
  end
  //中断逻辑 根据条件判断是否产生计时器中断
  always @(posedge clock) begin
    if(reset)begin
      csrf[5] <= 64'd0;
      timer_interrupt <= 1'd0;
      csrf[2][3] <= 1'd1; //mstatus 的 MIE位
      csrf[4][7] <= 1'd1; //mie 的 MTIE 位
    end
    else begin
      csrf[5][7] <= ( (csrf[2][3] & csrf[4][7]) & (mtime >= mtimecmp) );
      timer_interrupt <= csrf[5][7];
    end
  end
  //
  always @(posedge clock) begin
    if(reset)
      mtimecmp  <= 64'd100;
    else if(mtime >= mtimecmp)
      mtimecmp <= mtimecmp + 64'd100;
  end


endmodule

