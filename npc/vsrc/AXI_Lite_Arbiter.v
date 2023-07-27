/*
  仲裁器的作用是当LSU IFU同时访问存储器时，选一个主机 与 MEM 交互 
 */

module ysyx_22050854_axi_lite_arbiter(
    input ifu_request,
    input lsu_request,
    input mux_select,  //0---ifu  1---lsu

    input [63:0]sram_data_in,
    input sram_write_enable,
    input sram_read_enable,
    output [63:0]sram_data_out
);

    reg[63:0] sram_data_reg;
    reg sram_read_enable_reg, sram_write_enable_reg;
    wire [63:0] data_to_sram;

    assign data_to_sram = (mux_select & ifu_request) ? ifu_data_out : lsu_data_out;

    //连接SRAM读写信号
    assign sram_read_enable_reg = mux_select & ifu_request & ifu_read_enable;
    assign sram_write_enable_reg = mux_select & ifu_request & ifu_write_enable;

    always @(*)begin
    end
endmodule