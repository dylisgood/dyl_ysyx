/*
    I-cache 大小为4KB,一个ram大小为1KB，需要例化4个ram
    我想分成两路组相连，一路2KB，cache行大小为16B，128个行
    但这只是data 还有tag v d 呢 
    tag如何与data联系起来？

*/

module ysyx_22050854_Icache (clk,rst,
    valid,op,index,tag,offset,addr_ok,data_ok,rdata,unshoot,
    rd_req,rd_type,rd_addr,rd_rdy,ret_valid,ret_last,ret_data,
    sram0_addr,sram0_cen,sram0_wen,sram0_wmask,sram0_wdata,sram0_rdata,
    sram1_addr,sram1_cen,sram1_wen,sram1_wmask,sram1_wdata,sram1_rdata,
    sram2_addr,sram2_cen,sram2_wen,sram2_wmask,sram2_wdata,sram2_rdata,
    sram3_addr,sram3_cen,sram3_wen,sram3_wmask,sram3_wdata,sram3_rdata
);

parameter Offset_Bits = 4; //每一个cache块的大小是16B
parameter Index_Bits = 7;  //
parameter Tag_Bits = 21;

input clk;
input rst;
//Cache & CPU interface 
input valid;    //表明请求有效
input op;       // 1:write 0:read
input [Index_Bits - 1 : 0 ]index;    // 地址的index域,一路是2KB 一个块是16B，所以有11 - 4 = 7 个块
input [Tag_Bits - 1 : 0 ]tag;// 32 - 4- 7 = 21
input [Offset_Bits - 1:0]offset;       //每一个块的大小是16字节
output addr_ok;       //表示这次请求的地址传输OK
output data_ok;       //表示这次请求的数据传输OK
output [63:0]rdata;    //读cache的结果
output reg unshoot;
//Cache 与 AXI总线接口的交互接口
output reg rd_req;        //读请求有效信号，高电平valid
output reg [2:0]rd_type;       //读请求类型，3‘b000: 字节 001---半字  010---字 100-cache行
output reg [31:0]rd_addr;       //读请求起始地址
input rd_rdy;       //读请求能否被接受的握手信号，高电平有效
input ret_valid;      //返回数据有效   
input ret_last;     //返回数据是一次读请求对应最后一个返回的数据
input [63:0]ret_data;     //读返回数据

//cache 与 ram的交互信号
output [5:0]sram0_addr;
output sram0_cen;
output sram0_wen;
output [127:0]sram0_wmask;
output [127:0]sram0_wdata;
input [127:0]sram0_rdata;
output [5:0]sram1_addr;
output sram1_cen;
output sram1_wen;
output [127:0]sram1_wmask;
output [127:0]sram1_wdata;
input [127:0]sram1_rdata;
output [5:0]sram2_addr;
output sram2_cen;
output sram2_wen;
output [127:0]sram2_wmask;
output [127:0]sram2_wdata;
input [127:0]sram2_rdata;
output [5:0]sram3_addr;
output sram3_cen;
output sram3_wen;
output [127:0]sram3_wmask;
output [127:0]sram3_wdata;
input [127:0]sram3_rdata;

parameter IDLE = 4'b0001,LOOKUP = 4'b0010, MISS = 4'b0100, REPLACE = 4'b1000;
reg [3:0]state;

reg [Index_Bits - 1 : 0]RB_index;
reg [Tag_Bits - 1 : 0]RB_tag;
reg [Offset_Bits - 1 : 0]RB_offset;
reg [Index_Bits - 1 : 0]HIT_index;
reg [Tag_Bits - 1 : 0]HIT_tag;
reg [Offset_Bits - 1 : 0]HIT_offset;
reg [127:0] Bus_retdata;

reg [21:0] Way0_TagV [127:0];
reg [21:0] Way1_TagV [127:0];
initial 
begin
    for (int i = 0; i < 128; i = i + 1)begin
        Way0_TagV[i] = 0;
        Way1_TagV[i] = 0;
    end
end

wire [127:0]ram1_data;
reg ram1_CEN;
reg ram1_WEN;
reg [127:0]ram1_bwen;
reg [5:0]ram1_addr;
reg [127:0]ram1_wdata;

wire [127:0]ram2_data;
reg ram2_CEN;
reg ram2_WEN;
reg [127:0]ram2_bwen;
reg [5:0]ram2_addr;
reg [127:0]ram2_wdata;

wire [127:0]ram3_data;
reg ram3_CEN;
reg ram3_WEN;
reg [127:0]ram3_bwen;
reg [5:0]ram3_addr;
reg [127:0]ram3_wdata;

wire [127:0]ram4_data;
reg ram4_CEN;
reg ram4_WEN;
reg [127:0]ram4_bwen;
reg [5:0]ram4_addr;
reg [127:0]ram4_wdata;

reg Data_OK;
reg ADDR_OK;
reg hit_way0;
reg hit_way1;
reg HIT_way0;
reg HIT_way1;
wire [127:0]read_ramdata;
//state machine transition
always @(posedge clk)begin
    if(rst)begin
        state <= IDLE;
        RB_index <= 7'd0;
        RB_tag <= 21'd0;
        RB_offset <= 4'd0;
        HIT_index <= 7'd0;
        HIT_tag <= 21'd0;
        HIT_offset <= 4'd0;
        ADDR_OK <= 1'b0;
        hit_way0 <= 1'b0;
        hit_way1 <= 1'b0;
        HIT_way0 <= 1'b0;
        HIT_way1 <= 1'b0;
        unshoot <= 1'b0;
        Data_OK <= 1'b0;
        ram1_CEN <= 1'b1;
        ram1_WEN <= 1'b1;
        ram1_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram1_addr <= 6'b0;
        ram1_wdata <= 128'b0;
        ram2_CEN <= 1'b1;
        ram2_WEN <= 1'b1;
        ram2_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram2_addr <= 6'b0;
        ram2_wdata <= 128'b0;
        ram3_CEN <= 1'b1;
        ram3_WEN <= 1'b1;
        ram3_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram3_addr <= 6'b0;
        ram3_wdata <= 128'b0;
        ram4_CEN <= 1'b1;
        ram4_WEN <= 1'b1;
        ram4_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram4_addr <= 6'b0;
        ram4_wdata <= 128'b0; 
    end
    else begin
    case(state)
        IDLE: 
            begin 
                ram1_WEN <= 1'b1;
                ram1_bwen <= 128'hffffffffffffffffffffffffffffffff;
                ram1_addr <= 6'b0;
                ram1_wdata <= 128'b0;
                ram2_WEN <= 1'b1;
                ram2_bwen <= 128'hffffffffffffffffffffffffffffffff;
                ram2_addr <= 6'b0;
                ram2_wdata <= 128'b0;
                ram3_WEN <= 1'b1;
                ram3_bwen <= 128'hffffffffffffffffffffffffffffffff;
                ram3_addr <= 6'b0;
                ram3_wdata <= 128'b0;
                ram4_WEN <= 1'b1;
                ram4_bwen <= 128'hffffffffffffffffffffffffffffffff;
                ram4_addr <= 6'b0;
                ram4_wdata <= 128'b0;
                
                Data_OK <= 1'b0;

                if(valid & !op ) begin
                    RB_index <= index;  
                    RB_tag <= tag;
                    RB_offset <= offset;
                    ADDR_OK <= 1'b1;
                    if( Way0_TagV[index] == {1'b1,tag} ) begin //hit way0
                        state <= LOOKUP;
                        ram1_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram2_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram1_addr <= index[5:0];
                        ram2_addr <= index[5:0];
                        hit_way0 <= 1'b1;
                        hit_way1 <= 1'b0;
                        ram3_CEN <= 1'b1;
                        ram4_CEN <= 1'b1;
                    end
                    else if( Way1_TagV[index] == {1'b1,tag} ) begin //hit way1
                        state <= LOOKUP;
                        ram3_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram4_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram3_addr <= index[5:0];
                        ram4_addr <= index[5:0];
                        hit_way1 <= 1'b1;
                        hit_way0 <= 1'b0;
                        ram1_CEN <= 1'b1;
                        ram2_CEN <= 1'b1;
                    end
                    else begin                      //unshoot
                        if(rd_rdy)begin             // only AXI(SRAM) ready cloud generate request
                            rd_req <= 1'b1;
                            rd_type <= 3'b100;
                            rd_addr <= {tag,index,offset};
                        end
                        state <= MISS;
                        unshoot <= 1'b1;
                        hit_way0 <= 1'b0;
                        hit_way1 <= 1'b0;
                        ram1_CEN <= 1'b1;
                        ram2_CEN <= 1'b1;
                        ram3_CEN <= 1'b1;
                        ram4_CEN <= 1'b1;
                    end
                end
                else begin
                    state <= IDLE;
                    ADDR_OK <= 1'b0;

                    ram1_CEN <= 1'b1;
                    ram2_CEN <= 1'b1;
                    ram3_CEN <= 1'b1;
                    ram4_CEN <= 1'b1;
                end
            end
        LOOKUP:                      //only hit could enter state:LOOKUP
            begin
                if( hit_way0 || hit_way1) begin
                    HIT_index <= RB_index;  
                    HIT_tag <= RB_tag;
                    HIT_offset <= RB_offset;
                    HIT_way0 <= hit_way0;
                    HIT_way1 <= hit_way1;
                    Data_OK <= 1'b1;
                    ram1_CEN <= 1'b1;
                    ram2_CEN <= 1'b1;
                    ram3_CEN <= 1'b1;
                    ram4_CEN <= 1'b1;
                end
                else 
                    Data_OK <= 1'b0;

                if( !valid ) begin             //finish and no new request
                    state <= IDLE;
                    ADDR_OK <= 1'b0;
                    
                end
                else if( valid & !op) begin   //get valid again
                    RB_index <= index;  
                    RB_tag <= tag;
                    RB_offset <= offset;
                    ADDR_OK <= 1'b1;
                    if( Way0_TagV[index] == {1'b1,tag} ) begin //hit way0
                        state <= LOOKUP;
                        ram1_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram2_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram1_addr <= index[5:0];
                        ram2_addr <= index[5:0];
                        hit_way0 <= 1'b1;
                        hit_way1 <= 1'b0;
                    end
                    else if( Way1_TagV[index] == {1'b1,tag} ) begin //hit way1
                        state <= LOOKUP;
                        ram3_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram4_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram3_addr <= index[5:0];
                        ram4_addr <= index[5:0];
                        hit_way1 <= 1'b1;
                        hit_way0 <= 1'b0;
                    end
                    else begin                      // unshoot
                        if(rd_rdy)begin             // only AXI(SRAM) ready cloud generate request
                            rd_req <= 1'b1;
                            rd_type <= 3'b100;
                            rd_addr <= {tag,index,offset};
                        end
                        state <= MISS;
                        unshoot <= 1'b1;
                        hit_way0 <= 1'b0;
                        hit_way1 <= 1'b0;
                    end
                end
            end
        MISS:
            begin
                rd_req <= 1'b0;
                rd_type <= 3'b100;
                rd_addr <= 32'b0;
                ADDR_OK <= 1'b0;
                Data_OK <= 1'b0;
                HIT_way0 <= hit_way0;
                HIT_way1 <= hit_way1;
                if(ret_valid & !ret_last) begin //bus return data
                    state <= MISS;
                    Bus_retdata[63:0] <= ret_data; 
                end
                else if(ret_valid & ret_last)begin        //got whole cacheline from AXI
                    state <= REPLACE;
                    Bus_retdata[127:64] <= ret_data;
                    Data_OK <= 1'b1;
                end
                else 
                    state <= MISS;
            end
        REPLACE:
            begin
                state <= IDLE;
                unshoot <= 1'b0;
                Data_OK <= 1'b0;
                if( RB_index[6] && ~Way0_TagV[ RB_index ][21] )begin
                    ram2_CEN <= 1'b0;
                    ram2_WEN <= 1'b0;
                    ram2_bwen <= 128'b0;
                    ram2_addr <= RB_index[5:0];
                    ram2_wdata <= Bus_retdata;
                    Way0_TagV[RB_index] <= {1'b1,RB_tag};
                end
                else if( !RB_index[6] && ~Way0_TagV[ RB_index ][21])begin
                    ram1_CEN <= 1'b0;
                    ram1_WEN <= 1'b0;
                    ram1_bwen <= 128'b0;
                    ram1_addr <= RB_index[5:0];
                    ram1_wdata <= Bus_retdata;
                    Way0_TagV[RB_index] <= {1'b1,RB_tag};
                end
                else if( RB_index[6] && ~Way1_TagV[ RB_index ][21])begin
                    ram4_CEN <= 1'b0;
                    ram4_WEN <= 1'b0;
                    ram4_bwen <= 128'b0;
                    ram4_addr <= RB_index[5:0];
                    ram4_wdata <= Bus_retdata;
                    Way1_TagV[RB_index] <= {1'b1,RB_tag};
                end
                else if( !RB_index[6] && ~Way1_TagV[ RB_index ][21])begin     
                    ram3_CEN <= 1'b0;
                    ram3_WEN <= 1'b0;
                    ram3_bwen <= 128'b0;
                    ram3_addr <= RB_index[5:0];
                    ram3_wdata <= Bus_retdata;
                    Way1_TagV[RB_index] <= {1'b1,RB_tag};
                end
                else if( Way0_TagV[ RB_index ][21] && Way1_TagV[ RB_index ][21] )begin  //If both full // replace way0
                    if( RB_index[6]  )begin
                        ram2_CEN <= 1'b0;
                        ram2_WEN <= 1'b0;
                        ram2_bwen <= 128'b0;
                        ram2_addr <= RB_index[5:0];
                        ram2_wdata <= Bus_retdata;
                        Way0_TagV[RB_index] <= {1'b1,RB_tag};
                    end
                    else if( !RB_index[6] )begin
                        ram1_CEN <= 1'b0;
                        ram1_WEN <= 1'b0;
                        ram1_bwen <= 128'b0;
                        ram1_addr <= RB_index[5:0];
                        ram1_wdata <= Bus_retdata;
                        Way0_TagV[RB_index] <= {1'b1,RB_tag};
                    end
                end
            end
        default:
            state <= IDLE;
    endcase 
    end
end

assign read_ramdata = Data_OK ? ( HIT_way0 ? ( HIT_index[6] ? sram1_rdata : sram0_rdata ) : ( HIT_way1 ? ( HIT_index[6] ? sram3_rdata : sram2_rdata) : 128'b0 ) ) : 128'b0;
assign rdata = Data_OK ? ( ( state == REPLACE ) ? (  RB_offset[3] ?  Bus_retdata[127:64] : Bus_retdata[63:0] ) : ( HIT_offset[3] ?  read_ramdata[127:64] : read_ramdata[63:0] ) ) : 64'b0;

assign data_ok = Data_OK;
assign addr_ok = ADDR_OK;

assign sram0_addr = ram1_addr;
assign sram0_cen = ram1_CEN;
assign sram0_wen = ram1_WEN;
assign sram0_wmask = ram1_bwen;
assign sram0_wdata = ram1_wdata;

assign sram1_addr = ram2_addr;
assign sram1_cen = ram2_CEN;
assign sram1_wen = ram2_WEN;
assign sram1_wmask = ram2_bwen;
assign sram1_wdata = ram2_wdata;

assign sram2_addr = ram3_addr;
assign sram2_cen = ram3_CEN;
assign sram2_wen = ram3_WEN;
assign sram2_wmask = ram3_bwen;
assign sram2_wdata = ram3_wdata;

assign sram3_addr = ram4_addr;
assign sram3_cen = ram4_CEN;
assign sram3_wen = ram4_WEN;
assign sram3_wmask = ram4_bwen;
assign sram3_wdata = ram4_wdata;

wire [31:0]cache_state_32;
assign cache_state_32 = {28'b0,state};
import "DPI-C" function void get_cache_state_32_value(int cache_state_32);
always@(*) get_cache_state_32_value(cache_state_32);

wire [31:0]rd_req_32;
assign rd_req_32 = {31'b0,rd_req};
import "DPI-C" function void get_rd_req_32_value(int rd_req_32);
always@(*) get_rd_req_32_value(rd_req_32);

import "DPI-C" function void get_rd_addr_value(int rd_addr);
always@(*) get_rd_addr_value(rd_addr);

wire [31:0]ret_valid_32;
assign ret_valid_32 = {31'b0,ret_valid};
import "DPI-C" function void get_ret_valid_32_value(int ret_valid_32);
always@(*) get_ret_valid_32_value(ret_valid_32);

wire [31:0]ret_last_32;
assign ret_last_32 = {31'b0,ret_last};
import "DPI-C" function void get_ret_last_32_value(int ret_last_32);
always@(*) get_ret_last_32_value(ret_last_32);

wire [31:0]ret_data_32;
assign ret_data_32 = ret_data[31:0];
import "DPI-C" function void get_ret_data_32_value(int ret_data_32);
always@(*) get_ret_data_32_value(ret_data_32);

wire [31:0]Data_OK_32;
assign Data_OK_32 = {31'b0,Data_OK};
import "DPI-C" function void get_Data_OK_32_value(int Data_OK_32);
always@(*) get_Data_OK_32_value(Data_OK_32);

wire [31:0]rdata_32;
assign rdata_32 = read_ramdata[31:0];
import "DPI-C" function void get_cache_rdata_32_value(int rdata_32);
always@(*) get_cache_rdata_32_value(rdata_32);

wire [31:0]hit_32;
assign hit_32 = { 30'b0,hit_way1,hit_way0};
import "DPI-C" function void get_hit_32_value(int hit_32);
always@(*) get_hit_32_value(hit_32);

endmodule