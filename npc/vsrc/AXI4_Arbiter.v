/*
  仲裁器的作用是当LSU IFU同时访问存储器时，选一个主机 与 MEM 交互 
 */

module ysyx_22050854_AXI_arbiter(
    input clock,
    input reset,
    
    input IFU_request,
    input LSU_request,
    input [31:0]IFU_addr,
    input [31:0]LSU_addr,
    output AXI_arbiter_arvalid,
    output [3:0]AXI_arbiter_arid,
    output [31:0]AXI_arbiter_addr
);

    wire Double_request;
    assign Double_request = IFU_request & LSU_request;
    reg reg_DoubleRequest;
    always @(posedge clock)begin
        if(reset)
            reg_DoubleRequest <= 1'b0;
        else
            reg_DoubleRequest <= IFU_request & LSU_request;
    end

    reg [31:0]addr_DoubleRequest;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg_addr_DoubleRequest ( clock, reset, LSU_addr, addr_DoubleRequest, IFU_request & LSU_request );

    assign AXI_arbiter_arvalid = IFU_request | LSU_request | reg_DoubleRequest;
    assign AXI_arbiter_arid = IFU_request ? 4'b0001 : ( ( LSU_request | reg_DoubleRequest ) ? 4'b0010  : 4'b0 );
    assign AXI_arbiter_addr = IFU_request ? IFU_addr : ( LSU_request ? LSU_addr  : ( reg_DoubleRequest ? addr_DoubleRequest : 32'b0 ) );

endmodule

