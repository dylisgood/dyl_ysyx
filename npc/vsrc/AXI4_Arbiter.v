`define FLASH_AXI4_ID 4'b0000
`define Dcache_AXI4_ID 4'b0001
`define Device_AXI4_ID 4'b0010
`define Icache_AXI4_ID 4'b0011
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
    input [2:0]Device_arsize,
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
    reg [2:0]Reg_Device_arsize;
    ysyx_22050854_Reg #(3,3'b0) Inst_Reg_Device_arsize ( clock, reset, Device_arsize, Reg_Device_arsize, Double_request );

    wire is_second_request;
    assign is_second_request = ( IFU_request | FLS_request | LSU_request | DEV_request ) && AXI_arbiter_arvalid; // this request coming but last request not handsake
    reg reg_secondRequest;
    ysyx_22050854_Reg #(1,1'b0) Inst_Second_Request ( clock, reset, is_second_request, reg_secondRequest, is_second_request );

    reg [3:0]SecondRequest_arid;
    reg [31:0]SecondRequest_addr;
    reg [7:0]SecondRequest_arlen;
    reg [2:0]SecondRequest_arsize;
    reg [1:0]SecondRequest_burst;
    ysyx_22050854_Reg #(4,4'b0) Inst_SecondRequest_arid ( clock, reset, arid_temp, SecondRequest_arid, is_second_request );
    ysyx_22050854_Reg #(32,32'b0) Inst_SecondRequest_addr ( clock, reset, addr_temp, SecondRequest_addr, is_second_request );
    ysyx_22050854_Reg #(8,8'b0) Inst_SecondRequest_arlen ( clock, reset, arlen_temp, SecondRequest_arlen, is_second_request );
    ysyx_22050854_Reg #(3,3'b0) Inst_SecondRequest_arsize ( clock, reset, arsize_temp, SecondRequest_arsize, is_second_request );
    ysyx_22050854_Reg #(2,2'b0) Inst_SecondRequest_burst ( clock, reset, arburst_temp, SecondRequest_burst, is_second_request );

    wire [3:0]arid_temp;
    wire [31:0]addr_temp;
    wire [7:0]arlen_temp;
    wire [2:0]arsize_temp;
    wire [1:0]arburst_temp;
    assign arid_temp =      FLS_request ? `FLASH_AXI4_ID : 
                            IFU_request ? `Icache_AXI4_ID : 
                            LSU_request ? `Dcache_AXI4_ID : 
                            DEV_request ? `Device_AXI4_ID : 
                            4'b1111;
    assign addr_temp =      FLS_request ? FLS_addr : 
                            IFU_request ? IFU_addr : 
                            LSU_request ? LSU_addr : 
                            DEV_request ? Device_addr : 
                            32'b0;
    assign arlen_temp =     FLS_request ? 8'b0 : 
                            IFU_request ? 8'b1 : 
                            LSU_request ? 8'b1 : 
                            DEV_request ? 8'b0 : 
                            8'b0;
    assign arsize_temp =    FLS_request ? 3'b010 : 
                            IFU_request ? 3'b011 : 
                            LSU_request ? 3'b011 : 
                            DEV_request ? Device_arsize : 
                            3'b0;
    assign arburst_temp =   FLS_request ? 2'b00 : 
                            IFU_request ? 2'b01 : 
                            LSU_request ? 2'b01 : 
                            DEV_request ? 2'b00 : 
                            2'b0;  

    //IFU-0001   MEM--0010  DEV---0011
    //arid:   IFU-0011   MEM--0001  DEV---0010
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arid <= 4'b0000;
        else if( ( IFU_request | FLS_request | LSU_request | DEV_request ) && ~AXI_arbiter_arvalid )
            AXI_arbiter_arid <= arid_temp;
        else if( reg_secondRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arid <= SecondRequest_arid;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arid <= Double_is_Device ? `Device_AXI4_ID : `Dcache_AXI4_ID;
    end

    //araddr
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_addr <= 32'b0;
        else if( ( IFU_request | FLS_request | LSU_request | DEV_request ) && ~AXI_arbiter_arvalid )
            AXI_arbiter_addr <= addr_temp;
        else if( reg_secondRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_addr <= SecondRequest_addr;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_addr <= addr_DoubleRequest;
    end

    //arlen
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arlen <= 8'b0;
        else if( ( IFU_request | FLS_request | LSU_request | DEV_request ) && ~AXI_arbiter_arvalid )
            AXI_arbiter_arlen <= arlen_temp;
        else if( reg_secondRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arlen <= SecondRequest_arlen;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arlen <= Double_is_Device ? 8'b0 : 8'b1;
    end

    //arsize
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arsize <= 3'b0;
        else if( ( IFU_request | FLS_request | LSU_request | DEV_request ) && ~AXI_arbiter_arvalid )
            AXI_arbiter_arsize <= arsize_temp;  // 2^3 = 8 Bytes
        else if( reg_secondRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arsize <= SecondRequest_arsize;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arsize <= Double_is_Device ? Reg_Device_arsize : 3'b011;
    end

    //arburst
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arburst <= 2'b0;
        else if( ( IFU_request | FLS_request | LSU_request | DEV_request ) && ~AXI_arbiter_arvalid )
            AXI_arbiter_arburst <= arburst_temp;
        else if( reg_secondRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arburst <= SecondRequest_burst;
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )
            AXI_arbiter_arburst <= Double_is_Device ? 2'b00 : 2'b01;
    end

    //generate arvalid
    always @(posedge clock)begin
        if(reset)
            AXI_arbiter_arvalid <= 1'b0;
        else if( AXI_arbiter_arvalid && arready ) //if woshou success,set 0,and can access Both_request
            AXI_arbiter_arvalid <= 1'b0;
        else if( ( IFU_request | FLS_request | LSU_request | DEV_request ) && ~AXI_arbiter_arvalid )begin
            AXI_arbiter_arvalid <= 1'b1;
        end
        else if( reg_secondRequest && ~AXI_arbiter_arvalid )begin
            AXI_arbiter_arvalid <= 1'b1;
            reg_secondRequest <= 1'b0;
        end
        else if( reg_DoubleRequest && ~AXI_arbiter_arvalid )begin
            AXI_arbiter_arvalid <= 1'b1;
            reg_DoubleRequest <= 1'b0;
        end

    end

/*     
    wire [31:0]AXI_arbiter_arvalid_32;
    assign AXI_arbiter_arvalid_32 = { 24'b0,AXI_arbiter_arid,IFU_request,LSU_request,DEV_request,reg_DoubleRequest};
    import "DPI-C" function void get_AXI_arbiter_arvalid_32_value(int AXI_arbiter_arvalid_32);
    always@(*) get_AXI_arbiter_arvalid_32_value(AXI_arbiter_arvalid_32);
*/
endmodule

