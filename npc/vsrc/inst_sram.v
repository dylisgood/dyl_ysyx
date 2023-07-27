`timescale 1ns/1ps
/* read only AXI-lite instruction sram

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

parameter idle = 1'b0 , ready_to_send = 1'b1;
reg state;

reg [63:0]araddr_pc;
always @(posedge clk)begin
    if(!rst_n)begin
        arready <= 1'b1;
    end
    else if(arvalid && arready)begin
        araddr_pc <= {32'd0,araddr};
        arready <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)begin
        rvalid <= 1'b1;
        state <= idle;
    end
    else if(rvalid && rready)begin
        state <= ready_to_send;
        rvalid <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)begin
        rresp <= 1'b0;
    end
    else if(state == ready_to_send)begin
        v_pmem_read(araddr_pc,rdata);
        state <= idle;
        rresp <= 1'b1;
        arready <= 1'b1;
        rvalid <= 1'b1;
    end
    else
        rresp <= 1'b0;
end

/* always @(posedge clk)begin
    if(!rst_n) begin
        state <= idle;
        arready <= 1'b1; //复位后，I-SRAM做好了接收PC的准备
        rvalid <= 1'b1;  //
        rresp <= 1'b0;
    end
    else if(arvalid && rready)begin  //收到取指请求
        state <= ready_to_send;       
        rresp <= 1'b0;
        arready <= 1'd0; //表示我现在获得了一个地址，不能再接受一个地址了，直到把地址发出去
    end
    else begin
        state <= idle;
        rresp <= 1'b0;
        arready <= 1'd1;
    end
end

//radate rresp
always @(posedge clk)begin
    if(state == ready_to_send) begin
        v_pmem_read(araddr_pc,rdata);
        rresp <= 1'b1;
        state <= idle;
        arready <= 1'd1;  //我又可以接收下一个pc了
    end
end */

endmodule