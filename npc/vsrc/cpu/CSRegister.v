//CSR register files
//suport write two registers at the same time
module ysyx_22050854_CSRegister  (
  input clock,
  input reset,
  input [63:0] wdata1,
  input [63:0] wdata2,
  input [11:0] waddr1,
  input [11:0] waddr2,
  input mret,
  input ecall,
  input wen,
  input wen2,
  input ren,
  input [11:0] raddr,
  input mtime_bigger_mtimecmp,
  output [63:0] rdata,
  output timer_interrupt,
  input handle_timer_intr
);
  reg [63:0] csrf [9:0]; //define 10 control status register
  wire [3:0]csr_addr1;
  wire [3:0]csr_addr2;
  wire [3:0]csr_raddr;

  ysyx_22050854_MuxKeyWithDefault #(8,12,4) gen_csraddr1 (csr_addr1,waddr1,4'd10,{
    12'h305,4'd0,  //mtvec
    12'h341,4'd1,  //mepc
    12'h300,4'd2,  //mstatus
    12'h342,4'd3,  //mcause
    12'h304,4'd4,  //mie
    12'h344,4'd5,  //mip
    12'hf14,4'd6,  //mhartid
    12'h340,4'd7  //mscratch
  });

  ysyx_22050854_MuxKeyWithDefault #(8,12,4) gen_csraddr2 (csr_addr2,waddr2,4'd10,{
    12'h305,4'd0,  //mtvec
    12'h341,4'd1,  //mepc
    12'h300,4'd2,  //mstatus
    12'h342,4'd3,  //mcause
    12'h304,4'd4,  //mie
    12'h344,4'd5,  //mip
    12'hf14,4'd6,  //mhartid
    12'h340,4'd7   //mscratch
  });

  ysyx_22050854_MuxKeyWithDefault #(8,12,4) gen_csr_raddr (csr_raddr,raddr,4'd10,{
    12'h305,4'd0,  //mtvec
    12'h341,4'd1,  //mepc
    12'h300,4'd2,  //mstatus
    12'h342,4'd3,  //mcause
    12'h304,4'd4,  //mie
    12'h344,4'd5,  //mip
    12'hf14,4'd6,  //mhartid read only
    12'h340,4'd7  //mscratch
  });

  assign rdata = ren ? csrf[csr_raddr] : 64'd0;  //read csr

  always @(posedge clock) begin        //write csr1
    if(reset)
        csrf[6] <= 64'b0;  //mhartid
    else if( wen && ( csr_addr1 == 4'd6) )
        csrf[6] <= 64'b0;           //mhartid read only
    else if( wen && ( csr_addr1 != 4'd6) )
        csrf[csr_addr1] <= wdata1;
  end

  always @(posedge clock) begin        //write csr2
    if(reset)
        csrf[6] <= 64'b0;  //mhartid
    else if( wen2 && ( csr_addr2 == 4'd6) )
        csrf[6] <= 64'b0;           //mhartid read only
    else if( wen2 && ( csr_addr2 != 4'd6) )
        csrf[csr_addr2] <= wdata2;
  end

  //中断逻辑 根据条件判断是否产生计时器中断
  always @(posedge clock) begin
    if(reset)begin
      csrf[5] <= 64'd0;
    end
    else if( handle_timer_intr ) //if handle, reset
      csrf[5][7] <= 1'b0;
    else if( ( csrf[2][3] & csrf[4][7] ) & mtime_bigger_mtimecmp )begin
      csrf[5][7] <= 1'b1;         //mip->mtip set 1
    end
  end
  assign timer_interrupt = csrf[5][7];

  //mstatus->MIE[3] MPIE[7]
  always @(posedge clock ) begin
    if(reset)
      csrf[2][7] <= 1'b1;
    else if(( csrf[2][3] & csrf[4][7] ) & mtime_bigger_mtimecmp ) begin  //time interrupt
      csrf[2][7] <= csrf[2][3];
      csrf[2][3] <= 1'b0;
    end
    else if( ecall ) begin     //environment call
      csrf[2][7] <= csrf[2][3];
      csrf[2][3] <= 1'b0;
    end
    else if( mret )begin    //return 
      csrf[2][7] <= 1'b1;
      csrf[2][3] <= csrf[2][7];
    end

  end

endmodule

