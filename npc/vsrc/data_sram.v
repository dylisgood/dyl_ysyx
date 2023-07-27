`timescale 1ns/1ps
module ysyx_22050854_SRAM_LSU (
    input clk,
    input rst_n,

    //read address channel
    input [31:0]araddr,
    input arvalid,
    output reg arready, 

    //read data channel
    output reg [63:0]rdata,
    output reg rresp,
    output reg rvalid,
    input rready,

    //write address channel
    input [31:0]awaddr,
    input awvalid,
    output reg awready,

    //write data channel
    input [63:0]wdata,
    input wvalid,
    output reg wready,
    input [7:0]wstrb,

    //write response channel
    output reg bresp,
    output reg bvalid,
    input bready
);

import "DPI-C" function void v_pmem_read(
input longint raddr, output longint rdata);

import "DPI-C" function void v_pmem_write(
input longint waddr, input longint wdata, input longint wmask);

localparam idle = 1'b0, ready_to_send = 1'b1;
reg read_state, write_state;

// read
reg [63:0]read_addr_64;
always @(posedge clk)begin
    if(!rst_n)
        arready <= 1'b1;
    else if(arready && arvalid)begin
        read_addr_64 <= {32'd0,araddr};
        arready <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)begin
        read_state <= idle;
        rvalid <= 1'b1;
    end
    else if(rready && rvalid)begin
        read_state <= ready_to_send;
        rvalid <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)
        rresp <= 1'b0;
    else if(read_state == ready_to_send)begin
        v_pmem_read(read_addr_64,rdata);
        read_state <= idle;
        rresp <= 1'b1;
    end
    else
        rresp <= 1'b0;
end

always @(posedge clk)begin
    if(rresp)begin
        arready <= 1'b1;
        rvalid <= 1'b1;
    end
end

//write   
reg [63:0]dsram_write_addr;
reg [63:0]dsram_write_data;
reg [7:0]dsram_wtsb;
wire [63:0]wmask;
assign wmask = { {8{dsram_wtsb[7]}}, {8{dsram_wtsb[6]}}, {8{dsram_wtsb[5]}}, {8{dsram_wtsb[4]}}, {8{dsram_wtsb[3]}}, {8{dsram_wtsb[2]}}, {8{dsram_wtsb[1]}}, {8{dsram_wtsb[0]}} };
always @(posedge clk)begin
    if(!rst_n) awready <= 1'd1;
    else if(awvalid && awready) begin
        dsram_write_addr <= { 32'd0, awaddr};
        awready <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)begin
        wready <= 1'd1;
        write_state <= idle;
    end
    else if(wvalid && wready)begin
        dsram_write_data <= wdata;
        dsram_wtsb <= wstrb;
        write_state <= ready_to_send;
        wready <= 1'b0;
    end
end

always @(posedge clk)begin
    if(!rst_n)
        bresp <= 1'b0;
    else if(write_state == ready_to_send)begin
        v_pmem_write(dsram_write_addr,dsram_write_data,wmask);
        write_state <= idle;
        bresp <= 1'b1;
    end
    else 
        bresp <= 1'b0;
end

always @(posedge clk)begin
    if(bresp) begin
        wready <= 1'd1;
        awready <= 1'd1;
    end
end

endmodule