module ysyx_22050854_Dcache (clock,reset,
    valid,op,index,tag,offset,wstrb,wdata,data_ok,rdata,unshoot,fencei,
    rd_req,rd_addr,rd_rdy,ret_valid,ret_last,ret_data,wr_req,wr_addr,wr_wstb,wr_data,wr_rdy,wr_resp,
    sram4_addr,sram4_cen,sram4_wen,sram4_wmask,sram4_wdata,sram4_rdata,
    sram5_addr,sram5_cen,sram5_wen,sram5_wmask,sram5_wdata,sram5_rdata,
    sram6_addr,sram6_cen,sram6_wen,sram6_wmask,sram6_wdata,sram6_rdata,
    sram7_addr,sram7_cen,sram7_wen,sram7_wmask,sram7_wdata,sram7_rdata
);

parameter Offset_Bits = 4; //每一个cache块的大小是16B
parameter Index_Bits = 7;  //
parameter Tag_Bits = 21;

input clock;
input reset;
//Cache & CPU interface 
input valid;    //表明请求有效
input op;       // 1:write 0:read
input [Index_Bits - 1 : 0 ]index;    // 地址的index域,一路是2KB 一个块是16B，所以有11 - 4 = 7 个块
input [Tag_Bits - 1 : 0 ]tag;    // 32 - 4- 7 = 21
input [Offset_Bits - 1:0]offset;   //每一个块的大小是16字节
input [7:0]wstrb;    //最大是能写八个字节的
input [63:0]wdata;    //写数据
output data_ok;       //表示这次请求的数据传输OK
output [63:0]rdata;    //读cache的结果
output reg unshoot;
input fencei;

//Cache 与 AXI总线接口的交互接口
output reg rd_req;        //读请求有效信号，高电平valid
output reg [31:0]rd_addr;       //读请求起始地址
input rd_rdy;       //读请求能否被接受的握手信号，高电平有效
input ret_valid;      //返回数据有效   
input ret_last;     //返回数据是一次读请求对应最后一个返回的数据
input [63:0]ret_data;     //读返回数据
output reg wr_req;     //写请求信号，高电平有效
output reg [31:0]wr_addr;     //写请求地址
output reg [7:0]wr_wstb;   //写操作的字节掩码
output reg [127:0]wr_data;        //写数据
input wr_rdy;          //写请求能否被接收的握手信号，高电平有效，要求wr_rdy先于wr_req置起，wr_req看到wr_rdy置起后才可能置起
input wr_resp;         //写请求是否获得回应

//cache 与 ram的交互信号
output [5:0]sram4_addr;
output sram4_cen;
output sram4_wen;
output [127:0]sram4_wmask;
output [127:0]sram4_wdata;
input [127:0]sram4_rdata;
output [5:0]sram5_addr;
output sram5_cen;
output sram5_wen;
output [127:0]sram5_wmask;
output [127:0]sram5_wdata;
input [127:0]sram5_rdata;
output [5:0]sram6_addr;
output sram6_cen;
output sram6_wen;
output [127:0]sram6_wmask;
output [127:0]sram6_wdata;
input [127:0]sram6_rdata;
output [5:0]sram7_addr;
output sram7_cen;
output sram7_wen;
output [127:0]sram7_wmask;
output [127:0]sram7_wdata;
input [127:0]sram7_rdata;

parameter IDLE = 7'b0000001,LOOKUP = 7'b0000010, MISS = 7'b0000100, REPLACE = 7'b0001000,REWAIT = 7'b0010000,REFILL = 7'b0100000,WAIT_WR_RESPONSE = 7'b1000000;
reg [6:0]state;

reg [Index_Bits - 1 : 0]RB_index;
reg [Tag_Bits - 1 : 0]RB_tag;
reg RB_offset;
reg [127:0]RB_wdata;
reg RB_OP;
reg [127:0]RB_BWEN;

reg HIT_index;
reg HIT_offset;
reg [127:0] Bus_retdata;

reg [21:0] Way0_TagV [127:0];
reg [21:0] Way1_TagV [127:0];
reg [127:0] Way0_D;
reg [127:0] Way1_D;

reg ram4_CEN;
reg ram4_WEN;
reg [127:0]ram4_bwen;
reg [5:0]ram4_addr;
reg [127:0]ram4_wdata;
reg ram5_CEN;
reg ram5_WEN;
reg [127:0]ram5_bwen;
reg [5:0]ram5_addr;
reg [127:0]ram5_wdata;
reg ram6_CEN;
reg ram6_WEN;
reg [127:0]ram6_bwen;
reg [5:0]ram6_addr;
reg [127:0]ram6_wdata;
reg ram7_CEN;
reg ram7_WEN;
reg [127:0]ram7_bwen;
reg [5:0]ram7_addr;
reg [127:0]ram7_wdata;

reg Data_OK;
reg hit_way0;
reg hit_way1;
reg HIT_way0;
reg HIT_way1;
wire [127:0]read_ramdata;
reg [127:0]Replace_cache_data;

//由于这里输入进来的写掩码只有位数，并没有根据地址进行更改，所以需要自行对写掩码进行更改
//以前的更改是在仿真环境中用v_pmem_write实现的，但现在因为直接的写操作是在cache中完成，所以需要转化为精确的到字节的掩码
//而从cache写入内存时，只需要从起始地址写入一个cache块的内容了
//掩码0是写入，1无效
wire [63:0]wstrb_to_bwen_64_t;
wire [63:0]wstrb_to_bwen_64;
wire [127:0]wstrb_to_bwen_128;
wire [7:0]offset_8;
assign offset_8 = { 5'b0 , offset[2:0] };
assign wstrb_to_bwen_64_t = { {8{wstrb[7]}}, {8{wstrb[6]}}, {8{wstrb[5]}}, {8{wstrb[4]}}, {8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}} };
assign wstrb_to_bwen_64 = wstrb_to_bwen_64_t << ( offset_8 << 3 );
assign wstrb_to_bwen_128 = offset[3] ? { ~wstrb_to_bwen_64 , 64'hffffffffffffffff } : { 64'hffffffffffffffff , ~wstrb_to_bwen_64 };

wire [63:0]wdata_t;
assign wdata_t = wdata << ( offset_8 << 3 );
wire [127:0]wdata_128;
assign wdata_128 = offset[3] ? { wdata_t , 64'b0 } : { 64'b0 , wdata_t };

//Fence.I
localparam Fence_Idle = 4'b0001, Fence_Check = 4'b0010, Fence_Read = 4'b0100, Fence_Write = 4'b1000;
reg [3:0]Fence_state;

reg [8:0]Fence_counter;
always @(posedge clock)begin
    if( Fence_counter[8] ) begin
        unshoot <= 1'b0;
        Fence_counter <= 9'b0;
    end
end

reg Fence_ram4_CEN;
reg Fence_ram5_CEN;
reg Fence_ram6_CEN;
reg Fence_ram7_CEN;
reg [5:0]Fence_ram4_addr;
reg [5:0]Fence_ram5_addr;
reg [5:0]Fence_ram6_addr;
reg [5:0]Fence_ram7_addr;

reg [127:0]Fence_read_data;
reg Fence_wr;
//check way0_D, if dirty, first read ram, then write it to AXI
always @(posedge clock)begin
    if(reset) begin
        Fence_read_data <= 128'b0;
        Fence_counter <= 9'b0;
        Fence_state <= Fence_Idle;
        Fence_wr <= 1'b0;
        Fence_ram4_CEN <= 1'b1;
        Fence_ram5_CEN <= 1'b1;
        Fence_ram6_CEN <= 1'b1;
        Fence_ram7_CEN <= 1'b1;
        Fence_ram4_addr <= 6'b0;
        Fence_ram5_addr <= 6'b0;
        Fence_ram6_addr <= 6'b0;
        Fence_ram7_addr <= 6'b0;
    end
    else
    case(Fence_state)
    Fence_Idle:
        begin
            if( Fence_wr )begin  //if from Fence_Write
                wr_req <= 1'b0;
                wr_addr <= 32'b0;
                wr_wstb <= 8'h0;
                wr_data <= 128'b0;

                Fence_counter <= Fence_counter + 9'b1;
                Fence_state <= Fence_Check;
                Fence_wr <= 1'b0;
            end
            else if( ( state == IDLE || state == LOOKUP ) && fencei ) begin
                Fence_state <= Fence_Check;
                unshoot <= 1'b1;
                Fence_counter <= 9'b0;
            end
            else 
                Fence_state <= Fence_Idle;    
        end
    Fence_Check:
        begin
            if( Fence_counter[8] ) begin
                unshoot <= 1'b0;
                Fence_counter <= 9'b0;
                Fence_state <= Fence_Idle;
            end
            else
            begin
                if( ~Fence_counter[7] && Way0_D[Fence_counter[6:0]] ) //if Dirty, read ram   
                begin
                    Fence_state <= Fence_Read;
                    Way0_D[Fence_counter[6:0]] <= 1'b0;
                    
                    Fence_ram4_CEN <= ~Fence_counter[6] ? 1'b0 : 1'b1;
                    Fence_ram5_CEN <= Fence_counter[6] ? 1'b0 : 1'b1;
                    Fence_ram4_addr <= Fence_counter[5:0];
                    Fence_ram5_addr <= Fence_counter[5:0];
                end
                else if( Fence_counter[7] && Way1_D[Fence_counter[6:0]] )  //  
                begin
                    Fence_state <= Fence_Read;
                    Way1_D[Fence_counter[6:0]] <= 1'b0;

                    Fence_ram6_CEN <= ~Fence_counter[6] ? 1'b0 : 1'b1;
                    Fence_ram7_CEN <= Fence_counter[6] ? 1'b0 : 1'b1;
                    Fence_ram6_addr <= Fence_counter[5:0];
                    Fence_ram7_addr <= Fence_counter[5:0];
                end
                else begin
                    Fence_state <= Fence_Check;
                    Fence_counter <= Fence_counter + 9'b1;
                end
            end
        end
    Fence_Read:
        begin
            if( ~Fence_counter[7] && Fence_ram4_CEN && Fence_ram5_CEN )begin      //Way0
                Fence_state <= Fence_Write;
                Fence_read_data <= Fence_counter[6] ? sram5_rdata : sram4_rdata;
            end
            else if( Fence_counter[7] && Fence_ram6_CEN && Fence_ram7_CEN )begin  //Way1
                Fence_state <= Fence_Write;
                Fence_read_data <= Fence_counter[6] ? sram7_rdata : sram6_rdata;
            end
            else begin
                Fence_state <= Fence_Read; 
                Fence_ram4_CEN <= 1'b1;
                Fence_ram5_CEN <= 1'b1;
                Fence_ram6_CEN <= 1'b1;
                Fence_ram7_CEN <= 1'b1;
                Fence_ram4_addr <= 6'b0;
                Fence_ram5_addr <= 6'b0;
                Fence_ram6_addr <= 6'b0;
                Fence_ram7_addr <= 6'b0;
            end
        end
    Fence_Write:
        begin
            if( wr_rdy ) begin                      // 向AXI 发出写请求, 同时将AXI获得的数据写回到cache中
                Fence_state <= Fence_Idle;
                Fence_wr <= 1'b1;
                
                wr_req <= 1'b1;
                wr_wstb <= 8'hff;
                wr_data <= Fence_read_data; 
                if( ~Fence_counter[7] )
                    wr_addr <= { Way0_TagV[ Fence_counter[6:0] ][20:0], Fence_counter[6:0], 4'b0 };   //***
                else if( Fence_counter[7] )
                    wr_addr <= { Way1_TagV[ Fence_counter[6:0] ][20:0], Fence_counter[6:0], 4'b0 };   //***

            end
            else 
                Fence_state <= Fence_Write;
        end
    default:
        Fence_state <= Fence_Idle;
    endcase
end

//state machine transition
always @(posedge clock)begin
    if(reset)begin
        state <= IDLE;
        RB_index <= 7'd0;
        RB_tag <= 21'd0;
        RB_offset <= 1'b0;
        RB_OP <= 1'b0;
        HIT_index <= 1'b0;
        HIT_offset <= 1'b0;
        hit_way0 <= 1'b0;
        hit_way1 <= 1'b0;
        HIT_way0 <= 1'b0;
        HIT_way1 <= 1'b0;
        unshoot <= 1'b0;
        Data_OK <= 1'b0;
        ram4_CEN <= 1'b1;
        ram4_WEN <= 1'b1;
        ram4_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram4_addr <= 6'b0;
        ram4_wdata <= 128'b0;
        ram5_CEN <= 1'b1;
        ram5_WEN <= 1'b1;
        ram5_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram5_addr <= 6'b0;
        ram5_wdata <= 128'b0;
        ram6_CEN <= 1'b1;
        ram6_WEN <= 1'b1;
        ram6_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram6_addr <= 6'b0;
        ram6_wdata <= 128'b0;
        ram7_CEN <= 1'b1;
        ram7_WEN <= 1'b1;
        ram7_bwen <= 128'hffffffffffffffffffffffffffffffff;
        ram7_addr <= 6'b0;
        ram7_wdata <= 128'b0;

        rd_req <= 1'b0;
        rd_addr <= 32'b0;
        wr_req <= 1'b0;
        wr_addr <= 32'b0;
        wr_wstb <= 8'h0;
        wr_data <= 128'b0;

        Replace_cache_data <= 128'b0;

        RB_wdata <= 128'b0;
        RB_BWEN <= 128'hffffffffffffffffffffffffffffffff;
        Bus_retdata <= 128'b0;

        Way0_D <= 128'b0;
        Way1_D <= 128'b0;
    end
    else begin
    case(state)
        IDLE: 
            begin 
                Data_OK <= 1'b0;

                if(Fence_state != Fence_Write)begin
                    wr_req <= 1'b0;
                    wr_addr <= 32'b0;
                    wr_wstb <= 8'h0;
                    wr_data <= 128'b0;
                end

                if(valid & !op ) begin   // read
                    ram4_WEN <= 1'b1;  //if last cycle is write shoot but this cycle is read
                    ram5_WEN <= 1'b1;
                    ram6_WEN <= 1'b1;
                    ram7_WEN <= 1'b1;

                    RB_index <= index;  
                    RB_tag <= tag;
                    RB_offset <= offset[3];
                    RB_OP <= op;

                    if( Way0_TagV[index] == {1'b1,tag} ) begin //hit way0
                        state <= LOOKUP;
                        ram4_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram5_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram4_addr <= index[5:0];
                        ram5_addr <= index[5:0];
                        hit_way0 <= 1'b1;
                        hit_way1 <= 1'b0;
                        ram6_CEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                    end
                    else if( Way1_TagV[index] == {1'b1,tag} ) begin //hit way1
                        state <= LOOKUP;
                        ram6_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram7_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram6_addr <= index[5:0];
                        ram7_addr <= index[5:0];
                        hit_way1 <= 1'b1;
                        hit_way0 <= 1'b0;
                        ram4_CEN <= 1'b1;
                        ram5_CEN <= 1'b1;
                    end
                    else begin                      //unshoot
                        if(rd_rdy)begin             // only AXI(SRAM) ready cloud generate request
                            rd_req <= 1'b1;
                            rd_addr <= {tag,index,offset};
                        end
                        state <= MISS;
                        unshoot <= 1'b1;

                        ram5_CEN <= 1'b1;     //if last cycle write shoot but this cycle unshoot
                        ram4_CEN <= 1'b1;
                        ram6_CEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                    end
                end
                else if( valid && op) begin  //wirite
                    RB_index <= index;  
                    RB_tag <= tag;
                    RB_offset <= offset[3];
                    RB_wdata <= wdata_128;
                    RB_OP <= op;
                    RB_BWEN <= wstrb_to_bwen_128;

                    if( Way0_TagV[index] == { 1'b1,tag } ) begin //hit way0
                        state <= IDLE;

                        ram4_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram4_WEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram4_wdata <= ~index[6] ? wdata_128 : 128'b0;
                        ram4_bwen <= ~index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram4_addr <= index[5:0];

                        ram5_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram5_WEN <= index[6] ? 1'b0 : 1'b1;
                        ram5_wdata <= index[6] ? wdata_128 : 128'b0;
                        ram5_bwen <= index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram5_addr <= index[5:0];

                        Way0_D[index] <= 1'b1;
                        ram6_CEN <= 1'b1;
                        ram6_WEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                        ram7_WEN <= 1'b1;
                    end
                    else if( Way1_TagV[index] == { 1'b1,tag } ) begin //hit way1
                        state <= IDLE;

                        ram6_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram6_WEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram6_wdata <= ~index[6] ? wdata_128 : 128'b0;
                        ram6_bwen <= ~index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram6_addr <= index[5:0];

                        ram7_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram7_WEN <= index[6] ? 1'b0 : 1'b1;
                        ram7_wdata <= index[6] ? wdata_128 : 128'b0;
                        ram7_bwen <= index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram7_addr <= index[5:0];
                        
                        Way1_D[index] <= 1'b1;
                        ram4_CEN <= 1'b1;
                        ram4_WEN <= 1'b1;
                        ram5_CEN <= 1'b1;
                        ram5_WEN <= 1'b1;
                    end
                    else begin                      // unshoot
                        if(rd_rdy)begin             // only AXI(SRAM) ready cloud generate request
                            rd_req <= 1'b1;
                            rd_addr <= {tag,index,offset};
                        end
                        state <= MISS;
                        unshoot <= 1'b1;

                        ram4_CEN <= 1'b1;
                        ram4_WEN <= 1'b1;
                        ram5_CEN <= 1'b1;
                        ram5_WEN <= 1'b1;
                        ram6_CEN <= 1'b1;
                        ram6_WEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                        ram7_WEN <= 1'b1;
                    end
                end
                else begin    //if no request
                    state <= IDLE;

                    ram4_CEN <= 1'b1;                //last state maybe replace, so need stop write ram
                    ram4_WEN <= 1'b1;
                    ram4_bwen <= 128'hffffffffffffffffffffffffffffffff;
                    ram4_addr <= 6'b0;
                    ram4_wdata <= 128'b0;
                    ram5_CEN <= 1'b1;
                    ram5_WEN <= 1'b1;
                    ram5_bwen <= 128'hffffffffffffffffffffffffffffffff;
                    ram5_addr <= 6'b0;
                    ram5_wdata <= 128'b0;
                    ram6_CEN <= 1'b1;
                    ram6_WEN <= 1'b1;
                    ram6_bwen <= 128'hffffffffffffffffffffffffffffffff;
                    ram6_addr <= 6'b0;
                    ram6_wdata <= 128'b0;
                    ram7_CEN <= 1'b1;
                    ram7_WEN <= 1'b1;
                    ram7_bwen <= 128'hffffffffffffffffffffffffffffffff;
                    ram7_addr <= 6'b0;
                    ram7_wdata <= 128'b0;
                    hit_way0 <= 1'b0;
                    hit_way1 <= 1'b0;
                end
            end
        LOOKUP:                      //only hit could enter state:LOOKUP
            begin
                if( hit_way0 || hit_way1) begin
                    Data_OK <= 1'b1;
                    HIT_index <= RB_index[6];  
                    HIT_offset <= RB_offset;
                    HIT_way0 <= hit_way0;
                    HIT_way1 <= hit_way1;
                end

                if( !valid ) begin             //finish and no new request
                    state <= IDLE;
                    ram4_CEN <= 1'b1;
                    ram5_CEN <= 1'b1;
                    ram6_CEN <= 1'b1;
                    ram7_CEN <= 1'b1;
                    hit_way0 <= 1'b0;
                    hit_way1 <= 1'b0;
                end
                else if( valid & !op) begin   // read
                    RB_index <= index;  
                    RB_tag <= tag;
                    RB_offset <= offset[3];
                    if( Way0_TagV[index] == {1'b1,tag} ) begin //hit way0
                        state <= LOOKUP;
                        ram4_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram5_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram4_addr <= index[5:0];
                        ram5_addr <= index[5:0];
                        hit_way0 <= 1'b1;
                        hit_way1 <= 1'b0;
                        ram6_CEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                    end
                    else if( Way1_TagV[index] == {1'b1,tag} ) begin //hit way1
                        state <= LOOKUP;
                        ram6_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram7_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram6_addr <= index[5:0];
                        ram7_addr <= index[5:0];
                        hit_way1 <= 1'b1;
                        hit_way0 <= 1'b0;
                        ram4_CEN <= 1'b1;
                        ram5_CEN <= 1'b1;
                    end
                    else begin                      // unshoot
                        if(rd_rdy)begin             // only AXI(SRAM) ready cloud generate request
                            rd_req <= 1'b1;
                            rd_addr <= {tag,index,offset};
                        end
                        state <= MISS;
                        unshoot <= 1'b1;

                        ram5_CEN <= 1'b1;     //for read, if last cycle shoot but this cycle unshoot
                        ram4_CEN <= 1'b1;
                        ram6_CEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                        hit_way0 <= 1'b0;
                        hit_way1 <= 1'b0;
                    end
                end
                else if( valid && op ) begin  //wirite
                    hit_way0 <= 1'b0;
                    hit_way1 <= 1'b0;

                    RB_index <= index;  
                    RB_tag <= tag;
                    RB_offset <= offset[3];
                    RB_wdata <= wdata_128;
                    RB_OP <= op;
                    RB_BWEN <= wstrb_to_bwen_128;

                    if( Way0_TagV[index] == { 1'b1,tag } ) begin //hit way0
                        state <= IDLE;

                        ram4_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram4_WEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram4_wdata <= ~index[6] ? wdata_128 : 128'b0;
                        ram4_bwen <= ~index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram4_addr <= index[5:0];

                        ram5_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram5_WEN <= index[6] ? 1'b0 : 1'b1;
                        ram5_wdata <= index[6] ? wdata_128 : 128'b0;
                        ram5_bwen <= index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram5_addr <= index[5:0];

                        Way0_D[index] <= 1'b1;
                        ram6_CEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                    end
                    else if( Way1_TagV[index] == { 1'b1,tag } ) begin //hit way1
                        state <= IDLE;

                        ram6_CEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram6_WEN <= ~index[6] ? 1'b0 : 1'b1;
                        ram6_wdata <= ~index[6] ? wdata_128 : 128'b0;
                        ram6_bwen <= ~index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram6_addr <= index[5:0];

                        ram7_CEN <= index[6] ? 1'b0 : 1'b1;
                        ram7_WEN <= index[6] ? 1'b0 : 1'b1;
                        ram7_wdata <= index[6] ? wdata_128 : 128'b0;
                        ram7_bwen <= index[6] ? wstrb_to_bwen_128 : 128'b0;
                        ram7_addr <= index[5:0];
                        
                        Way1_D[index] <= 1'b1;
                        ram4_CEN <= 1'b1;
                        ram5_CEN <= 1'b1;
                    end
                    else begin                      // unshoot
                        if(rd_rdy)begin             // only AXI(SRAM) ready cloud generate request
                            rd_req <= 1'b1;
                            rd_addr <= {tag,index,offset};
                        end
                        state <= MISS;
                        unshoot <= 1'b1;

                        ram4_CEN <= 1'b1;           //for read, if last cycle read shoot but this cycle not shoot
                        ram5_CEN <= 1'b1;
                        ram6_CEN <= 1'b1;
                        ram7_CEN <= 1'b1;
                    end
                end
            end
        MISS:
            begin
                rd_req <= 1'b0;
                rd_addr <= 32'b0;
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
                Data_OK <= 1'b0;
                if( RB_index[6] && ~Way0_TagV[ RB_index ][21] )begin  //regard invalid as empty
                    state <= IDLE;
                    unshoot <= 1'b0;
                    ram5_CEN <= 1'b0;
                    ram5_WEN <= 1'b0;
                    ram5_bwen <= 128'b0;
                    ram5_addr <= RB_index[5:0];
                    ram5_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                    Way0_TagV[RB_index] <= {1'b1,RB_tag};
                    Way0_D[RB_index] <= RB_OP;
                end
                else if( !RB_index[6] && ~Way0_TagV[ RB_index ][21] )begin
                    state <= IDLE;
                    unshoot <= 1'b0;
                    ram4_CEN <= 1'b0;
                    ram4_WEN <= 1'b0;
                    ram4_bwen <= 128'b0;
                    ram4_addr <= RB_index[5:0];
                    ram4_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                    Way0_TagV[RB_index] <= {1'b1,RB_tag};
                    Way0_D[RB_index] <= RB_OP;
                end
                else if( RB_index[6] && ~Way1_TagV[ RB_index ][21] )begin
                    state <= IDLE;
                    unshoot <= 1'b0;
                    ram7_CEN <= 1'b0;
                    ram7_WEN <= 1'b0;
                    ram7_bwen <= 128'b0;
                    ram7_addr <= RB_index[5:0];
                    ram7_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                    Way1_TagV[RB_index] <= {1'b1,RB_tag};
                    Way1_D[RB_index] <= RB_OP;
                end
                else if( !RB_index[6] && ~Way1_TagV[ RB_index ][21])begin
                    state <= IDLE;
                    unshoot <= 1'b0;     
                    ram6_CEN <= 1'b0;
                    ram6_WEN <= 1'b0;
                    ram6_bwen <= 128'b0;
                    ram6_addr <= RB_index[5:0];
                    ram6_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                    Way1_TagV[RB_index] <= {1'b1,RB_tag};
                    Way1_D[RB_index] <= RB_OP;
                end
                else if( Way0_TagV[ RB_index ][21] && Way1_TagV[ RB_index ][21] ) begin   //If both full , replace way0
                    if( ~Way0_D[RB_index] ) begin      //If way_0 cache is not dirty, replace way0
                        state <= IDLE;
                        unshoot <= 1'b0;
                        if( RB_index[6] )begin  
                            ram5_CEN <= 1'b0;
                            ram5_WEN <= 1'b0;
                            ram5_bwen <= 128'b0;
                            ram5_addr <= RB_index[5:0];
                            ram5_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                            Way0_TagV[RB_index] <= {1'b1,RB_tag};
                            Way0_D[RB_index] <= RB_OP;
                        end
                        else if( !RB_index[6] )begin    
                            ram4_CEN <= 1'b0;
                            ram4_WEN <= 1'b0;
                            ram4_bwen <= 128'b0;
                            ram4_addr <= RB_index[5:0];
                            ram4_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                            Way0_TagV[RB_index] <= {1'b1,RB_tag};
                            Way0_D[RB_index] <= RB_OP;
                        end
                    end
                    else if( Way0_D[RB_index] && ~Way1_D[RB_index] )begin
                        state <= IDLE;
                        unshoot <= 1'b0;
                        if( RB_index[6]  )begin  
                            ram7_CEN <= 1'b0;
                            ram7_WEN <= 1'b0;
                            ram7_bwen <= 128'b0;
                            ram7_addr <= RB_index[5:0];
                            ram7_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                            Way1_TagV[RB_index] <= {1'b1,RB_tag};
                            Way1_D[RB_index] <= RB_OP;
                        end
                        else if( !RB_index[6] )begin
                            ram6_CEN <= 1'b0;
                            ram6_WEN <= 1'b0;
                            ram6_bwen <= 128'b0;
                            ram6_addr <= RB_index[5:0];
                            ram6_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                            Way1_TagV[RB_index] <= {1'b1,RB_tag};
                            Way1_D[RB_index] <= RB_OP;
                        end
                    end
                    else if(( Way0_D[RB_index] && Way1_D[RB_index] ))begin   //both dirty, replace way_0 , get cache data
                        state <= REWAIT;
                        ram4_CEN <= ~RB_index[6] ? 1'b0 : 1'b1;
                        ram5_CEN <= RB_index[6] ? 1'b0 : 1'b1;
                        ram4_addr <= RB_index[5:0];
                        ram5_addr <= RB_index[5:0];
                    end 
                end
            end
        REWAIT:
            begin
                if( ram4_CEN & ram5_CEN )begin
                    state <= REFILL;
                    Replace_cache_data <= RB_index[6] ? sram5_rdata : sram4_rdata;
                end
                else begin
                    state <= REWAIT; 
                    ram4_CEN <= 1'b1;
                    ram5_CEN <= 1'b1;
                end
            end
        REFILL:
            begin
                if( wr_rdy ) begin     // 向AXI 发出写请求, 同时将AXI获得的数据写回到cache中
                    //state <= IDLE;
                    //unshoot <= 1'b0;
                    state <= WAIT_WR_RESPONSE;

                    wr_req <= 1'b1;
                    wr_addr <= { Way0_TagV[ RB_index ][20:0],RB_index,4'b0 };  //***
                    wr_wstb <= 8'hff;
                    wr_data <= Replace_cache_data;

                    if( RB_index[6] )begin  
                        ram5_CEN <= 1'b0;
                        ram5_WEN <= 1'b0;
                        ram5_bwen <= 128'b0;
                        ram5_addr <= RB_index[5:0];
                        ram5_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                        Way0_TagV[RB_index] <= {1'b1,RB_tag};
                        Way0_D[RB_index] <= RB_OP;
                    end
                    else if( !RB_index[6] )begin    
                        ram4_CEN <= 1'b0;
                        ram4_WEN <= 1'b0;
                        ram4_bwen <= 128'b0;
                        ram4_addr <= RB_index[5:0];
                        ram4_wdata <= RB_OP ? ( Bus_retdata & RB_BWEN | RB_wdata & ~RB_BWEN ): Bus_retdata;
                        Way0_TagV[RB_index] <= {1'b1,RB_tag};
                        Way0_D[RB_index] <= RB_OP;
                    end
                end
                else begin
                    state <= REFILL; 
                end
            end
        WAIT_WR_RESPONSE:
            begin
                    wr_req <= 1'b0;
                    wr_addr <= 32'b0;
                    wr_wstb <= 8'h0;
                    wr_data <= 128'b0;

                    ram4_CEN <= 1'b1;                //last state maybe replace, so need stop write ram
                    ram4_WEN <= 1'b1;
                    ram4_bwen <= 128'hffffffffffffffffffffffffffffffff;
                    ram4_addr <= 6'b0;
                    ram4_wdata <= 128'b0;
                    ram5_CEN <= 1'b1;
                    ram5_WEN <= 1'b1;
                    ram5_bwen <= 128'hffffffffffffffffffffffffffffffff;
                    ram5_addr <= 6'b0;
                    ram5_wdata <= 128'b0;

                    if(wr_resp) begin
                        state <= IDLE;
                        unshoot <= 1'b0;
                    end
                    else state <= WAIT_WR_RESPONSE;
            end
        default:
            state <= IDLE;
    endcase 
    end
end

assign read_ramdata = Data_OK ? ( HIT_way0 ? ( HIT_index ? sram5_rdata : sram4_rdata ) : ( HIT_way1 ? ( HIT_index ? sram7_rdata : sram6_rdata) : 128'b0 ) ) : 128'b0;
assign rdata = Data_OK ? ( ( state == REPLACE ) ? (  RB_offset ?  Bus_retdata[127:64] : Bus_retdata[63:0] ) : ( HIT_offset ?  read_ramdata[127:64] : read_ramdata[63:0] ) ) : 64'b0;

assign data_ok = Data_OK;

assign sram4_addr = ~ram4_CEN ? ram4_addr : Fence_ram4_addr;
assign sram4_cen = ram4_CEN & Fence_ram4_CEN;
assign sram4_wen = ram4_WEN;
assign sram4_wmask = ram4_bwen;
assign sram4_wdata = ram4_wdata;

assign sram5_addr = ~ram5_CEN ? ram5_addr : Fence_ram5_addr;
assign sram5_cen = ram5_CEN & Fence_ram5_CEN;
assign sram5_wen = ram5_WEN;
assign sram5_wmask = ram5_bwen;
assign sram5_wdata = ram5_wdata;

assign sram6_addr = ~ram6_CEN ? ram6_addr : Fence_ram6_addr;
assign sram6_cen = ram6_CEN & Fence_ram6_CEN;
assign sram6_wen = ram6_WEN;
assign sram6_wmask = ram6_bwen;
assign sram6_wdata = ram6_wdata;

assign sram7_addr = ~ram7_CEN ? ram7_addr : Fence_ram7_addr;
assign sram7_cen = ram7_CEN & Fence_ram7_CEN;
assign sram7_wen = ram7_WEN;
assign sram7_wmask = ram7_bwen;
assign sram7_wdata = ram7_wdata;


wire [31:0]Dcache_state_32;
assign Dcache_state_32 = {25'b0,state};
import "DPI-C" function void get_Dcache_state_32_value(int Dcache_state_32);
always@(*) get_Dcache_state_32_value(Dcache_state_32);

wire [31:0]Dcache_AXI_ret_data;
assign Dcache_AXI_ret_data = ret_data[31:0];
import "DPI-C" function void get_Dcache_AXI_ret_data_value(int Dcache_AXI_ret_data);
always@(*) get_Dcache_AXI_ret_data_value(Dcache_AXI_ret_data);

wire [31:0]Hitway_32;
assign Hitway_32 = { 30'b0, hit_way1, hit_way0 };
import "DPI-C" function void get_Dcache_Hitway_value(int Hitway_32);
always@(*) get_Dcache_Hitway_value(Hitway_32);

wire [31:0]RB_wdata_32;
assign RB_wdata_32 = wstrb_to_bwen_128[95:64];
import "DPI-C" function void get_RB_wdata_value(int RB_wdata_32);
always@(*) get_RB_wdata_value(RB_wdata_32);

wire [31:0]Replace_cache_data_32;
assign Replace_cache_data_32 = Replace_cache_data[95:64];
import "DPI-C" function void get_Replace_cache_data_value(int Replace_cache_data_32);
always@(*) get_Replace_cache_data_value(Replace_cache_data_32);

wire [31:0]Fence_32;
assign Fence_32 = { 31'b0,fencei };
import "DPI-C" function void get_fencei_value(int Fence_32);
always@(*) get_fencei_value(Fence_32);

wire [31:0]Fence_counter_32;
assign Fence_counter_32 = { 23'b0,Fence_counter };
import "DPI-C" function void get_Fence_counter_32_value(int Fence_counter_32);
always@(*) get_Fence_counter_32_value(Fence_counter_32);

wire [31:0]Fence_state_32;
assign Fence_state_32 = { 24'b0,Fence_ram4_CEN,Fence_ram5_CEN,Fence_ram6_CEN,Fence_ram7_CEN,Fence_state };
import "DPI-C" function void get_Fence_state_32_value(int Fence_state_32);
always@(*) get_Fence_state_32_value(Fence_state_32);

endmodule
