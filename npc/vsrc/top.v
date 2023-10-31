`timescale 1ns/1ps
module top(
    input clock,
    input reset,
    input cpu_io_interrupt
);

wire  cpu_io_master_awready; // @[CPU.scala 51:21]
wire  cpu_io_master_awvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_master_awid; // @[CPU.scala 51:21]
wire [31:0] cpu_io_master_awaddr; // @[CPU.scala 51:21]
wire [7:0] cpu_io_master_awlen; // @[CPU.scala 51:21]
wire [2:0] cpu_io_master_awsize; // @[CPU.scala 51:21]
wire [1:0] cpu_io_master_awburst; // @[CPU.scala 51:21]

wire  cpu_io_master_wready; // @[CPU.scala 51:21]
wire  cpu_io_master_wvalid; // @[CPU.scala 51:21]
wire [63:0] cpu_io_master_wdata; // @[CPU.scala 51:21]
wire [7:0] cpu_io_master_wstrb; // @[CPU.scala 51:21]
wire  cpu_io_master_wlast; // @[CPU.scala 51:21]

wire  cpu_io_master_bready; // @[CPU.scala 51:21]
wire  cpu_io_master_bvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_master_bid; // @[CPU.scala 51:21]
wire [1:0] cpu_io_master_bresp; // @[CPU.scala 51:21]

wire  cpu_io_master_arready; // @[CPU.scala 51:21]
wire  cpu_io_master_arvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_master_arid; // @[CPU.scala 51:21]
wire [31:0] cpu_io_master_araddr; // @[CPU.scala 51:21]
wire [7:0] cpu_io_master_arlen; // @[CPU.scala 51:21]
wire [2:0] cpu_io_master_arsize; // @[CPU.scala 51:21]
wire [1:0] cpu_io_master_arburst; // @[CPU.scala 51:21]

wire  cpu_io_master_rready; // @[CPU.scala 51:21]
wire  cpu_io_master_rvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_master_rid; // @[CPU.scala 51:21]
wire [63:0] cpu_io_master_rdata; // @[CPU.scala 51:21]
wire [1:0] cpu_io_master_rresp; // @[CPU.scala 51:21]
wire  cpu_io_master_rlast; // @[CPU.scala 51:21]

wire  cpu_io_slave_awready; // @[CPU.scala 51:21]
wire  cpu_io_slave_awvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_slave_awid; // @[CPU.scala 51:21]
wire [31:0] cpu_io_slave_awaddr; // @[CPU.scala 51:21]
wire [7:0] cpu_io_slave_awlen; // @[CPU.scala 51:21]
wire [2:0] cpu_io_slave_awsize; // @[CPU.scala 51:21]
wire [1:0] cpu_io_slave_awburst; // @[CPU.scala 51:21]

wire  cpu_io_slave_wready; // @[CPU.scala 51:21]
wire  cpu_io_slave_wvalid; // @[CPU.scala 51:21]
wire [63:0] cpu_io_slave_wdata; // @[CPU.scala 51:21]
wire [7:0] cpu_io_slave_wstrb; // @[CPU.scala 51:21]
wire  cpu_io_slave_wlast; // @[CPU.scala 51:21]

wire  cpu_io_slave_bready; // @[CPU.scala 51:21]
wire  cpu_io_slave_bvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_slave_bid; // @[CPU.scala 51:21]
wire [1:0] cpu_io_slave_bresp; // @[CPU.scala 51:21]

wire  cpu_io_slave_arready; // @[CPU.scala 51:21]
wire  cpu_io_slave_arvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_slave_arid; // @[CPU.scala 51:21]
wire [31:0] cpu_io_slave_araddr; // @[CPU.scala 51:21]
wire [7:0] cpu_io_slave_arlen; // @[CPU.scala 51:21]
wire [2:0] cpu_io_slave_arsize; // @[CPU.scala 51:21]
wire [1:0] cpu_io_slave_arburst; // @[CPU.scala 51:21]

wire  cpu_io_slave_rready; // @[CPU.scala 51:21]
wire  cpu_io_slave_rvalid; // @[CPU.scala 51:21]
wire [3:0] cpu_io_slave_rid; // @[CPU.scala 51:21]
wire [63:0] cpu_io_slave_rdata; // @[CPU.scala 51:21]
wire [1:0] cpu_io_slave_rresp; // @[CPU.scala 51:21]
wire  cpu_io_slave_rlast; // @[CPU.scala 51:21]

wire [5:0] cpu_io_sram0_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram0_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram0_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram0_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram0_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram0_rdata; // @[CPU.scala 51:21]
wire [5:0] cpu_io_sram1_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram1_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram1_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram1_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram1_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram1_rdata; // @[CPU.scala 51:21]
wire [5:0] cpu_io_sram2_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram2_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram2_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram2_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram2_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram2_rdata; // @[CPU.scala 51:21]
wire [5:0] cpu_io_sram3_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram3_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram3_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram3_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram3_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram3_rdata; // @[CPU.scala 51:21]
wire [5:0] cpu_io_sram4_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram4_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram4_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram4_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram4_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram4_rdata; // @[CPU.scala 51:21]
wire [5:0] cpu_io_sram5_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram5_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram5_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram5_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram5_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram5_rdata; // @[CPU.scala 51:21]
wire [5:0] cpu_io_sram6_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram6_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram6_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram6_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram6_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram6_rdata; // @[CPU.scala 51:21]
wire [5:0] cpu_io_sram7_addr; // @[CPU.scala 51:21]
wire  cpu_io_sram7_cen; // @[CPU.scala 51:21]
wire  cpu_io_sram7_wen; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram7_wmask; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram7_wdata; // @[CPU.scala 51:21]
wire [127:0] cpu_io_sram7_rdata; // @[CPU.scala 51:21]


ysyx_22050854 inst_cpu(
    .clock(clock),
    .reset(reset),
    .io_interrupt(cpu_io_interrupt),

    .io_master_awready(cpu_io_master_awready),
    .io_master_awvalid(cpu_io_master_awvalid), 
    .io_master_awid(cpu_io_master_awid), 
    .io_master_awaddr(cpu_io_master_awaddr), 
    .io_master_awlen(cpu_io_master_awlen),
    .io_master_awsize(cpu_io_master_awsize),
    .io_master_awburst(cpu_io_master_awburst),

    .io_master_wready(cpu_io_master_wready),
    .io_master_wvalid(cpu_io_master_wvalid),
    .io_master_wdata(cpu_io_master_wdata),
    .io_master_wstrb(cpu_io_master_wstrb),
    .io_master_wlast(cpu_io_master_wlast),

    .io_master_bready(cpu_io_master_bready),
    .io_master_bvalid(cpu_io_master_bvalid),
    .io_master_bid(cpu_io_master_bid),
    .io_master_bresp(cpu_io_master_bresp),

    .io_master_arready(cpu_io_master_arready),
    .io_master_arvalid(cpu_io_master_arvalid),
    .io_master_arid(cpu_io_master_arid),
    .io_master_araddr(cpu_io_master_araddr),
    .io_master_arlen(cpu_io_master_arlen),
    .io_master_arsize(cpu_io_master_arsize),
    .io_master_arburst(cpu_io_master_arburst),

    .io_master_rready(cpu_io_master_rready),
    .io_master_rvalid(cpu_io_master_rvalid),
    .io_master_rid(cpu_io_master_rid),
    .io_master_rdata(cpu_io_master_rdata),
    .io_master_rresp(cpu_io_master_rresp),
    .io_master_rlast(cpu_io_master_rlast),

    .io_slave_awready(cpu_io_slave_awready),
    .io_slave_awvalid(cpu_io_slave_awvalid),
    .io_slave_awid(cpu_io_slave_awid),
    .io_slave_awaddr(cpu_io_slave_awaddr),
    .io_slave_awlen(cpu_io_slave_awlen),
    .io_slave_awsize(cpu_io_slave_awsize),
    .io_slave_awburst(cpu_io_slave_awburst),
    .io_slave_wready(cpu_io_slave_wready),
    .io_slave_wvalid(cpu_io_slave_wvalid),
    .io_slave_wdata(cpu_io_slave_wdata),
    .io_slave_wstrb(cpu_io_slave_wstrb),
    .io_slave_wlast(cpu_io_slave_wlast),
    .io_slave_bready(cpu_io_slave_bready),
    .io_slave_bvalid(cpu_io_slave_bvalid),
    .io_slave_bid(cpu_io_slave_bid),
    .io_slave_bresp(cpu_io_slave_bresp),
    .io_slave_arready(cpu_io_slave_arready),
    .io_slave_arvalid(cpu_io_slave_arvalid),
    .io_slave_arid(cpu_io_slave_arid),
    .io_slave_araddr(cpu_io_slave_araddr),
    .io_slave_arlen(cpu_io_slave_arlen),
    .io_slave_arsize(cpu_io_slave_arsize),
    .io_slave_arburst(cpu_io_slave_arburst),
    .io_slave_rready(cpu_io_slave_rready),
    .io_slave_rvalid(cpu_io_slave_rvalid),
    .io_slave_rid(cpu_io_slave_rid),
    .io_slave_rdata(cpu_io_slave_rdata),
    .io_slave_rresp(cpu_io_slave_rresp),
    .io_slave_rlast(cpu_io_slave_rlast),

    .io_sram0_addr(cpu_io_sram0_addr),
    .io_sram0_cen(cpu_io_sram0_cen),
    .io_sram0_wen(cpu_io_sram0_wen),
    .io_sram0_wmask(cpu_io_sram0_wmask),
    .io_sram0_wdata(cpu_io_sram0_wdata),
    .io_sram0_rdata(cpu_io_sram0_rdata),
    .io_sram1_addr(cpu_io_sram1_addr),
    .io_sram1_cen(cpu_io_sram1_cen),
    .io_sram1_wen(cpu_io_sram1_wen),
    .io_sram1_wmask(cpu_io_sram1_wmask),
    .io_sram1_wdata(cpu_io_sram1_wdata),
    .io_sram1_rdata(cpu_io_sram1_rdata),
    .io_sram2_addr(cpu_io_sram2_addr),
    .io_sram2_cen(cpu_io_sram2_cen),
    .io_sram2_wen(cpu_io_sram2_wen),
    .io_sram2_wmask(cpu_io_sram2_wmask),
    .io_sram2_wdata(cpu_io_sram2_wdata),
    .io_sram2_rdata(cpu_io_sram2_rdata),
    .io_sram3_addr(cpu_io_sram3_addr),
    .io_sram3_cen(cpu_io_sram3_cen),
    .io_sram3_wen(cpu_io_sram3_wen),
    .io_sram3_wmask(cpu_io_sram3_wmask),
    .io_sram3_wdata(cpu_io_sram3_wdata),
    .io_sram3_rdata(cpu_io_sram3_rdata),
    .io_sram4_addr(cpu_io_sram4_addr),
    .io_sram4_cen(cpu_io_sram4_cen),
    .io_sram4_wen(cpu_io_sram4_wen),
    .io_sram4_wmask(cpu_io_sram4_wmask),
    .io_sram4_wdata(cpu_io_sram4_wdata),
    .io_sram4_rdata(cpu_io_sram4_rdata),
    .io_sram5_addr(cpu_io_sram5_addr),
    .io_sram5_cen(cpu_io_sram5_cen),
    .io_sram5_wen(cpu_io_sram5_wen),
    .io_sram5_wmask(cpu_io_sram5_wmask),
    .io_sram5_wdata(cpu_io_sram5_wdata),
    .io_sram5_rdata(cpu_io_sram5_rdata),
    .io_sram6_addr(cpu_io_sram6_addr),
    .io_sram6_cen(cpu_io_sram6_cen),
    .io_sram6_wen(cpu_io_sram6_wen),
    .io_sram6_wmask(cpu_io_sram6_wmask),
    .io_sram6_wdata(cpu_io_sram6_wdata),
    .io_sram6_rdata(cpu_io_sram6_rdata),
    .io_sram7_addr(cpu_io_sram7_addr),
    .io_sram7_cen(cpu_io_sram7_cen),
    .io_sram7_wen(cpu_io_sram7_wen),
    .io_sram7_wmask(cpu_io_sram7_wmask),
    .io_sram7_wdata(cpu_io_sram7_wdata),
    .io_sram7_rdata(cpu_io_sram7_rdata)
);

wire rst_n;
assign rst_n = ~reset;

ysyx_22050854_AXI_SRAM_LSU Cache_AXI_DDR (
    .clock(clock),
    .rst_n(rst_n),

    //read address channel
    .araddr(cpu_io_master_araddr),
    .arvalid(cpu_io_master_arvalid),
    .arready(cpu_io_master_arready), 
    .arlen(cpu_io_master_arlen),
    .arsize(cpu_io_master_arsize),
    .arburst(cpu_io_master_arburst),
    .arid(cpu_io_master_arid),

    //read data channel
    .rrr_data(cpu_io_master_rdata),
    .rresp(cpu_io_master_rresp),
    .rvalid(cpu_io_master_rvalid),
    .rready(cpu_io_master_rready),
    .rid(cpu_io_master_rid),
    .rlast(cpu_io_master_rlast),

    //write address channel
    .awaddr(cpu_io_master_awaddr),
    .awvalid(cpu_io_master_awvalid),
    .awready(cpu_io_master_awready),
    .awid(cpu_io_master_awid),
    .awlen(cpu_io_master_awlen),
    .awsize(cpu_io_master_awsize),
    .awburst(cpu_io_master_awburst),

    //write data channel
    .wdata(cpu_io_master_wdata),
    .wvalid(cpu_io_master_wvalid),
    .wready(cpu_io_master_wready),
    .wstrb(cpu_io_master_wstrb),
    .wlast(cpu_io_master_wlast),

    //write response channel
    .bresp(cpu_io_master_bresp),
    .bvalid(cpu_io_master_bvalid),
    .bready(cpu_io_master_bready),
    .bid(cpu_io_master_bid)
);

//一个ram的大小是64 * 16B = 1kB
ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst0(
    .Q(cpu_io_sram0_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram0_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram0_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram0_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram0_addr),           //读写地址
    .D(cpu_io_sram0_wdata)            //写数据
);

ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst1(
    .Q(cpu_io_sram1_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram1_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram1_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram1_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram1_addr),           //读写地址
    .D(cpu_io_sram1_wdata)            //写数据
);

ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst2(
    .Q(cpu_io_sram2_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram2_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram2_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram2_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram2_addr),           //读写地址
    .D(cpu_io_sram2_wdata)            //写数据
);

ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst3(
    .Q(cpu_io_sram3_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram3_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram3_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram3_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram3_addr),           //读写地址
    .D(cpu_io_sram3_wdata)            //写数据
);

ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst4(
    .Q(cpu_io_sram4_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram4_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram4_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram4_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram4_addr),           //读写地址
    .D(cpu_io_sram4_wdata)            //写数据
);

ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst5(
    .Q(cpu_io_sram5_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram5_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram5_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram5_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram5_addr),           //读写地址
    .D(cpu_io_sram5_wdata)            //写数据
);

ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst6(
    .Q(cpu_io_sram6_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram6_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram6_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram6_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram6_addr),           //读写地址
    .D(cpu_io_sram6_wdata)            //写数据
);

ysyx_22050854_S011HD1P_X32Y2D128_BW ram_inst7(
    .Q(cpu_io_sram7_rdata),  //读到的数据
    .CLK(clock),      //时钟
    .CEN(cpu_io_sram7_cen),         //使能信号，低电平有效
    .WEN(cpu_io_sram7_wen),         //写使能信号，低电平有效
    .BWEN(cpu_io_sram7_wmask),        //写掩码信号，掩码粒度为1bit,低电平有效
    .A(cpu_io_sram7_addr),           //读写地址
    .D(cpu_io_sram7_wdata)            //写数据
);

endmodule
