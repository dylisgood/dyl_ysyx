`timescale 1ns/1ps
/* read only AXI-lite instruction sram
   功能：
        接收cache的读数据请求，模拟AXI总线，能够满足突发传输，一个事务传输16个字节
        一次传输8个字节，传输两次
        为简单起，直接每次收到地址就将地址16字节对齐为起始地址的数据输出，分两个周期输出
        毕竟CPU通过AXI总线输出到从设备，该部分逻辑由从设备，也就是SRAM完成，我只需要模拟它的实现结果就好
 */
module ysyx_22050854_AXI_ISRAM (
    input clk,
    input rst_n,

    input [31:0]araddr, 
    input arvalid,
    input arlen,
    input arsize,
    input [1:0]arburst,
    output reg arready, //I-SRAM 准备好接收地址了没？

    output reg [63:0]rdata,
    output reg rvalid,
    input rready,
    output reg rlast,
    output reg rresp
);

import "DPI-C" function void v_pmem_read(
input longint raddr, output longint rdata);

wire [31:0]araddr_pc_32;
assign araddr_pc_32 = araddr_pc[31:0];
import "DPI-C" function void get_araddr_pc(int araddr_pc_32);
always@(*) get_araddr_pc(araddr_pc_32);

reg first_over;
reg [63:0]araddr_pc;
reg get_addr1,get_addr2;
reg [31:0]reg_araddr;
always @(posedge clk)begin
    if(!rst_n)begin
        arready <= 1'b1;
        get_addr1 <= 1'b0;
        get_addr2 <= 1'b0;
        reg_araddr <= 32'b0;
        araddr_pc <= 64'b0;
    end
    else if(arvalid && arready )begin
        reg_araddr <= araddr;
        araddr_pc <= { 32'd0, araddr[31:4], 4'b0 };
        get_addr1 <= 1'b1;
    end
    else if(first_over)begin
        araddr_pc <= { 32'd0, reg_araddr[31:4], 1'b1 ,3'b0 };
        get_addr2 <= 1'b1;
    end
    else begin
        get_addr1 <= 1'b0;
        get_addr2 <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)begin
        rresp <= 1'b0;
        rvalid <= 1'b1;
        first_over <= 1'b0;
        rlast <= 1'b0;
    end
    else if(rvalid && rready && get_addr1)begin
        v_pmem_read(araddr_pc,rdata);
        rresp <= 1'b1;
        first_over <= 1'b1;
    end
    else if(rvalid && rready && get_addr2)begin
        v_pmem_read(araddr_pc,rdata);
        rresp <= 1'b1;
        rlast <= 1'b1;
    end
    else begin
        rresp <= 1'b0;
        first_over <= 1'b0;
        rlast <= 1'b0;
    end
end

endmodule