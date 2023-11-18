/*
  这个模块实际上为模拟 接收到AXI信号后 SDRAM 的操作而设计
  接口信号为ysyxSoc的接口信号 就是一个不完整的AXI4 协议
  由于为仿真设计，所以其不具备通用性
  其功能为读/写 一个cache块的内容\
  其需要具备
    1.长度分别位1 2的传输 64Bytes 128Bytes
    2.能够支持连续传输，每次返回的rid,bid都是arid,awid传来的id
*/

module ysyx_22050854_AXI_SRAM_LSU (
    input clock,
    input rst_n,

    //read address channel
    input arvalid,
    output reg arready, 
    input [31:0]araddr,
    input [3:0]arid,
    input [7:0]arlen,
    input [2:0]arsize,
    input [1:0]arburst,

    //read data channel
    output reg[63:0]rrr_data,
    output reg [1:0]rresp,
    output reg rvalid,
    input rready,
    output reg [3:0]rid,
    output reg rlast,

    //write address channel
    input [31:0]awaddr,
    input awvalid,
    output reg awready,
    input [3:0]awid,
    input [7:0]awlen,
    input [2:0]awsize,
    input [1:0]awburst,

    //write data channel
    input [63:0]wdata,
    input wvalid,
    output reg wready,
    input [7:0]wstrb,
    input wlast,

    //write response channel
    output reg [1:0]bresp,
    output reg bvalid,
    input bready,
    output [3:0]bid
);

import "DPI-C" function void v_pmem_read(
input longint raddr, output longint rdata);

import "DPI-C" function void v_pmem_write(
input longint waddr, input longint wdata, input longint wmask);


reg first_over;
reg get_addr;
reg [63:0]first_addr;
reg [3:0]first_arid;
reg [1:0]reg_arburst;
reg [63:0]Device_addr;
always @(posedge clock)begin
    if(!rst_n)begin
        arready <= 1'b1;
        get_addr <= 1'b0;
        first_addr <= 64'b0;
        first_arid <= 4'b0;
        reg_arburst <= 2'b0;
        Device_addr <= 64'd0;
    end
    else if( arvalid && arready )begin
        first_addr <= {32'b0, araddr[31:4] , 4'b0 };
        first_arid <= arid;
        get_addr <= 1'b1;
        reg_arburst <= arburst;
        Device_addr <=  ( arburst == 2'b00 ) ? { 32'b0,araddr } : 64'b0;
    end
end

reg [63:0]Next_addr;
reg [3:0]Next_arid;
//reg [63:0]rrr_data;
always @(posedge clock)begin
    if(!rst_n)begin
        rresp <= 2'b00;
        rvalid <= 1'b0;
        first_over <= 1'b0;
        rlast <= 1'b0;
        Next_arid <= 4'b0;
        Next_addr <= 64'b0;
        rid <= 4'b0;
    end
    else if(rready && first_over)begin
        rrr_data <= readdata;
        //v_pmem_read( Next_addr,readdata);
        rresp <= 2'b10;
        rlast <= 1'b1;
        rid <= Next_arid;
        rvalid <= 1'b1;

        first_over <= 1'b0;
    end
    else if( rready && get_addr )begin
        //v_pmem_read(first_addr,readdata);
        rrr_data <= readdata;
        rresp <= ( reg_arburst == 2'b01 ) ? 2'b10 : 2'b00;
        rid <= first_arid;
        rlast <= 1'b0;
        rvalid <= ( reg_arburst == 2'b01 ) ? 1'b1 : 1'b0;;

        first_over <= 1'b1;       
        Next_addr <= ( reg_arburst == 2'b01 ) ? { first_addr[63:4] , 1'b1, 3'b0 } : Device_addr;
        Next_arid <= first_arid;
    
        if( ~arvalid ) get_addr <= 1'b0;
    end
    else begin
        rresp <= 2'b00;
        first_over <= 1'b0;
        rlast <= 1'b0;
        rid <= 4'b0;
        rvalid <= 1'b0;
    end
end

reg [63:0]readdata;
always @(*)begin
    if( rready && first_over )  //must at first than get_addr,because maybe first IFU then LSU
        v_pmem_read( Next_addr, readdata);
    else if( rready && get_addr && ( reg_arburst == 2'b01 ) )
        v_pmem_read( first_addr, readdata);
    else 
        readdata = 64'b0;
end

//write 
//first cycle get awaddr awid, second cycle get wdata   
reg [63:0]dsram_write_addr;
reg [7:0]dsram_wtsb;
wire [63:0]wmask;
reg [1:0]reg_awburst;
reg [3:0]reg_awid;
//assign wmask = { {8{dsram_wtsb[7]}}, {8{dsram_wtsb[6]}}, {8{dsram_wtsb[5]}}, {8{dsram_wtsb[4]}}, {8{dsram_wtsb[3]}}, {8{dsram_wtsb[2]}}, {8{dsram_wtsb[1]}}, {8{dsram_wtsb[0]}} };
assign wmask = 64'hffffffffffffffff;
always @(posedge clock)begin
    if(!rst_n) begin
        awready <= 1'd1;
        reg_awburst <= 2'b00;
    end
    else if(awvalid && awready) begin
        dsram_write_addr <= { 32'd0, awaddr};
        reg_awburst <= awburst;
        reg_awid <= awid;
    end
end

//
always @(posedge clock)begin
    if(!rst_n)begin
        wready <= 1'd1;
        bresp <= 2'b00;
        bvalid <= 1'b0;
    end
    else if( wvalid && wready )begin
        if( wlast && ( reg_awburst == 2'b01 )) begin  //The Dcache's second data
            v_pmem_write( { dsram_write_addr[63:4],4'b1000},wdata,wmask );
            bvalid <= 1'b1;
            bresp <= 2'b01;
            bid <= reg_awid;
        end
        else if( reg_awburst == 2'b01 ) begin  //The Dcache's first data
            v_pmem_write(dsram_write_addr,wdata,wmask);
            bvalid <= 1'b0;
            bid <= reg_awid;
        end
        else if( reg_awburst == 2'b00 )begin  //Write device data
            v_pmem_write(dsram_write_addr,wdata,wmask);
            bvalid <= 1'b1;
            bresp <= 2'b01;
            bid <= reg_awid;
        end
    end
    else begin
        bresp <= 2'b00;
        bvalid <= 1'b0;
        bid <= 4'b0;
    end
end

wire [31:0]awvalid_32;
assign awvalid_32 = { 31'b0, awvalid };
import "DPI-C" function void get_awvalid_32_value(int awvalid_32);
always@(*) get_awvalid_32_value(awvalid_32);

wire [31:0]dsram_write_addr_32;
assign dsram_write_addr_32 = dsram_write_addr[31:0];
import "DPI-C" function void get_dsram_write_addr_value(int dsram_write_addr_32);
always@(*) get_dsram_write_addr_value(dsram_write_addr_32);

wire [31:0]dsram_wdata_32;
assign dsram_wdata_32 = wdata[31:0];
import "DPI-C" function void get_dsram_wdata_32_value(int dsram_wdata_32);
always@(*) get_dsram_wdata_32_value(dsram_wdata_32);

wire [31:0]arvalid_32;
assign arvalid_32 = { 20'b0, 2'b0,rresp,2'b0,reg_arburst,3'b0,arvalid};
import "DPI-C" function void get_arvalid_32_value(int arvalid_32);
always@(*) get_arvalid_32_value(arvalid_32);

wire [31:0]first_addr_32;
assign first_addr_32 = first_addr[31:0];
import "DPI-C" function void get_first_addr_32_value(int first_addr_32);
always@(*) get_first_addr_32_value(first_addr_32);

endmodule