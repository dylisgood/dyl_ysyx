`timescale 1ns/1ps
/*
  这个模块实际上为模拟 接收到AXI信号后 SDRAM 的操作而设计
  接口信号为ysyxSoc的接口信号 就是一个不完整的AXI4 协议
  由于为仿真设计，所以其不具备通用性
  其功能为读/写 一个cache块的内容 
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
    output reg [63:0]rdata,
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
always @(posedge clock)begin
    if(!rst_n)begin
        arready <= 1'b1;
        get_addr <= 1'b0;
        first_addr <= 64'b0;
        first_arid <= 4'b0;
    end
    else if( arvalid && arready )begin
        first_addr <= {32'b0, araddr[31:4] , 4'b0 };
        first_arid <= arid;
        get_addr <= 1'b1;
    end
end

reg [63:0]Next_addr;
reg [3:0]Next_arid;
always @(posedge clock)begin
    if(!rst_n)begin
        rresp <= 2'b00;
        rvalid <= 1'b1;
        first_over <= 1'b0;
        rlast <= 1'b0;
        Next_arid <= 4'b0;
        Next_addr <= 64'b0;
        rid <= 4'b0;
    end
    else if(rvalid && rready && first_over)begin
        v_pmem_read(Next_addr ,rdata);
        rresp <= 2'b10;
        rlast <= 1'b1;
        rid <= Next_arid;

        first_over <= 1'b0;
    end
    else if( rvalid && rready && get_addr )begin
        v_pmem_read(first_addr,rdata);
        rresp <= 2'b10;
        rid <= first_arid;
        rlast <= 1'b0;

        first_over <= 1'b1;
        Next_addr <= { first_addr[63:4] , 1'b1, 3'b0 };
        Next_arid <= first_arid;
        
        if( ~arvalid ) get_addr <= 1'b0;
    end
    else begin
        rresp <= 2'b00;
        first_over <= 1'b0;
        rlast <= 1'b0;
        rid <= 4'b0;
    end
end

//write   
reg [63:0]dsram_write_addr;
reg [7:0]dsram_wtsb;
wire [63:0]wmask;
//assign wmask = { {8{dsram_wtsb[7]}}, {8{dsram_wtsb[6]}}, {8{dsram_wtsb[5]}}, {8{dsram_wtsb[4]}}, {8{dsram_wtsb[3]}}, {8{dsram_wtsb[2]}}, {8{dsram_wtsb[1]}}, {8{dsram_wtsb[0]}} };
assign wmask = 64'hffffffffffffffff;
always @(posedge clock)begin
    if(!rst_n) begin
        awready <= 1'd1;
    end
    else if(awvalid && awready) begin
        dsram_write_addr <= { 32'd0, awaddr};
    end
end

always @(posedge clock)begin
    if(!rst_n)begin
        wready <= 1'd1;
        bresp <= 2'b00;
    end
    else if( wvalid && wready )begin
        if(wlast) begin
            v_pmem_write( { dsram_write_addr[63:4],4'b1000},wdata,wmask);
            bresp <= 2'b01;
        end
        else begin
            v_pmem_write(dsram_write_addr,wdata,wmask);
        end
    end
    else begin
        bresp <= 2'b00;
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

endmodule