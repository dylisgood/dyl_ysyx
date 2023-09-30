module ysyx_22050854_Dcache (clk,rst,
    valid,op,index,tag,offset,wstrb,wdata,addr_ok,data_ok,rdata,
    rd_req,rd_type,rd_addr,rd_rdy,ret_valid,ret_last,ret_data,wr_type,wr_addr,wr_wstb,wr_data,wr_rdy
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
input [Tag_Bits - 1 : 0 ]tag;    // 32 - 4- 7 = 21
input [Offset_Bits - 1:0]offset;   //每一个块的大小是16字节
input [7:0]wstrb;    //最大是能写八个字节的
input [63:0]wdata;    //写数据
output addr_ok;       //表示这次请求的地址传输OK
output data_ok;       //表示这次请求的数据传输OK
output [63:0]rdata;    //读cache的结果
//Cache 与 AXI总线接口的交互接口
output rd_req;        //读请求有效信号，高电平valid
output rd_type;       //读请求类型，3‘b000: 字节 001---半字  010---字 100-cache行
output [31:0]rd_addr;       //读请求起始地址
input rd_rdy;       //读请求能否被接受的握手信号，高电平有效
input ret_valid;      //返回数据有效   
input ret_last;     //返回数据是一次读请求对应最后一个返回的数据
input [63:0]ret_data;     //读返回数据
output wr_req;     //写请求信号，高电平有效
output wr_type;     //写请求类型， 000---字节 001---半字  010---字  100----cache行
output [31:0]wr_addr;     //写请求地址
output [7:0]wr_wstb;   //写操作的字节掩码
output wr_data;        //写数据
input wr_rdy;          //写请求能否被接收的握手信号，高电平有效，要求wr_rdy先于wr_req置起，wr_req看到wr_rdy置起后才可能置起



endmodule 