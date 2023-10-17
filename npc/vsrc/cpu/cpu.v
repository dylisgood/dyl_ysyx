`timescale 1ns/1ps
module ysyx_22050854_cpu(
    input rst,
    input clk,
    output timer_interrupt,

    input io_master_awready,
    output  io_master_awvalid, 
    output [3:0] io_master_awid, 
    output [31:0] io_master_awaddr, 
    output [7:0] io_master_awlen,
    output [2:0] io_master_awsize,
    output [1:0] io_master_awburst,

    input io_master_wready,
    output  io_master_wvalid,
    output [63:0] io_master_wdata,
    output [7:0] io_master_wstrb,
    output  io_master_wlast,

    output  io_master_bready,
    input  io_master_bvalid,
    input [3:0] io_master_bid,
    input [1:0] io_master_bresp,

    input  io_master_arready,
    output  io_master_arvalid,
    output [3:0] io_master_arid,
    output [31:0] io_master_araddr,
    output [7:0] io_master_arlen,
    output [2:0] io_master_arsize,
    output [1:0] io_master_arburst,

    output  io_master_rready,
    input  io_master_rvalid,
    input [3:0] io_master_rid,
    input [63:0] io_master_rdata,
    input [1:0] io_master_rresp,
    input  io_master_rlast,

    output io_slave_awready,
    input  io_slave_awvalid, 
    input [3:0] io_slave_awid, 
    input [31:0] io_slave_awaddr, 
    input [7:0] io_slave_awlen,
    input [2:0] io_slave_awsize,
    input [1:0] io_slave_awburst,

    output io_slave_wready,
    input  io_slave_wvalid,
    input [63:0] io_slave_wdata,
    input [7:0] io_slave_wstrb,
    input  io_slave_wlast,

    input  io_slave_bready,
    output  io_slave_bvalid,
    output [3:0] io_slave_bid,
    output [1:0] io_slave_bresp,

    output  io_slave_arready,
    input  io_slave_arvalid,
    input [3:0] io_slave_arid,
    input [31:0] io_slave_araddr,
    input [7:0] io_slave_arlen,
    input [2:0] io_slave_arsize,
    input [1:0] io_slave_arburst,

    input  io_slave_rready,
    output  io_slave_rvalid,
    output [3:0] io_slave_rid,
    output [63:0] io_slave_rdata,
    output [1:0] io_slave_rresp,
    output  io_slave_rlast,

    output [5:0] cpu_io_sram0_addr,
    output  cpu_io_sram0_cen,
    output  cpu_io_sram0_wen,
    output [127:0] cpu_io_sram0_wmask,
    output [127:0] cpu_io_sram0_wdata,
    input [127:0] cpu_io_sram0_rdata,
    output [5:0] cpu_io_sram1_addr,
    output  cpu_io_sram1_cen,
    output  cpu_io_sram1_wen,
    output [127:0] cpu_io_sram1_wmask,
    output [127:0] cpu_io_sram1_wdata,
    input [127:0] cpu_io_sram1_rdata,
    output [5:0] cpu_io_sram2_addr,
    output  cpu_io_sram2_cen,
    output  cpu_io_sram2_wen,
    output [127:0] cpu_io_sram2_wmask,
    output [127:0] cpu_io_sram2_wdata,
    input [127:0] cpu_io_sram2_rdata,
    output [5:0] cpu_io_sram3_addr,
    output  cpu_io_sram3_cen,
    output  cpu_io_sram3_wen,
    output [127:0] cpu_io_sram3_wmask,
    output [127:0] cpu_io_sram3_wdata,
    input [127:0] cpu_io_sram3_rdata,
    output [5:0] cpu_io_sram4_addr,
    output  cpu_io_sram4_cen,
    output  cpu_io_sram4_wen,
    output [127:0] cpu_io_sram4_wmask,
    output [127:0] cpu_io_sram4_wdata,
    input [127:0] cpu_io_sram4_rdata,
    output [5:0] cpu_io_sram5_addr,
    output  cpu_io_sram5_cen,
    output  cpu_io_sram5_wen,
    output [127:0] cpu_io_sram5_wmask,
    output [127:0] cpu_io_sram5_wdata,
    input [127:0] cpu_io_sram5_rdata,
    output [5:0] cpu_io_sram6_addr,
    output  cpu_io_sram6_cen,
    output  cpu_io_sram6_wen,
    output [127:0] cpu_io_sram6_wmask,
    output [127:0] cpu_io_sram6_wdata,
    input [127:0] cpu_io_sram6_rdata,
    output [5:0] cpu_io_sram7_addr,
    output  cpu_io_sram7_cen,
    output  cpu_io_sram7_wen,
    output [127:0] cpu_io_sram7_wmask,
    output [127:0] cpu_io_sram7_wdata,
    input [127:0] cpu_io_sram7_rdata
);   
    wire rst_n;
    assign rst_n = ~rst;

    //------------------- IFU -------------------//
    //当IFU取消暂停时，已经将取到的指令放到IDreg了
    reg [31:0]pc_test;
    always @(posedge clk)begin
        if(rst)
            pc_test <= 32'h80000000;
        else if( jump | Data_Conflict_block | last_JumpAndDataBlock ) //如果是跳转指令或遇到了数据冲突 或同时遇到
            pc_test <= next_pc + 32'd4;
        else if( last_Suspend_LSU & ~Suspend_LSU )begin
            pc_test <= EXEreg_pc + 32'd8;
        end
        else if ( last_Suspend_IFU & !Suspend_IFU & ~Last_Jump_Suspend & ~Last_ALUsuspend_IFUsuspend & ~Last_DataBlock_Suspend & ~Last_JumpAndBlock_Suspend )begin
            pc_test <= next_pc + 32'd4;
        end
        else if( ~jump & Last_Jump_Suspend & ~Suspend_IFU)begin
            pc_test <= PC_Jump_Suspend + 32'd4;
            Last_Jump_Suspend <= 1'b0;
        end
        else if( ~Data_Conflict_block & Last_DataBlock_Suspend & ~Suspend_IFU)begin
            pc_test <= PC_DataBlock_Suspend + 32'd4;
            Last_DataBlock_Suspend <= 1'b0;
        end
        else if( ~last_JumpAndDataBlock & Last_JumpAndBlock_Suspend & ~Suspend_IFU)begin
            pc_test <= PC_JumpAndBlock_Suspend + 32'd4;
            Last_JumpAndBlock_Suspend <= 1'b0;
        end
        else if( last_Suspend_ALU & ~Suspend_ALU & ~Suspend_IFU )begin  //ALU暂停结束时，IFU已经暂停结束
            pc_test <= EXEreg_pc + 32'd8;
            Last_ALUsuspend_IFUsuspend <= 1'b0;   //***
        end
        else if( Last_ALUsuspend_IFUsuspend & ~Suspend_IFU)begin  //ALU暂停结束时，IFU还没暂停结束
            pc_test <= PC_ALUsuspend_IFUsuspend + 32'd4;
            Last_ALUsuspend_IFUsuspend <= 1'b0;
        end
        else if(!Suspend_IFU)
            pc_test <= pc_test + 32'd4;
    end

    //如果译码阶段发现是jump 但不阻塞 则可根据next_pc取指 
    //如果译码阶段发现阻塞 但不是jump 则可根据next_pc取指 因为pc_test早两拍 
    //如果译码阶段发现既是jump又是阻塞，则不能取指，因为阻塞产生的jump并不准确 (取指的有效信号为0)
    //如果上周期既是jump又是阻塞，则可以取指，因为本周期能计算出是否真正jump (arvalid_n_t)
    //如果ALU发起了暂停，则下周期不取指，直到暂停取消 (暂停时取指有效信号为0，如果上周期暂停，而这周期不暂停，则用next_pc取指)
    //如果IFU发起暂停，然后暂停取消后，指令已经放到了IDreg，根据译码出来的next_pc取指即可
    //如果在译码阶段发现是jump且此时IFU发起了暂停，则需要记录正确的PC，并在IFU的暂停结束后重新取指
    //如果在译码阶段发现是 单纯的数据阻塞，且此时IFU发起了暂停，则没关系，直接等取回来就好
    //如果在译码阶段发现是 跳转的数据阻塞 则会等待一周期，之后判断是否为跳转 在等待的这一阶段不会发生取指 
    //如果在执行阶段需要暂停，且此时IFU发起了暂停，而
    reg [31:0]pc_real;
    always @(*)begin
        if(rst)
            pc_real = 32'h80000000;
        else if( jump | Data_Conflict_block | last_JumpAndDataBlock )
            pc_real = next_pc;
        else if( last_Suspend_LSU & ~Suspend_LSU )
            pc_real = EXEreg_pc + 32'd4;
        else if( last_Suspend_IFU & !Suspend_IFU & ~Last_Jump_Suspend & ~Last_ALUsuspend_IFUsuspend & ~Last_DataBlock_Suspend & ~Last_JumpAndBlock_Suspend ) //当SuspendLSU为0时，指令刚好进入IDreg
            pc_real = next_pc;
        else if( ~jump & Last_Jump_Suspend & ~Suspend_IFU)
            pc_real = PC_Jump_Suspend;
        else if( ~Data_Conflict_block & Last_DataBlock_Suspend & ~Suspend_IFU)
            pc_real = PC_DataBlock_Suspend;
        else if( ~last_JumpAndDataBlock & Last_JumpAndBlock_Suspend & ~Suspend_IFU)
            pc_real = PC_JumpAndBlock_Suspend;
        else if( last_Suspend_ALU & ~Suspend_ALU )  //因为是在EXE发起暂停，而此时ID已经取得一条指令，这条指令的pc就是暂停结束后，要重新取的pc
            pc_real = EXEreg_pc + 32'd4;
        else if( Last_ALUsuspend_IFUsuspend & ~Suspend_IFU)
            pc_real = PC_ALUsuspend_IFUsuspend;
        else
            pc_real = pc_test; 
    end

wire [31:0]test_one;
assign test_one = { 28'b0,Last_ALUsuspend_IFUsuspend    ,Last_Jump_Suspend   ,Last_DataBlock_Suspend    ,Last_JumpAndBlock_Suspend };

//如果发现jump的时候 IFU没有命中 那么原先的置后两个周期的指令无效不起作用
//需要等到IFU取到指令无效（具体周期不确定），定义以下寄存器来确定
    reg [31:0]PC_Jump_Suspend;
    reg Last_Jump_Suspend;
    always @(posedge clk)begin
        if(rst)
        begin
            Last_Jump_Suspend <= 1'b0;
            PC_Jump_Suspend <= 32'h80000000;
        end
        else if(jump & Suspend_IFU & ~last_JumpAndDataBlock)begin
            Last_Jump_Suspend <= 1'b1;
            PC_Jump_Suspend  <= next_pc;
        end
    end
    
//如果发现Datablock的时候 且该指令的第二个指令IFU没有命中 那么原先的置后两个周期的指令无效不起作用 且会损失一个指令
//需要等到IFU取到指令无效（具体周期不确定），定义以下寄存器来确定
    reg [31:0]PC_DataBlock_Suspend;
    reg Last_DataBlock_Suspend;
    always @(posedge clk)begin
        if(rst)
        begin
            Last_DataBlock_Suspend <= 1'b0;
            PC_DataBlock_Suspend <= 32'h80000000;
        end
        else if(Data_Conflict_block & ~JumpAndDataBlock & Suspend_IFU )begin
            Last_DataBlock_Suspend <= 1'b1;
            PC_DataBlock_Suspend  <= next_pc;
        end
    end

//如果发现Datablock并且是跳转指令时，当前周期不保存，等下一周期不冲突后，再保存正确的跳转地址
//并且当前周期不存在于DataBlock中，下一周期也不存在于jump中，保证标记的唯一性
    reg [31:0]PC_JumpAndBlock_Suspend;
    reg Last_JumpAndBlock_Suspend;
    always @(posedge clk)begin
        if(rst)
        begin
            Last_JumpAndBlock_Suspend <= 1'b0;
            PC_JumpAndBlock_Suspend <= 32'h80000000;
        end
        else if(last_JumpAndDataBlock & Suspend_IFU)begin
            Last_JumpAndBlock_Suspend <= 1'b1;
            PC_JumpAndBlock_Suspend  <= next_pc;
        end
    end

//如果ALU发起暂停的时候 IFU没有命中,正在寻找，而在ALU结束暂停之后，IFU取到指令，那么这个指令应当无效,当之前的逻辑只是ALU暂停时无效
//应该记录下来ALU暂停且IFU也暂停时的指令，等到IFU结束暂停之后，用这个指令取指
    reg [31:0]PC_ALUsuspend_IFUsuspend;
    reg Last_ALUsuspend_IFUsuspend;
    always @(posedge clk)begin
        if(rst)
        begin
            Last_ALUsuspend_IFUsuspend <= 1'b0;
            PC_ALUsuspend_IFUsuspend <= 32'h80000000;
        end
        else if(Suspend_ALU & Suspend_IFU)begin
            Last_ALUsuspend_IFUsuspend <= 1'b1;
            PC_ALUsuspend_IFUsuspend  <= EXEreg_pc + 32'd4;
            if(Last_DataBlock_Suspend)
                Last_DataBlock_Suspend <= 1'b0;     //***
        end
    end

    reg [31:0]pc_record_1;
    reg [31:0]pc_record_2;
    always@(posedge clk)begin
        if(rst)
            pc_record_1 <= 32'b0;
        else 
            pc_record_1 <= pc_real; 
    end
    always@(posedge clk)begin
        if(rst)
            pc_record_2 <= 32'b0;
        else if( Icache_addr_ok )
            pc_record_2 <= pc_record_1;
    end

    //如果当前周期下是jalr 或者 beq指令 且发生了阻塞，则无法产生正确的next_pc,本周期不取指
    wire JumpAndDataBlock;
    assign JumpAndDataBlock = ( ( ID_reg_inst[6:0] == 7'b1100011) | (ID_reg_inst[6:0]) == 7'b1100111) & Data_Conflict_block;

    reg last_JumpAndDataBlock;
    ysyx_22050854_Reg #(1,1'b0) jumpandblock (clk, rst, JumpAndDataBlock, last_JumpAndDataBlock, 1'b1);
    reg last_Suspend_ALU;
    ysyx_22050854_Reg #(1,1'b0) record_lastSuspend (clk, rst, Suspend_ALU, last_Suspend_ALU, 1'b1);
    reg last_Suspend_IFU;
    ysyx_22050854_Reg #(1,1'b0) record_last_Suspend_IFU (clk, rst, Suspend_IFU, last_Suspend_IFU, 1'b1);
    reg last_Suspend_LSU;
    ysyx_22050854_Reg #(1,1'b0) record_last_Suspend_LSU (clk, rst, Suspend_LSU, last_Suspend_LSU, 1'b1);

    wire Icache_valid;
    assign Icache_valid = ~JumpAndDataBlock & ~Suspend_ALU & ~Suspend_IFU & ~Suspend_LSU;         // 如果遇到阻塞且有条件跳转指令，或遇到ALU/IFU暂停，不取指
    wire [6:0]Icache_index;
    wire [20:0]Icache_tag;
    wire [3:0]Icache_offset;
    assign Icache_offset = pc_real[3:0];
    assign Icache_tag = pc_real[31:11];
    assign Icache_index = pc_real[10:4];
    wire Icache_addr_ok;
    wire Icache_data_ok;
    wire [63:0]Icache_ret_data;
    wire Suspend_IFU;

    wire AXI_Icache_rd_req;
    wire [2:0]AXI_Icache_rd_type;
    wire [31:0]AXI_Icache_rd_addr;
    wire AXI_Icache_ret_valid;
    wire AXI_Icache_ret_last;
    wire [63:0]AXI_Icache_ret_data;
    assign AXI_Icache_ret_valid = ( io_master_rresp  == 2'b10 ) && ( io_master_rid == 4'b0001 );
    assign AXI_Icache_ret_last = io_master_rlast;
    assign AXI_Icache_ret_data = io_master_rdata;
    ysyx_22050854_Icache icache_inst(
        .clk(clk),
        .rst(rst),
        .valid(Icache_valid),
        .op(1'b0), 
        .index(Icache_index),
        .tag(Icache_tag), 
        .offset(Icache_offset), 
        .addr_ok(Icache_addr_ok), 
        .data_ok(Icache_data_ok),
        .rdata(Icache_ret_data),
        .unshoot(Suspend_IFU),
        //with AXI4
        .rd_req(AXI_Icache_rd_req), 
        .rd_type(AXI_Icache_rd_type),
        .rd_addr(AXI_Icache_rd_addr),
        .rd_rdy(1'b1),
        .ret_valid(AXI_Icache_ret_valid),
        .ret_last(AXI_Icache_ret_last),
        .ret_data(AXI_Icache_ret_data),

        .sram0_addr(cpu_io_sram0_addr),
        .sram0_cen(cpu_io_sram0_cen),
        .sram0_wen(cpu_io_sram0_wen),
        .sram0_wmask(cpu_io_sram0_wmask),
        .sram0_wdata(cpu_io_sram0_wdata),
        .sram0_rdata(cpu_io_sram0_rdata),

        .sram1_addr(cpu_io_sram1_addr),
        .sram1_cen(cpu_io_sram1_cen),
        .sram1_wen(cpu_io_sram1_wen),
        .sram1_wmask(cpu_io_sram1_wmask),
        .sram1_wdata(cpu_io_sram1_wdata),
        .sram1_rdata(cpu_io_sram1_rdata),

        .sram2_addr(cpu_io_sram2_addr),
        .sram2_cen(cpu_io_sram2_cen),
        .sram2_wen(cpu_io_sram2_wen),
        .sram2_wmask(cpu_io_sram2_wmask),
        .sram2_wdata(cpu_io_sram2_wdata),
        .sram2_rdata(cpu_io_sram2_rdata),

        .sram3_addr(cpu_io_sram3_addr),
        .sram3_cen(cpu_io_sram3_cen),
        .sram3_wen(cpu_io_sram3_wen),
        .sram3_wmask(cpu_io_sram3_wmask),
        .sram3_wdata(cpu_io_sram3_wdata),
        .sram3_rdata(cpu_io_sram3_rdata)
    );

/*     wire AXI_arready;
    wire AXI_rvalid;
    ysyx_22050854_AXI_ISRAM cache_sram (
        .clk(clk),
        .rst_n(rst_n),

        .araddr(AXI_Icache_rd_addr),
        .arvalid(AXI_Icache_rd_req),
        .arready(AXI_arready),
        .arlen(1'b0),
        .arsize(1'b0),
        .arburst(2'b00),

        .rdata(AXI_Icache_ret_data),
        .rresp(AXI_Icache_rd_valid),
        .rvalid(AXI_rvalid),
        .rlast(AXI_Icache_ret_last),
        .rready(1'b1)
    ); */

    reg [31:0]inst;
    wire [63:0]inst_64;
    assign inst_64 = (Icache_data_ok == 1'b1) ? Icache_ret_data : 64'h6666666666666666;
    always @(*)begin
        if(Icache_data_ok)  begin//如果是刚取到指令
            inst = ( pc_record_2[2:0] == 3'b000 ) ? inst_64[31:0] : inst_64[63:32]; 
        end
        else
            inst = 32'd0;
    end

    import "DPI-C" function void get_next_pc_value(int next_pc);
    always@(*) get_next_pc_value(next_pc);
    import "DPI-C" function void get_pc_value(int pc_real);
    always@(*) get_pc_value(pc_real);
    import "DPI-C" function void get_inst_value(int inst);
    always@(*) get_inst_value(inst);
    import "DPI-C" function void get_PC_JUMP_Suspend_value(int test_one);
    always@(*) get_PC_JUMP_Suspend_value(test_one);


    //---------------------------------------------                      ID_reg                             -----------------------------------------//
    reg ID_reg_valid;
    reg ID_reg_inst_enable;
    reg [31:0]ID_reg_inst;
    reg ID_reg_pc_enable;
    reg [31:0]ID_reg_pc;
    always@(*)begin
        ID_reg_inst_enable = Icache_data_ok & (~Data_Conflict_block) & ~Suspend_ALU; //如果更新前发现需要阻塞，就不更新了 如果ALU发起了暂停，IDreg也应该保持不变
        ID_reg_pc_enable = Icache_data_ok & (~Data_Conflict_block) & ~Suspend_ALU;
    end
    always@(posedge clk)begin
        if(rst)
            ID_reg_valid <= 1'b0;
        else
            ID_reg_valid <=  ( Icache_data_ok & (~jump) & (~EXEreg_jump) & (~EXEreg_Datablock) & (~Suspend_ALU) & (~Last_Jump_Suspend) & (~Last_DataBlock_Suspend) & (~Last_ALUsuspend_IFUsuspend) & (~Last_JumpAndBlock_Suspend) & ~Suspend_LSU ) | Data_Conflict_block;
    end                                                                                                          
    //当取到跳转的跳转指令时，下个上升沿以及下下个上升沿都不能将指令送到IDreg中，而是将指令置为0，空走两个始终周期
    wire [31:0]pc_record;
    assign pc_record = jump ? next_pc : pc_record_2;
    ysyx_22050854_Reg #(32,32'b0) IDreg_gen0 (clk, (rst | jump | EXEreg_jump | EXEreg_Datablock), inst, ID_reg_inst, ID_reg_inst_enable);
    ysyx_22050854_Reg #(32,32'h80000000) IDreg_gen1 (clk, rst, pc_record, ID_reg_pc, ID_reg_pc_enable);

    wire [31:0]ID_reg_valid_32;
    assign ID_reg_valid_32 = {31'b0,ID_reg_valid};
    import "DPI-C" function void get_ID_reg_valid_value(int ID_reg_valid_32);
    always@(*) get_ID_reg_valid_value(ID_reg_valid_32);
    import "DPI-C" function void get_IDreginst_value(int ID_reg_inst);
    always@(*) get_IDreginst_value(ID_reg_inst);

    //Suspend_IFU
    wire [31:0]Suspend_IFU_32;
    assign Suspend_IFU_32 = { 31'b0 , Suspend_IFU };
    import "DPI-C" function void get_Suspend_IFU_value(int Suspend_IFU_32);
    always@(*) get_Suspend_IFU_value( Suspend_IFU_32 );

    wire [31:0]IFU_valid_32;
    assign IFU_valid_32 = { 31'b0 , Icache_valid };
    import "DPI-C" function void get_IFU_valid_value(int IFU_valid_32);
    always@(*) get_IFU_valid_value( IFU_valid_32 );

    import "DPI-C" function void get_IDregpc_value(int ID_reg_pc);
    always@(*) get_IDregpc_value(ID_reg_pc);

    //----------------------------------          ID           -----------------------//
    wire [4:0]rs1,rs2;
    wire [4:0]rd;
    wire [2:0]ExtOP;
    wire RegWr;
    wire [2:0]Branch;
    wire No_branch;
    wire MemtoReg;
    wire MemWr;
    wire MemRd;
    wire [2:0]MemOP;
    wire ALUsrc1;
    wire [1:0]ALUsrc2;
    wire [3:0]ALUctr;
    wire [2:0]ALUext;
    wire [3:0]MULctr;
    ysyx_22050854_IDU instr_decode(
        .instr(ID_reg_inst),
        .rs1(rs1),                          
        .rs2(rs2),
        .rd(rd),
        .ExtOP(ExtOP),
        .RegWr(RegWr),
        .Branch(Branch),
        .No_branch(No_branch),
        .MemtoReg(MemtoReg),
        .MemWr(MemWr),
        .MemRd(MemRd),
        .MemOP(MemOP),
        .ALUsrc1(ALUsrc1),
        .ALUsrc2(ALUsrc2),
        .ALUctr(ALUctr),
        .ALUext(ALUext),
        .MULctr(MULctr)     
    );   

    wire ID_MUL_t;
    wire ID_MUL;
    ysyx_22050854_MuxKey #(13,4,1) gem_MUL_T (ID_MUL_t,MULctr,{
        4'b1001,1'b1,  //mul
        4'b0001,1'b1,  //mulh
        4'b0010,1'b1,  //mulhsu
        4'b0011,1'b1,  //mulhu
        4'b0100,1'b1,  //div
        4'b0101,1'b1,  //divu
        4'b0110,1'b1,  //rem
        4'b0111,1'b1,  //remu
        4'b1000,1'b1,  //mulw
        4'b1100,1'b1,  //divw
        4'b1101,1'b1,  //divuw
        4'b1110,1'b1,  //remw
        4'b1111,1'b1  //remuw       
    });
    assign ID_MUL = ID_MUL_t & ID_reg_valid;

    wire [63:0]imm;
    ysyx_22050854_imm_gen gen_imm(
    .instr(ID_reg_inst),
    .ExtOP(ExtOP),
    .imm(imm)
);

    wire [63:0]src1;
    wire [63:0]src2;
    wire [63:0]x10;
    ysyx_22050854_RegisterFile regfile_inst(
    .clk(clk),
    .wdata(wr_reg_data),
    .waddr(WBreg_rd),
    .wen(WBreg_regwr & WBreg_valid),
    .raddra(rs1),
    .raddrb(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .test_addr1(),
    .test_addr2(5'd10),
    .test_rdata1(),
    .test_rdata2(x10)    
    );

    wire [63:0]alu_src1;
    wire [63:0]alu_src2;
    ysyx_22050854_src_gen gen_src(
        .ALUsrc1(ALUsrc1),
        .ALUsrc2(ALUsrc2),
        .pc(ID_reg_pc),
        .imm(imm),
        .src1(New_src1),
        .src2(New_src2),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2)
    );

    //-------  CSR 相关 ------------//
    //CSR 读控制字
    wire CSRrd;
    assign CSRrd = ( ID_reg_inst[6:0] == 7'b1110011 ) ? (ID_reg_inst == 32'h100073 ? 1'b0 : 1'b1) : 1'b0; //ebreak not read
    //CSR 读寄存器地址
    wire [11:0]csr_raddr;
    assign csr_raddr = (ID_reg_inst == 32'h73) ? 12'h305 : (ID_reg_inst == 32'h30200073 ? 12'h341 : ID_reg_inst[31:20]); //ecall-mtvec(305) mret-mepc(341)

    //CSR 写控制字
    wire CSRwr;
    wire CSRwr2;
    wire CSRwr_t;
    ysyx_22050854_MuxKey #(6,10,1) csrwr_t_gen (CSRwr_t, {ID_reg_inst[14:12],ID_reg_inst[6:0]}, {
        10'b0011110011,1'b1,
        10'b0101110011,1'b1,
        10'b0111110011,1'b1,
        10'b1011110011,1'b1,
        10'b1101110011,1'b1,
        10'b1111110011,1'b1
    });
    assign CSRwr = ( ID_reg_inst == 32'h73 ) ? 1'b1 : CSRwr_t; //mret and ebreak not write
    assign CSRwr2 = ( ID_reg_inst == 32'h73 ) ? 1'b1 : 1'b0;   //only ecall need to write two csr
    //CSR   写地址
    wire [11:0]csr_waddr1,csr_waddr2;
    assign csr_waddr1 = ( ID_reg_inst == 32'h73 ) ? 12'h341 : ID_reg_inst[31:20]; //if ecall, mepc
    assign csr_waddr2 = ( ID_reg_inst == 32'h73 ) ? 12'h342 : ID_reg_inst[31:20]; //if ecall, mcause
    //写数据
    wire [63:0]csr_wdata1,csr_wdata2;
    wire [63:0]csrwdata_t;
    ysyx_22050854_MuxKey #(6,10,64) csrwdata_gen (csrwdata_t, {ID_reg_inst[14:12],ID_reg_inst[6:0]}, {
        10'b0011110011, New_src1,
        10'b0101110011, csr_rdata | New_src1,
        10'b0111110011, csr_rdata & ~New_src1,
        10'b1011110011, {59'd0,ID_reg_inst[19:15]},
        10'b1101110011, csr_rdata | {59'd0,ID_reg_inst[19:15]},
        10'b1111110011, csr_rdata & ~{59'd0,ID_reg_inst[19:15]}
    });
    assign csr_wdata1 = ( ID_reg_inst == 32'h73 ) ? ( { 32'd0, ID_reg_pc } + 64'd4 ) : csrwdata_t; //ecall->mepc
    assign csr_wdata2 = ( ID_reg_inst == 32'h73 ) ? New_src2 : 64'h0;  //ecall->mcause

    wire [63:0]csr_rdata;
    ysyx_22050854_CSRegister CSRfile_inst (
    .clk(clk),
    .rst(rst),
    .waddr1(csr_waddr1),
    .waddr2(csr_waddr2),
    .wdata1(csr_wdata1),
    .wdata2(csr_wdata2),
    .wen(CSRwr),
    .wen2(CSRwr2),
    .ren(CSRrd),
    .raddr(csr_raddr),
    .rdata(csr_rdata),
    .timer_interrupt(timer_interrupt)
    );
    
    wire CSR_gprRd;
    ysyx_22050854_MuxKey #(3,10,1) CSR_gprRd_gen (CSR_gprRd, {ID_reg_inst[14:12],ID_reg_inst[6:0]}, {
        10'b0011110011, 1'b1,
        10'b0101110011, 1'b1,
        10'b0111110011, 1'b1
    });

    //-------------------       判断数据冲突       --------------------------------//
    wire rs1_conflict_EXE;
    wire rs2_conflict_EXE;
    wire reg_Conflict_EXE;
    wire store_conflict_EXE; //还有一种冲突是当store指令的源操作数(要写入内存的数据)与之前指令的目的寄存器重合时（如ld 之后 sd / add 之后 sd）
    wire ret_conflict_EXE;
    assign rs1_conflict_EXE = (( ALUsrc1 == 1'b0 ) & ( rs1 == EXEreg_Rd ) & ( EXEreg_Rd != 0)); //当且仅当alu操作数是寄存器，且前一条指令要写回， 且写回地址不是x0时 ,rd = rs 才冲突
    assign rs2_conflict_EXE = (( ALUsrc2 == 2'b00 ) & ( rs2 == EXEreg_Rd) & ( EXEreg_Rd != 0));
    assign reg_Conflict_EXE = ID_reg_valid & EXEreg_valid & EXEreg_regWr  & ( rs1_conflict_EXE | rs2_conflict_EXE ); //与前一条指令冲突
    assign store_conflict_EXE = ID_reg_valid & MemWr & (rs2 == EXEreg_Rd) & (EXEreg_Rd != 0) & (EXEreg_valid) & (EXEreg_regWr);
    assign ret_conflict_EXE = ID_reg_valid & (ID_reg_inst[6:0] == 7'b1100111) & (rs1 == EXEreg_Rd) & EXEreg_regWr & EXEreg_valid & (EXEreg_Rd != 0);

    wire rs1_conflict_MEM;
    wire rs2_conflict_MEM;
    wire reg_Conflict_MEM;
    wire store_conflict_MEM;
    wire ret_conflict_MEM;
    assign rs1_conflict_MEM = (( ALUsrc1 == 1'b0 ) & ( rs1 == MEMreg_rd) & (MEMreg_rd != 0));
    assign rs2_conflict_MEM = (( ALUsrc2 == 2'b00) & ( rs2 == MEMreg_rd) & (MEMreg_rd != 0));
    assign reg_Conflict_MEM = ID_reg_valid & MEMreg_valid & MEMreg_regwr & (rs1_conflict_MEM | rs2_conflict_MEM); //与前两条指令冲突
    assign store_conflict_MEM = ID_reg_valid & MemWr & (rs2 == MEMreg_rd) & (MEMreg_rd != 0) & (MEMreg_valid) & (MEMreg_regwr);
    assign ret_conflict_MEM = ID_reg_valid & (ID_reg_inst[6:0] == 7'b1100111) & (rs1 == MEMreg_rd) & MEMreg_regwr & MEMreg_valid & (MEMreg_rd != 0);

    wire rs1_conflict_WB;
    wire rs2_conflict_WB;
    wire ret_conflict_WB;
    wire reg_Conflict_WB;
    wire store_conflict_WB;
    wire ret_conflict_WB;
    //按理说内存数据冲突 应该不会发生在这，因为发现冲突后的上升沿就写回数据了，而此时当前指令刚发起访问请求
    assign rs1_conflict_WB = (( ALUsrc1 == 1'b0 ) & (rs1 == WBreg_rd) & (WBreg_rd != 0));
    assign rs2_conflict_WB = (( ALUsrc2 == 2'b00) & (rs2 == WBreg_rd) & (WBreg_rd != 0));
    assign reg_Conflict_WB = ID_reg_valid & WBreg_valid & WBreg_regwr & ( rs1_conflict_WB | rs2_conflict_WB);   //与前三条指令冲突
    assign store_conflict_WB = ID_reg_valid & MemWr & (rs2 == WBreg_rd) & (WBreg_rd != 0) & (WBreg_valid) & (WBreg_regwr);
    assign ret_conflict_WB = ID_reg_valid & (ID_reg_inst[6:0] == 7'b1100111) & (rs1 == WBreg_rd) & WBreg_regwr & WBreg_valid & (WBreg_rd != 0);

    wire CSRsrc1_conflict_EXE;
    wire CSRsrc1_conflict_MEM;
    wire CSRsrc1_conflict_WB;
    assign CSRsrc1_conflict_EXE = ID_reg_valid & CSR_gprRd & (rs1 == EXEreg_Rd) & ( EXEreg_Rd != 0 ) & (EXEreg_valid) & (EXEreg_regWr);
    assign CSRsrc1_conflict_MEM = ID_reg_valid & CSR_gprRd & (rs1 == MEMreg_rd) & ( MEMreg_rd != 0 ) & MEMreg_valid & MEMreg_regwr;
    assign CSRsrc1_conflict_WB = ID_reg_valid & CSR_gprRd & (rs1 == WBreg_rd) & ( WBreg_rd != 0) & WBreg_valid & WBreg_regwr;
    //only ecall use src2
    wire CSRsrc2_conflict_EXE;
    wire CSRsrc2_conflict_MEM;
    wire CSRsrc2_conflict_WB;
    assign CSRsrc2_conflict_EXE = ID_reg_valid & ( ID_reg_inst == 32'h73 ) & (rs2 == EXEreg_Rd) & (EXEreg_valid) & (EXEreg_regWr);
    assign CSRsrc2_conflict_MEM = ID_reg_valid & ( ID_reg_inst == 32'h73 ) & (rs2 == MEMreg_rd) & (MEMreg_valid) & (MEMreg_regwr);
    assign CSRsrc2_conflict_WB = ID_reg_valid & ( ID_reg_inst == 32'h73 ) & (rs2 == WBreg_rd) & WBreg_valid & WBreg_regwr;
    wire CSRsrc_confilct_EXE;
    assign CSRsrc_confilct_EXE = CSRsrc1_conflict_EXE | CSRsrc2_conflict_EXE;

    wire reg_Conflict;
    assign reg_Conflict = reg_Conflict_EXE | reg_Conflict_MEM | reg_Conflict_WB;

    //需要阻塞的情况
    wire Data_Conflict_block;
    assign Data_Conflict_block = ( reg_Conflict_EXE | store_conflict_EXE | ret_conflict_EXE | CSRsrc_confilct_EXE ) & EXEreg_memRd & ~Suspend_LSU; //目前是只有上一条指令是load的情况才需要阻塞
/*     wire PC_nojump;
    assign PC_nojump = ( reg_Conflict_EXE | store_conflict_EXE | ret_conflict_EXE | CSRsrc_confilct_EXE ) & EXEreg_memRd; */

    wire [31:0]Data_Conflict_32;
    assign Data_Conflict_32 = {22'b0,ret_conflict_EXE,ret_conflict_MEM,ret_conflict_WB,store_conflict_EXE,store_conflict_MEM,store_conflict_WB,reg_Conflict_WB,reg_Conflict_MEM,reg_Conflict_EXE,Data_Conflict_block};
    import "DPI-C" function void get_Data_Conflict_value(int Data_Conflict_32);
    always@(*) get_Data_Conflict_value(Data_Conflict_32);


    wire src1_conflict_EXE;
    wire src1_conflict_MEM;
    wire src1_conflict_WB;
    assign src1_conflict_EXE = ( reg_Conflict_EXE & rs1_conflict_EXE ) | ret_conflict_EXE | CSRsrc1_conflict_EXE;
    assign src1_conflict_MEM = ( reg_Conflict_MEM & rs1_conflict_MEM ) | ret_conflict_MEM | CSRsrc1_conflict_MEM;
    assign src1_conflict_WB = ( reg_Conflict_WB & rs1_conflict_WB ) | ret_conflict_WB | CSRsrc1_conflict_WB;

    wire src2_conflict_EXE;
    wire src2_conflict_MEM;
    wire src2_conflict_WB;
    assign src2_conflict_EXE = ( reg_Conflict_EXE & rs2_conflict_EXE ) | store_conflict_EXE | CSRsrc2_conflict_EXE;
    assign src2_conflict_MEM = ( reg_Conflict_MEM & rs2_conflict_MEM ) | store_conflict_MEM | CSRsrc2_conflict_MEM;
    assign src2_conflict_WB = ( reg_Conflict_WB & rs2_conflict_WB ) | store_conflict_WB | CSRsrc2_conflict_WB;

    // --------------                   流水线前递          ----------------//
    reg [63:0]New_src1;
    reg [63:0]New_src2;
    always @(*)begin
        if( src1_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            New_src1 = alu_out;
        else if( src1_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            New_src1 = csr_rdata;
        else if(src1_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            New_src1 = MEMreg_aluout;
        else if(src1_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            New_src1 = MEMreg_CSRrdata;
        else if(src1_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            New_src1 = read_mem_data;
        else if( src1_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            New_src1 = WBreg_aluout;
        else if( src1_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            New_src1 = WBreg_CSRrdata;
        else if( src1_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            New_src1 = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            New_src1 = src1;
    end

    always @(*)begin
        if( src2_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            New_src2 = alu_out;
        else if( src2_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            New_src2 = csr_rdata;
        else if(src2_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            New_src2 = MEMreg_aluout;
        else if(src2_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            New_src2 = MEMreg_CSRrdata;
        else if(src2_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            New_src2 = read_mem_data;
        else if( src2_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            New_src2 = WBreg_aluout;
        else if( src2_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            New_src2 = WBreg_CSRrdata;
        else if( src2_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            New_src2 = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            New_src2 = src2;
    end   

    //根据store命令的格式 获得正确的存入内存的数据
    //即使没有冲突，从src2读取出来的数据 我提前给他格式化一下应该是没问题的，因为在C语言的写内存函数中还是要将wdata按照掩码格式化
    wire [63:0]real_storememdata_right;
    ysyx_22050854_MuxKey #(4,3,64) gen_real_storememdata_right (real_storememdata_right,MemOP,{
        3'b000,{56'b0,New_src2[7:0]},  // sb   000
        3'b001,{48'b0,New_src2[15:0]},  // sh
        3'b010,{32'b0,New_src2[31:0]},  // sw
        3'b011,{New_src2}   // sd
    });

    //-------------- GEN readmemaddr -----------//在译码级就计算出load的地址
    wire [63:0]readmemaddr;
    assign readmemaddr = MemRd | MemWr ? (alu_src1 + alu_src2) : 64'd0;
  
    //----------------- GEN PC -----------------//
    wire [31:0]current_pc;
    wire [31:0]next_pc;
    wire jump;
    wire ecall_or_mret;
    assign ecall_or_mret = ( ID_reg_inst == 32'h73 ) ? 1 : ( ID_reg_inst == 32'h30200073 ? 1'b1 : 1'b0);
    ysyx_22050854_pc gen_pc(
    .rst(rst),
    .clk(clk),
    .IDreg_valid(ID_reg_valid),
    .Data_Conflict(Data_Conflict_block),
    .suspend(Suspend_ALU | Suspend_LSU),
    .Branch(Branch),
    .No_branch(No_branch),
    .is_csr_pc(ecall_or_mret),
    .csr_pc(csr_rdata[31:0]),
    .unsigned_compare(ALUctr[3]),
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .src1(New_src1),
    .imm(imm),
    .jump(jump),
    .pc(current_pc),
    .next_pc(next_pc)
    );
    wire [31:0]jump_32;
    assign jump_32 = {31'b0,jump};
    import "DPI-C" function void get_jump_value(int jump_32);
    always@(*) get_jump_value(jump_32);

    import "DPI-C" function void get_current_pc_value(int current_pc);
    always@(*) get_current_pc_value(current_pc);

    //----------------------------------------------- EXE_reg ------------------------------------------------//
    reg EXEreg_valid;
    reg EXEreg_inst_enable;
    reg [31:0]EXEreg_inst;
    reg EXEreg_pc_enable;
    reg [31:0]EXEreg_pc;
    reg EXEreg_alusrc1_enable;
    reg [63:0]EXEreg_alusrc1;
    reg EXEreg_alusrc2_enable;
    reg [63:0]EXEreg_alusrc2;
    reg EXEreg_ALUctr_enable;
    reg [3:0]EXEreg_ALUctr;
    reg EXEreg_MULctr_enable;
    reg [3:0]EXEreg_MULctr;
    reg EXEreg_ALUext_enable;
    reg [2:0]EXEreg_ALUext;
    reg EXEreg_regWr_enable;
    reg EXEreg_regWr;
    reg EXEreg_Rd_enable;
    reg [4:0]EXEreg_Rd;
    reg EXEreg_memWr_enable;
    reg EXEreg_memWr;
    reg EXEreg_memRd_enable;
    reg EXEreg_memRd;
    reg EXEreg_memop_enable;
    reg [2:0]EXEreg_memop;
    reg EXEreg_memtoreg_enable;
    reg EXEreg_memtoreg;
    reg EXEreg_writememdata_enable;
    reg [63:0]EXEreg_writememdata;
    reg EXEreg_jump_enable;
    reg EXEreg_jump;
    reg EXEreg_Datablock_enable;
    reg EXEreg_Datablock;
    reg EXEreg_readmemaddr_enable;
    reg [63:0]EXEreg_readmemaddr;
    reg EXEreg_CSRrd_enable;
    reg EXEreg_CSRrd;
    reg EXEreg_CSRrdata_enable;
    reg [63:0]EXEreg_CSRrdata;
    always@(*)begin               //如果当前的ALU出现阻塞，则EXEreg不变，直到它计算完成
        EXEreg_inst_enable             =  ~Suspend_ALU & ~Suspend_LSU;  
        EXEreg_pc_enable               =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_alusrc1_enable          =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_alusrc2_enable          =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_ALUctr_enable           =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_MULctr_enable           =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_ALUext_enable           =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_regWr_enable            =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_Rd_enable               =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_memWr_enable            =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_memRd_enable            =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_memop_enable            =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_memtoreg_enable         =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_writememdata_enable     =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_jump_enable             =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_Datablock_enable        =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_readmemaddr_enable      =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_CSRrd_enable            =  ~Suspend_ALU & ~Suspend_LSU;
        EXEreg_CSRrdata_enable         =  ~Suspend_ALU & ~Suspend_LSU;
    end
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen0 (clk, rst,( (ID_reg_valid & (~Data_Conflict_block)) | Suspend_ALU | Suspend_LSU), EXEreg_valid, 1'b1);
    ysyx_22050854_Reg #(32,32'b0) EXEreg_geninst (clk, rst, ID_reg_inst, EXEreg_inst, EXEreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) EXEreg_genPC (clk, rst, ID_reg_pc, EXEreg_pc, EXEreg_pc_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen1 (clk, rst, alu_src1, EXEreg_alusrc1, EXEreg_alusrc1_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen2 (clk, rst, alu_src2, EXEreg_alusrc2, EXEreg_alusrc2_enable);
    ysyx_22050854_Reg #(4,4'b1111) EXEreg_gen3 (clk, rst, ALUctr, EXEreg_ALUctr, EXEreg_ALUctr_enable);
    ysyx_22050854_Reg #(4,4'b0) EXEreg_gen4 (clk, rst, MULctr, EXEreg_MULctr, EXEreg_MULctr_enable);
    ysyx_22050854_Reg #(3,3'b0) EXEreg_gen5 (clk, rst, ALUext, EXEreg_ALUext, EXEreg_ALUext_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen6 (clk, rst, RegWr, EXEreg_regWr, EXEreg_regWr_enable);
    ysyx_22050854_Reg #(5,5'b0) EXEreg_gen7 (clk, rst, rd, EXEreg_Rd, EXEreg_Rd_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen8 (clk, rst, MemWr, EXEreg_memWr, EXEreg_memWr_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen9 (clk, rst, MemRd, EXEreg_memRd, EXEreg_memRd_enable);
    ysyx_22050854_Reg #(3,3'b0) EXEreg_gen10 (clk, rst, MemOP, EXEreg_memop, EXEreg_memop_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen11 (clk, rst, MemtoReg, EXEreg_memtoreg, EXEreg_memtoreg_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen12 (clk, rst, real_storememdata_right, EXEreg_writememdata, EXEreg_writememdata_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen13 (clk, rst, jump, EXEreg_jump, EXEreg_jump_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen14 (clk, rst, Data_Conflict_block, EXEreg_Datablock, EXEreg_Datablock_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen15 (clk, rst, readmemaddr, EXEreg_readmemaddr, EXEreg_readmemaddr_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen20 (clk, rst, CSRrd, EXEreg_CSRrd, EXEreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen21 (clk, rst, csr_rdata, EXEreg_CSRrdata, EXEreg_CSRrdata_enable);

    import "DPI-C" function void get_EXEreginst_value(int EXEreg_inst);
    always@(*) get_EXEreginst_value(EXEreg_inst);
    import "DPI-C" function void get_EXEreg_pc_value(int EXEreg_pc);
    always@(*) get_EXEreg_pc_value(EXEreg_pc);
    wire [31:0]alusrc1;
    wire [31:0]alusrc2;
    assign alusrc1 = EXEreg_alusrc1[31:0];
    assign alusrc2 = EXEreg_alusrc2[31:0];
    import "DPI-C" function void get_EXEreg_alusrc1_value(int alusrc1);
    always@(*) get_EXEreg_alusrc1_value(alusrc1);
    import "DPI-C" function void get_EXEreg_alusrc2_value(int alusrc2);
    always@(*) get_EXEreg_alusrc2_value(alusrc2);
    wire [31:0]EXEreg_valid_32;
    assign EXEreg_valid_32 = {31'b0,EXEreg_valid};
    import "DPI-C" function void get_EXEreg_valid_value(int EXEreg_valid_32);
    always@(*) get_EXEreg_valid_value(EXEreg_valid_32);
    wire [31:0]EXEreg_writememdata_32;
    assign EXEreg_writememdata_32 = EXEreg_writememdata[31:0];
    import "DPI-C" function void get_EXEreg_writememdata_value(int EXEreg_writememdata_32);
    always@(*) get_EXEreg_writememdata_value(EXEreg_writememdata_32);

    //------------ALU------------//
    wire Suspend_ALU;
    wire [63:0]alu_out;
    ysyx_22050854_alu alu1(
    .clk(clk),
    .rst(rst),
    .EXEreg_valid(EXEreg_valid),   
    .ALUctr(EXEreg_ALUctr),
    .MULctr(EXEreg_MULctr),
    .ALUext(EXEreg_ALUext),
    .src1(EXEreg_alusrc1),
    .src2(EXEreg_alusrc2),
    .alu_busy(Suspend_ALU),
    .alu_out(alu_out)
    );

    wire [31:0]Suspend_alu_32;
    assign Suspend_alu_32 = {31'b0,Suspend_ALU};
    import "DPI-C" function void get_Suspend_alu_value(int Suspend_alu_32);
    always@(*) get_Suspend_alu_value(Suspend_alu_32);

    //--------------------------------------------- MEM_reg ---------------------------------------------//
    reg MEMreg_valid;
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen0 (clk, rst, ( EXEreg_valid & ~Suspend_ALU & ~Suspend_LSU ), MEMreg_valid, 1'b1); //如果ALU出现暂停信号，那么下周期MEMreg无效,如果LSU出现暂停，下周期MEMreg也无效
    reg MEMreg_inst_enable;
    reg [31:0]MEMreg_inst;
    reg MEMreg_pc_enable;
    reg [31:0]MEMreg_pc;
    reg MEMreg_aluout_enable;
    reg [63:0]MEMreg_aluout;
    reg MEMreg_regwr_enable;
    reg MEMreg_regwr;
    reg MEMreg_rd_enable;
    reg [4:0]MEMreg_rd;
    reg MEMreg_memwr_enable;
    reg MEMreg_memwr;
    reg MEMreg_memrd_enable;
    reg MEMreg_memrd;
    reg MEMreg_memop_enable;
    reg [2:0]MEMreg_memop;
    reg MEMreg_memtoreg_enable;
    reg MEMreg_memtoreg;
    reg MEMreg_writememdata_enable;
    reg [63:0]MEMreg_writememdata;
    reg MEMreg_readmemaddr_enable;
    reg [63:0]MEMreg_readmemaddr; //为判断 内存的数据冲突
    reg MEMreg_CSRrd_enable;
    reg MEMreg_CSRrd;
    reg MEMreg_CSRrdata_enable;
    reg [63:0]MEMreg_CSRrdata;

    ysyx_22050854_Reg #(32,32'b0) MEMreg_geninst (clk, rst, EXEreg_inst, MEMreg_inst, MEMreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) MEMreg_genPC (clk, rst, EXEreg_pc, MEMreg_pc, MEMreg_pc_enable);  
    always @(*)begin
        MEMreg_inst_enable = 1'b1;
        MEMreg_pc_enable = 1'b1;
        MEMreg_aluout_enable = 1'b1;
        MEMreg_regwr_enable = 1'b1;
        MEMreg_rd_enable = 1'b1;
        MEMreg_memwr_enable = 1'b1;
        MEMreg_memrd_enable = 1'b1;
        MEMreg_memop_enable = 1'b1;
        MEMreg_memtoreg_enable = 1'b1;
        MEMreg_writememdata_enable = 1'b1;
        MEMreg_readmemaddr_enable = 1'b1;
        MEMreg_CSRrd_enable = 1'b1;
        MEMreg_CSRrdata_enable = 1'b1;
    end
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen1 (clk, rst, alu_out, MEMreg_aluout, MEMreg_aluout_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen2 (clk, rst, EXEreg_regWr, MEMreg_regwr, MEMreg_regwr_enable);
    ysyx_22050854_Reg #(5,5'b0) MEMreg_gen3 (clk, rst, EXEreg_Rd, MEMreg_rd, MEMreg_rd_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen4 (clk, rst, EXEreg_memWr, MEMreg_memwr, MEMreg_memwr_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen5 (clk, rst, EXEreg_memRd, MEMreg_memrd, MEMreg_memrd_enable);
    ysyx_22050854_Reg #(3,3'b0) MEMreg_gen6 (clk, rst, EXEreg_memop, MEMreg_memop, MEMreg_memop_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen7 (clk, rst, EXEreg_memtoreg, MEMreg_memtoreg, MEMreg_memtoreg_enable);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen8 (clk, rst, EXEreg_writememdata, MEMreg_writememdata, MEMreg_writememdata_enable);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen9 (clk, rst, EXEreg_readmemaddr, MEMreg_readmemaddr, MEMreg_readmemaddr_enable); //
    ysyx_22050854_Reg #(1,1'b0) MEMreg_ge14 (clk, rst, EXEreg_CSRrd, MEMreg_CSRrd, MEMreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_ge15 (clk, rst, EXEreg_CSRrdata, MEMreg_CSRrdata, MEMreg_CSRrdata_enable);


    import "DPI-C" function void get_MEMreginst_value(int MEMreg_inst);
    always@(*) get_MEMreginst_value(MEMreg_inst);
    import "DPI-C" function void get_MEMreg_pc_value(int MEMreg_pc);
    always@(*) get_MEMreg_pc_value(MEMreg_pc);
    wire [31:0]memreg;
    assign memreg = MEMreg_aluout[31:0];
    import "DPI-C" function void get_MEMreg_aluout_value(int memreg);
    always@(*) get_MEMreg_aluout_value(memreg);
    wire [31:0]MEMreg_memwr_32;
    assign MEMreg_memwr_32 = {31'd0,MEMreg_memwr};
    import "DPI-C" function void get_MEMreg_memwr_value(int MEMreg_memwr_32);
    always@(*) get_MEMreg_memwr_value(MEMreg_memwr_32);
    wire [31:0]MEMreg_writememdata_32;
    assign MEMreg_writememdata_32 = MEMreg_writememdata[31:0];
    import "DPI-C" function void get_MEMreg_writememdata_value(int MEMreg_writememdata_32);
    always@(*) get_MEMreg_writememdata_value(MEMreg_writememdata_32);
    wire [31:0]MEMreg_valid_32;
    assign MEMreg_valid_32 = {31'b0,MEMreg_valid};
    import "DPI-C" function void get_MEMreg_valid_value(int MEMreg_valid);
    always@(*) get_MEMreg_valid_value(MEMreg_valid_32);

    wire [63:0] rdata;
    wire [63:0] Dcache_ret_data;
 
    wire Access_mem;
    assign Access_mem = ( readmemaddr[31:0] <= 32'h87ffffff ) ? 1'b1 : 1'b0;   // access device cannot use cache. for debug
    wire Data_cache_valid;
    assign Data_cache_valid =  ( MemRd | MemWr ) & ID_reg_valid & ~Suspend_ALU & ~Suspend_LSU & ~Data_Conflict_block;  //
    wire Data_cache_valid_debug;
    assign Data_cache_valid_debug =  Data_cache_valid & Access_mem;
    wire Access_device;
    assign Access_device = Data_cache_valid & ~Access_mem;
    wire Data_cache_op;
    assign Data_cache_op = ( MemWr & ID_reg_valid & ~Suspend_ALU & ~Data_Conflict_block );
    wire [6:0]Data_cache_index;
    wire [20:0]Data_cache_tag;
    wire [3:0]Data_cache_offset;
    assign Data_cache_offset = readmemaddr[3:0] ;
    assign Data_cache_index = readmemaddr[10:4];
    assign Data_cache_tag = readmemaddr[31:11];
    wire Data_cache_addr_ok;
    wire Data_cache_Data_ok;
    wire [7:0]Dcache_wr_wstb;
    ysyx_22050854_MuxKey #(4,3,8) gen_Dcache_wr_wstb (Dcache_wr_wstb,MemOP,{
        3'b000,8'b00000001,  // sb   000
        3'b001,8'b00000011,  // sh
        3'b010,8'b00001111,  // sw
        3'b011,8'b11111111   // sd
    });

    wire AXI_Dcache_rd_req;
    wire [2:0]AXI_Dcache_rd_type;
    wire [31:0]AXI_Dcache_rd_addr;
    wire AXI_Dcache_rd_rdy;
    wire AXI_Dcache_ret_valid;
    wire AXI_Dcache_ret_last;
    wire [63:0]AXI_Dcache_ret_data;
    wire AXI_Dcache_wr_req;
    wire [2:0]AXI_Dcache_wr_type;
    wire [31:0]AXI_Dcache_wr_addr;
    wire [7:0]AXI_Dcache_wr_wstb;
    wire [127:0]AXI_Dcache_wr_data;
    wire AXI_Dcache_wr_rdy;
    assign AXI_Dcache_wr_rdy = 1'b1;
    assign AXI_Dcache_rd_rdy = 1'b1;
    wire Suspend_LSU;
    assign AXI_Dcache_ret_valid = ( io_master_rresp  == 2'b10 ) && ( io_master_rid == 4'b0010 );
    assign AXI_Dcache_ret_last = io_master_rlast;
    assign AXI_Dcache_ret_data = io_master_rdata;
    ysyx_22050854_Dcache data_cache_inst (
        .clk(clk),
        .rst(rst),
        .valid(Data_cache_valid_debug),
        .op(Data_cache_op),
        .index(Data_cache_index),
        .tag(Data_cache_tag),
        .offset(Data_cache_offset),
        .wstrb(Dcache_wr_wstb),
        .wdata(real_storememdata_right),
        .addr_ok(Data_cache_addr_ok),
        .data_ok(Data_cache_Data_ok),
        .rdata(Dcache_ret_data),
        .unshoot(Suspend_LSU),

        //Dcache & AXI4 交互信号
        .rd_req(AXI_Dcache_rd_req),
        .rd_type(AXI_Dcache_rd_type),
        .rd_addr(AXI_Dcache_rd_addr),
        .rd_rdy(AXI_Dcache_rd_rdy),
        .ret_valid(AXI_Dcache_ret_valid),
        .ret_last(AXI_Dcache_ret_last),
        .ret_data(AXI_Dcache_ret_data),
        .wr_req(AXI_Dcache_wr_req),
        .wr_type(AXI_Dcache_wr_type),
        .wr_addr(AXI_Dcache_wr_addr),
        .wr_wstb(AXI_Dcache_wr_wstb),
        .wr_data(AXI_Dcache_wr_data),
        .wr_rdy(AXI_Dcache_wr_rdy),

        .sram4_addr(cpu_io_sram4_addr),
        .sram4_cen(cpu_io_sram4_cen),
        .sram4_wen(cpu_io_sram4_wen),
        .sram4_wmask(cpu_io_sram4_wmask),
        .sram4_wdata(cpu_io_sram4_wdata),
        .sram4_rdata(cpu_io_sram4_rdata),

        .sram5_addr(cpu_io_sram5_addr),
        .sram5_cen(cpu_io_sram5_cen),
        .sram5_wen(cpu_io_sram5_wen),
        .sram5_wmask(cpu_io_sram5_wmask),
        .sram5_wdata(cpu_io_sram5_wdata),
        .sram5_rdata(cpu_io_sram5_rdata),

        .sram6_addr(cpu_io_sram6_addr),
        .sram6_cen(cpu_io_sram6_cen),
        .sram6_wen(cpu_io_sram6_wen),
        .sram6_wmask(cpu_io_sram6_wmask),
        .sram6_wdata(cpu_io_sram6_wdata),
        .sram6_rdata(cpu_io_sram6_rdata),

        .sram7_addr(cpu_io_sram7_addr),
        .sram7_cen(cpu_io_sram7_cen),
        .sram7_wen(cpu_io_sram7_wen),
        .sram7_wmask(cpu_io_sram7_wmask),
        .sram7_wdata(cpu_io_sram7_wdata),
        .sram7_rdata(cpu_io_sram7_rdata)
    );

    reg AXI_Dcache_wlast;
    reg AXI_Dcache_wvalid;
    reg [63:0]AXI_Dcache_data_64;
    reg AXI_Dcache_data_first_over;
    reg [127:0]Dcache_to_AXI_data_temp;
    always @(posedge clk)begin
        if(rst)
            Dcache_to_AXI_data_temp <= 128'b0;
        else if(AXI_Dcache_wr_req)
            Dcache_to_AXI_data_temp <= AXI_Dcache_wr_data;
    end
    
//由于采用突发传输传输128位，而总线位宽为64位，所以需要传递两次，需要重新组织待传输的数据
//当检测到写地址信号时，第一个上升沿准备第一个写数据，并置写数据信号有效，第二个上升沿准备第二个写信号，同样置写数据信号有效
    always @(posedge clk)begin
        if(rst)begin
            AXI_Dcache_data_64 <= 64'b0;
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_wvalid <= 1'b0;
            AXI_Dcache_wlast <= 1'b0;
        end
        else if( AXI_Dcache_data_first_over )begin
            AXI_Dcache_data_64 <= Dcache_to_AXI_data_temp[127:64];
            AXI_Dcache_wvalid <= 1'b1;
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_wlast <= 1'b1;
        end
        else if( AXI_Dcache_wr_req ) begin     //读请求只持续一个周期
            AXI_Dcache_data_64 <= AXI_Dcache_wr_data[63:0];
            AXI_Dcache_wvalid <= 1'b1;
            AXI_Dcache_data_first_over <= 1'b1;
        end
        else begin
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_data_64 <= 64'b0;
            AXI_Dcache_wvalid <= 1'b0;
            AXI_Dcache_wlast <= 1'b0;
        end
    end

    assign io_master_awvalid = AXI_Dcache_wr_req;
    assign io_master_awaddr =  AXI_Dcache_wr_addr;
    assign io_master_awid = 4'b0010;
    assign io_master_awlen = 8'd128;
    assign io_master_awsize = 3'b0;
    assign io_master_awburst = 2'b0;

    assign io_master_wvalid = AXI_Dcache_wvalid;
    assign io_master_wdata = AXI_Dcache_data_64;
    assign io_master_wstrb = 8'hff;
    assign io_master_wlast = AXI_Dcache_wlast;

    assign io_master_bready = 1'b1;

    ysyx_22050854_AXI_arbiter GEN_AXI_signal (
        .clk(clk),
        .rst(rst),

        .IFU_request(AXI_Icache_rd_req),
        .LSU_request(AXI_Dcache_rd_req),
        .IFU_addr(AXI_Icache_rd_addr),
        .LSU_addr(AXI_Dcache_rd_addr),
        .AXI_arbiter_arvalid(io_master_arvalid),
        .AXI_arbiter_arid(io_master_arid),
        .AXI_arbiter_addr(io_master_araddr)
    );
    assign io_master_arlen = 8'b0;
    assign io_master_arsize = 3'b0;
    assign io_master_arburst = 2'b1;

    assign io_master_rready = 1'b1;

    //专门用来访问设备 可以说是调试用
    wire [63:0]device_rdata;
    wire device_arready;
    wire device_rresp;
    wire device_awready;
    wire device_wready;
    wire device_rvalid;
    wire device_bresp;
    wire device_bvalid;
    ysyx_22050854_SRAM_LSU cpu_access_device (
        .clk(clk),
        .rst_n(rst_n),

        //read address channel
        .araddr(readmemaddr[31:0]),
        .arvalid(Access_device & MemRd),
        .arready(device_arready), 

        //read data channel
        .rdata(device_rdata),
        .rresp(device_rresp),
        .rvalid(device_rvalid),
        .rready(1'b1),

        //write address channel
        .awaddr(readmemaddr[31:0]),
        .awvalid(Access_device & MemWr),
        .awready(device_awready),

        //write data channel
        .wdata(real_storememdata_right),
        .wvalid(Access_device & MemWr),
        .wready(device_wready),
        .wstrb(Dcache_wr_wstb),

        //write response channel
        .bresp(device_bresp),
        .bvalid(device_bvalid),
        .bready(1'b1)
    );

    reg [63:0]Data_while_SuspendLSU;
    always @(posedge clk)begin
        if(rst)
            Data_while_SuspendLSU <= 64'b0;
        else if( Suspend_LSU & Data_cache_Data_ok)
            Data_while_SuspendLSU <= read_mem_data;
    end

    wire [63:0]Memdata_to_WBreg_2;
    assign Memdata_to_WBreg_2 = Data_cache_Data_ok ? read_mem_data : Data_while_SuspendLSU;
    wire [63:0]Memdata_to_WBreg;
    assign Memdata_to_WBreg = device_rresp ? read_mem_data : Memdata_to_WBreg_2; //访问设备固定两个周期读出
    //如果Dcache没有命中，那么需要暂停，此时读内存的数据就应该是之前记录的暂停期间读到的数
    wire [63:0]read_mem_data;
    assign rdata = ( Data_cache_Data_ok ) ? Dcache_ret_data : device_rdata;
    //因为从存储器读出的数据总是8字节的,所以要根据地址以及位数获得不同的数据
    ysyx_22050854_MuxKey #(41,6,64) gen_read_mem_data (read_mem_data,{ MEMreg_aluout[2:0],MEMreg_memop },{
        6'b000000, {{56{rdata[7]}},rdata[7:0]},  //1 bytes signed extend  lb 000
        6'b000001, {{48{rdata[15]}},rdata[15:0]}, //2 bytes signed extend  lh
        6'b000010, {{32{rdata[31]}},rdata[31:0]}, //4 bytes signed extend  lw
        6'b000011, rdata,                 //8 bytes ld
        6'b000100, {56'b0,rdata[7:0]},    // 1 bytes unsigned extend lbu
        6'b000101, {48'b0,rdata[15:0]},   // 2 bytes unsigned extend lhu
        6'b000110, {32'b0,rdata[31:0]},   // 4 bytes unsigned extend lwu

        6'b001000, {{56{rdata[15]}},rdata[15:8]},  //1 bytes signed extend  lb 001
        6'b001001, {{48{rdata[23]}},rdata[23:8]}, //2 bytes signed extend  lh
        6'b001010, {{32{rdata[39]}},rdata[39:8]}, //4 bytes signed extend  lw
        6'b001100, {56'b0,rdata[15:8]},    // 1 bytes unsigned extend lbu
        6'b001101, {48'b0,rdata[23:8]},   // 2 bytes unsigned extend lhu
        6'b001110, {32'b0,rdata[39:8]},   // 4 bytes unsigned extend lwu

        6'b010000, {{56{rdata[23]}},rdata[23:16]},  //1 bytes signed extend  lb 010
        6'b010001, {{48{rdata[31]}},rdata[31:16]}, //2 bytes signed extend  lh
        6'b010010, {{32{rdata[47]}},rdata[47:16]}, //4 bytes signed extend  lw
        6'b010100, {56'b0,rdata[23:16]},    // 1 bytes unsigned extend lbu
        6'b010101, {48'b0,rdata[31:16]},   // 2 bytes unsigned extend lhu
        6'b010110, {32'b0,rdata[47:16]},   // 4 bytes unsigned extend lwu

        6'b011000, {{56{rdata[31]}},rdata[31:24]},  //1 bytes signed extend  lb 011
        6'b011001, {{48{rdata[39]}},rdata[39:24]}, //2 bytes signed extend  lh
        6'b011010, {{32{rdata[55]}},rdata[55:24]}, //4 bytes signed extend  lw
        6'b011100, {56'b0,rdata[31:24]},    // 1 bytes unsigned extend lbu
        6'b011101, {48'b0,rdata[39:24]},   // 2 bytes unsigned extend lhu
        6'b011110, {32'b0,rdata[55:24]},   // 4 bytes unsigned extend lwu

        6'b100000, {{56{rdata[39]}},rdata[39:32]},  //1 bytes signed extend  lb 100
        6'b100001, {{48{rdata[47]}},rdata[47:32]}, //2 bytes signed extend  lh
        6'b100010, {{32{rdata[63]}},rdata[63:32]}, //4 bytes signed extend  lw
        6'b100100, {56'b0,rdata[39:32]},   // 1 bytes unsigned extend lbu
        6'b100101, {48'b0,rdata[47:32]},   // 2 bytes unsigned extend lhu
        6'b100110, {32'b0,rdata[63:32]},   // 4 bytes unsigned extend lwu

        6'b101000, {{56{rdata[47]}},rdata[47:40]},  //1 bytes signed extend  lb 101
        6'b101001, {{48{rdata[55]}},rdata[55:40]}, //2 bytes signed extend  lh
        6'b101100, {56'b0,rdata[47:40]},    // 1 bytes unsigned extend lbu
        6'b101101, {48'b0,rdata[55:40]},   // 2 bytes unsigned extend lhu

        6'b110000, {{56{rdata[55]}},rdata[55:48]},  //1 bytes signed extend  lb 110
        6'b110001, {{48{rdata[63]}},rdata[63:48]},  //2 bytes signed extend  lh
        6'b110100, {56'b0,rdata[55:48]},    // 1 bytes unsigned extend lbu
        6'b110101, {48'b0,rdata[63:48]},   // 2 bytes unsigned extend lhu

        6'b111000, {{56{rdata[63]}},rdata[63:56]},  //1 bytes signed extend  lb 111
        6'b111100, {56'b0,rdata[63:56]}    // 1 bytes unsigned extend lbu
    });

    wire [31:0]wr_reg_data_32;
    assign wr_reg_data_32 = wr_reg_data[31:0];
    import "DPI-C" function void get_wr_reg_data_value(int wr_reg_data_32);
    always@(*) get_wr_reg_data_value(wr_reg_data_32);

    wire [31:0]rdata_32;
    assign rdata_32 = read_mem_data[31:0];
    import "DPI-C" function void get_rdata_value(int rdata_32);
    always@(*) get_rdata_value(rdata_32);

    wire [31:0]Suspend_LSU_32;
    assign Suspend_LSU_32 = { 31'b0 , Suspend_LSU };
    import "DPI-C" function void get_Suspend_LSU_value(int Suspend_LSU_32);
    always@(*) get_Suspend_LSU_value( Suspend_LSU_32 );


    wire [31:0]Data_cache_Data_ok_32;
    assign Data_cache_Data_ok_32 = { 31'b0 , Data_cache_Data_ok };
    import "DPI-C" function void get_Data_cache_Data_ok_value(int Data_cache_Data_ok_32);
    always@(*) get_Data_cache_Data_ok_value( Data_cache_Data_ok_32 );

    wire [31:0]Dcache_ret_data_32;
    assign Dcache_ret_data_32 = Dcache_ret_data[31:0];
    import "DPI-C" function void get_Dcache_ret_data_value(int Dcache_ret_data_32);
    always@(*) get_Dcache_ret_data_value(Dcache_ret_data_32);

    wire [31:0]Data_cache_valid_32;
    assign Data_cache_valid_32 = { 31'b0 , Data_cache_valid };
    import "DPI-C" function void get_Data_cache_valid_value(int Data_cache_valid_32);
    always@(*) get_Data_cache_valid_value( Data_cache_valid_32 );

    wire [31:0]real_storememdata_right_32;
    assign real_storememdata_right_32 = real_storememdata_right[31:0];
    import "DPI-C" function void get_real_storememdata_right_value(int real_storememdata_right_32);
    always@(*) get_real_storememdata_right_value(real_storememdata_right_32);

    wire [31:0]Dcache_addr;
    assign Dcache_addr = readmemaddr[31:0];
    import "DPI-C" function void get_Dcache_addr_value(int Dcache_addr);
    always@(*) get_Dcache_addr_value(Dcache_addr);

    import "DPI-C" function void get_AXI_Dcache_wr_addr_value(int AXI_Dcache_wr_addr);
    always@(*) get_AXI_Dcache_wr_addr_value(AXI_Dcache_wr_addr);

    wire [31:0]AXI_Dcache_data_32;
    assign AXI_Dcache_data_32 = AXI_Dcache_data_64[31:0];
    import "DPI-C" function void get_AXI_Dcache_data_64_value(int AXI_Dcache_data_32);
    always@(*) get_AXI_Dcache_data_64_value(AXI_Dcache_data_32);

    //AXI_Dcache_rd_req
    //----------------------------------- WBreg -------------------------------------------------------------//
    reg WBreg_valid;
    reg WBreg_inst_enable;
    reg [31:0]WBreg_inst;
    reg WBreg_pc_enable;
    reg [31:0]WBreg_pc;
    reg WBreg_readmemdata_enable;
    reg [63:0]WBreg_readmemdata;
    reg WBreg_regwr_enable;
    reg WBreg_regwr;
    reg WBreg_rd_enable;
    reg [4:0]WBreg_rd;
    reg WBreg_aluout_enable;
    reg [63:0]WBreg_aluout;
    reg WBreg_memRd_enable;
    reg WBreg_memRd;
    reg WBreg_memtoreg_enable;
    reg WBreg_memtoreg;
    reg WBreg_CSRrd_enable;
    reg WBreg_CSRrd;
    reg WBreg_CSRrdata_enable;
    reg [63:0]WBreg_CSRrdata;
    always@(*)begin
        WBreg_inst_enable = 1'b1;
        WBreg_pc_enable = 1'b1;
        //WBreg_readmemdata_enable = dsram_rresp;
        WBreg_readmemdata_enable = 1'b1;
        WBreg_regwr_enable = 1'b1;
        WBreg_rd_enable = 1'b1;
        WBreg_memtoreg_enable = 1'b1;
        WBreg_aluout_enable = 1'b1;
        WBreg_memRd_enable = 1'b1;
        WBreg_CSRrd_enable = 1'b1;
        WBreg_CSRrdata_enable = 1'b1;
    end
    ysyx_22050854_Reg #(32,32'b0) WBreg_geninst (clk, rst, MEMreg_inst, WBreg_inst, WBreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) WBreg_genPC (clk, rst, MEMreg_pc, WBreg_pc, WBreg_pc_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen0 (clk, rst, MEMreg_valid, WBreg_valid, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen1 (clk, rst, Memdata_to_WBreg, WBreg_readmemdata, WBreg_readmemdata_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen2 (clk, rst, MEMreg_regwr, WBreg_regwr, WBreg_regwr_enable);
    ysyx_22050854_Reg #(5,5'b0) WBreg_gen3 (clk, rst, MEMreg_rd, WBreg_rd, WBreg_rd_enable);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen4 (clk, rst, MEMreg_aluout, WBreg_aluout, WBreg_aluout_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen5 (clk, rst, MEMreg_memtoreg, WBreg_memtoreg, WBreg_memtoreg_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen6 (clk, rst, MEMreg_memrd, WBreg_memRd, WBreg_memRd_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen7 (clk, rst, MEMreg_CSRrd, WBreg_CSRrd, WBreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen8 (clk, rst, MEMreg_CSRrdata, WBreg_CSRrdata, WBreg_CSRrdata_enable);

    wire ebreak;
    assign ebreak = ( ( WBreg_inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011 ) &  WBreg_valid ) ? 1'b1 : 1'b0;
    wire [31:0]ebreak_32;
    assign ebreak_32 = { 31'b0,ebreak };
    import "DPI-C" function void get_ebreak_value(int ebreak_32);
    always@(*) get_ebreak_value(ebreak_32);

    wire [31:0]x10_32;
    assign x10_32 = x10[31:0];
    import "DPI-C" function void get_x10_value(int x10_32);
    always@(*) get_x10_value(x10_32);


    //写回寄存器的数据，总共有三种可能 1.ALU计算值  2.从内存读出的数据 3.从CSR读出的数据
    wire [63:0]wr_reg_data;
    assign wr_reg_data = WBreg_memtoreg ? WBreg_readmemdata : ( WBreg_CSRrd ? WBreg_CSRrdata : WBreg_aluout );

    import "DPI-C" function void get_WBreginst_value(int WBreg_inst);
    always@(*) get_WBreginst_value(WBreg_inst);
    import "DPI-C" function void get_WBreg_pc_value(int WBreg_pc);
    always@(*) get_WBreg_pc_value(WBreg_pc);
    wire [31:0]wbreg;
    assign wbreg = WBreg_aluout[31:0];
    import "DPI-C" function void get_WBreg_aluout_value(int wbreg);
    always@(*) get_WBreg_aluout_value(wbreg);
    wire [31:0]wbrd_32;
    assign wbrd_32 = {27'b0,WBreg_rd};
    import "DPI-C" function void get_WBreg_rd_value(int wbrd_32);
    always@(*) get_WBreg_rd_value(wbrd_32);
    wire [31:0]WBreg_valid_32;
    assign WBreg_valid_32 = {31'b0,WBreg_valid};
    import "DPI-C" function void get_WBreg_valid_value(int WBreg_valid_32);
    always@(*) get_WBreg_valid_value(WBreg_valid_32);

    //for difftest
    reg inst_finish;
    ysyx_22050854_Reg #(1,1'b0) inst_finish_gen (clk, rst, WBreg_valid, inst_finish, 1'b1);
    reg [31:0]inst_finish_pc;
    ysyx_22050854_Reg #(32,32'h0) inst_finishpc_gen (clk, rst, WBreg_pc, inst_finish_pc, 1'b1);
    reg [31:0]instruction_finsh;
    ysyx_22050854_Reg #(32,32'h0) instruction_finsh_gen (clk, rst, WBreg_inst, instruction_finsh, 1'b1);
    reg [31:0]access_mem_addr;
    ysyx_22050854_Reg #(32,32'h0) access_mem_addr_gen (clk, rst, WBreg_aluout[31:0], access_mem_addr, 1'b1);
    reg DIFFreg_memrd;
    ysyx_22050854_Reg #(1,1'b0) DIFFreg_memrd_gen (clk, rst, WBreg_memRd, DIFFreg_memrd, 1'b1);
    wire is_accessdevice;
    assign is_accessdevice = ( DIFFreg_memrd ) ? ( ( access_mem_addr > 32'h8fffffff ) ? 1'b1 : 1'b0 ) : 1'b0;

    wire [31:0]inst_finish_32;
    assign inst_finish_32 = {31'b0,inst_finish};
    import "DPI-C" function void get_inst_finish_value(int inst_finish_32);
    always@(*) get_inst_finish_value(inst_finish_32);
    import "DPI-C" function void get_inst_finishpc_value(int inst_finish_pc);
    always@(*) get_inst_finishpc_value(inst_finish_pc);
    wire [31:0]is_device_32;
    assign is_device_32 = {31'b0,is_accessdevice};
    import "DPI-C" function void get_is_device_value(int is_device_32);
    always@(*) get_is_device_value(is_device_32);
    import "DPI-C" function void get_instruction_finsh_value(int instruction_finsh);
    always@(*) get_instruction_finsh_value(instruction_finsh);


endmodule 
