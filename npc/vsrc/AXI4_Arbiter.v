/*
  仲裁器的作用是当LSU IFU同时访问存储器时，选一个主机 与 MEM 交互 
 */

module ysyx_22050854_AXI_arbiter(
    input clock,
    input reset,
    
    input IFU_request,
    input FLS_request,
    input LSU_request,
    input DEV_request,
    input arready,
    input [31:0]IFU_addr,
    input [31:0]FLS_addr,
    input [31:0]LSU_addr,
    input [31:0]Device_addr,
    output reg AXI_arbiter_arvalid,
    output reg [3:0]AXI_arbiter_arid,
    output reg [31:0]AXI_arbiter_addr,
    output reg [7:0]AXI_arbiter_arlen,
    output reg [2:0]AXI_arbiter_arsize,
    output reg [1:0]AXI_arbiter_arburst
);
    //IFU first
    wire Double_request;
    assign Double_request = ( IFU_request | FLS_request ) & ( LSU_request | DEV_request );

    reg reg_DoubleRequest;
    ysyx_22050854_Reg #(1,1'b0) Inst_reg_DoubleRequest ( clock, reset, Double_request, reg_DoubleRequest, Double_request );
    reg Double_is_Device;
    ysyx_22050854_Reg #(1,1'b0) Inst_Double_is_Device ( clock, reset, DEV_request, Double_is_Device, Double_request );

    reg [31:0]addr_DoubleRequest;
    wire [31:0]store_address;
    assign store_address = DEV_request ? Device_addr : LSU_addr;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg_addr_DoubleRequest ( clock, reset, store_address, addr_DoubleRequest, Double_request );

/*     wire IFU_req_is_mem;
    assign IFU_req_is_mem = ( IFU_addr <= 32'h87ffffff ) ? 1'b1 : 1'b0; */
    //assign IFU_req_is_mem = ( IFU_addr >= 32'h80000000 && IFU_addr <= 32'hfbffffff ) ? 1'b1 : 1'b0;

    //IFU-0001   MEM--0010  DEV---0011
    //arid:   IFU-0001   MEM--0010  DEV---0011
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arid <= 4'b0;
        else if( IFU_request )
            AXI_arbiter_arid <= 4'b0001;
        else if( FLS_request)
            AXI_arbiter_arid <= 4'b0100;
        else if( LSU_request )
            AXI_arbiter_arid <= 4'b0010;
        else if( DEV_request )
            AXI_arbiter_arid <= 4'b0011;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arid <= Double_is_Device ? 4'b0011 : 4'b0010;
        else 
            AXI_arbiter_arid <= 4'b0;
    end

    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_addr <= 32'b0;
        else if( IFU_request )
            AXI_arbiter_addr <= IFU_addr;
        else if( FLS_request )
            AXI_arbiter_addr <= FLS_addr;
        else if( LSU_request )
            AXI_arbiter_addr <= LSU_addr;
        else if( DEV_request )
            AXI_arbiter_addr <= Device_addr;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_addr <= addr_DoubleRequest;
        else 
            AXI_arbiter_addr <= 32'b0;
    end

    //arlen
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arlen <= 8'b0;
        else if( IFU_request )
            AXI_arbiter_arlen <= 8'b1;
        else if( FLS_request )
            AXI_arbiter_arlen <= 8'b0;
        else if( LSU_request )
            AXI_arbiter_arlen <= 8'b1;
        else if( DEV_request )
            AXI_arbiter_arlen <= 8'b0;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arlen <= Double_is_Device ? 8'b0 : 8'b1;
        else 
            AXI_arbiter_arlen <= 8'b0;
    end

    //arsize
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arsize <= 3'b0;
        else if( IFU_request )
            AXI_arbiter_arsize <= 3'b100;  // 2^4=16Bytes
        else if( FLS_request )
            AXI_arbiter_arsize <= 3'b010;  // 2^2=4Bytes
        else if( LSU_request )
            AXI_arbiter_arsize <= 3'b100; 
        else if( DEV_request )
            AXI_arbiter_arsize <= 3'b010;  // 4Bytes
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arsize <= Double_is_Device ? 3'b010 : 3'b100;
        else 
            AXI_arbiter_arsize <= 3'b0;
    end

    //arburst
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arburst <= 2'b0;
        else if( IFU_request )
            AXI_arbiter_arburst <= 2'b01;
        else if( FLS_request )
            AXI_arbiter_arburst <= 2'b00; 
        else if( LSU_request )
            AXI_arbiter_arburst <= 2'b01; 
        else if( DEV_request )
            AXI_arbiter_arburst <= 2'b0;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arburst <= Double_is_Device ? 2'b0 : 2'b01;
        else 
            AXI_arbiter_arburst <= 2'b0;
    end

    //generate arvalid
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arvalid <= 1'b0;
        else if( IFU_request | FLS_request | LSU_request | DEV_request ) 
            AXI_arbiter_arvalid <= 1'b1;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )begin
            AXI_arbiter_arvalid <= 1'b1;
            reg_DoubleRequest <= 1'b0;
        end
        else if( AXI_arbiter_arvalid && arready ) //if woshou success,set 0,and can access Both_request
            AXI_arbiter_arvalid <= 1'b0;
    end

    //assign AXI_arbiter_arvalid = IFU_request | LSU_request | DEV_request | reg_DoubleRequest;

    wire [31:0]AXI_arbiter_arvalid_32;
    assign AXI_arbiter_arvalid_32 = { 24'b0,AXI_arbiter_arid,IFU_request,LSU_request,DEV_request,reg_DoubleRequest};
    import "DPI-C" function void get_AXI_arbiter_arvalid_32_value(int AXI_arbiter_arvalid_32);
    always@(*) get_AXI_arbiter_arvalid_32_value(AXI_arbiter_arvalid_32);
/*     wire AXI_arbiter_arid_32;
    assign AXI_arbiter_arid_32 = { 28'b0,AXI_arbiter_arid};
    import "DPI-C" function void get_AXI_arbiter_arvalid_32_value(int AXI_arbiter_arvalid_32);
    always@(*) get_AXI_arbiter_arvalid_32_value(AXI_arbiter_arvalid_32); */

endmodule

