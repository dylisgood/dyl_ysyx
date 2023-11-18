module ysyx_22050854_SRAM_LSU (
    input clock,
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

/* localparam idle = 1'b0, ready_to_send = 1'b1;
reg read_state, write_state; */

// read
// 8.16 change to every cycle can get addr ,next cycle send data
reg [63:0]read_addr_64;
reg get_read_addr;
always @(posedge clock)begin
    if(!rst_n) begin
        arready <= 1'b1;      //假设DATA SRAM是一直能接收地址信号的，即每周期都能接收
        get_read_addr <= 1'b0;
    end
    else if(arready && arvalid)begin
        read_addr_64 <= {32'd0,araddr};
        get_read_addr <= 1'b1;
    end
    else
        get_read_addr <= 1'b0;
end

always @(posedge clock)begin
    if(!rst_n)begin
        rresp <= 1'b0;
        rvalid <= 1'b1;  //假设DATA SRAM的数据一直是准备好的，收到地址的下一个周期就能把数据送出去
    end
    else if(get_read_addr)begin
        v_pmem_read(read_addr_64,rdata);
        rresp <= 1'b1;
    end
    else
        rresp <= 1'b0;
end

//write   
reg [63:0]dsram_write_addr;
reg [63:0]dsram_write_data;
reg [7:0]dsram_wtsb;
wire [63:0]wmask;
assign wmask = { {8{dsram_wtsb[7]}}, {8{dsram_wtsb[6]}}, {8{dsram_wtsb[5]}}, {8{dsram_wtsb[4]}}, {8{dsram_wtsb[3]}}, {8{dsram_wtsb[2]}}, {8{dsram_wtsb[1]}}, {8{dsram_wtsb[0]}} };

reg get_write_addr;
always @(posedge clock)begin
    if(!rst_n) begin
        awready <= 1'd1;
        get_write_addr <= 1'b0;
    end
    else if(awvalid && awready) begin
        dsram_write_addr <= { 32'd0, awaddr};
        get_write_addr <= 1'b1;
    end
    else
        get_write_addr <= 1'b0;
end

reg get_write_data;
always @(posedge clock)begin
    if(!rst_n)begin
        wready <= 1'd1;
        get_write_data <= 1'b0;
    end
    else if(wvalid && wready)begin
        dsram_write_data <= wdata;
        dsram_wtsb <= wstrb;
        get_write_data <= 1'b1;
    end
    else
        get_write_data <= 1'b0;
end

always @(posedge clock)begin
    if(!rst_n)
        bresp <= 1'b0;
    else if(get_write_addr && get_write_data)begin
        v_pmem_write(dsram_write_addr,dsram_write_data,wmask);
        bresp <= 1'b1;
    end
    else 
        bresp <= 1'b0;
end

endmodule