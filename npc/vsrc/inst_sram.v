`timescale 1ns/1ps
/* read only AXI-lite instruction sram
8/15
要求每个周期都能接收地址，第二个周期把数据送出去
 */
module ysyx_22050854_SRAM_IFU (
    input clk,
    input rst_n,

    input [31:0]araddr, 
    input arvalid,
    output reg arready, //I-SRAM 准备好接收地址了没？

    output reg [63:0]rdata,
    output reg rvalid,
    input rready,
    output reg rresp
);

import "DPI-C" function void v_pmem_read(
input longint raddr, output longint rdata);

/* parameter idle = 1'b0 , ready_to_send = 1'b1;
reg state; */

reg [63:0]araddr_pc;
reg get_addr;
always @(posedge clk)begin
    if(!rst_n)begin
        arready <= 1'b1;
        get_addr <= 1'b0;
    end
    else if(arvalid && arready)begin
        araddr_pc <= {32'd0,araddr};
        get_addr <= 1'b1;
    end
    else begin
        get_addr <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)begin
        rresp <= 1'b0;
        rvalid <= 1'b1;
    end
    else if(rvalid && rready && get_addr)begin
        v_pmem_read(araddr_pc,rdata);
        rresp <= 1'b1;
    end
    else
        rresp <= 1'b0;
end

endmodule