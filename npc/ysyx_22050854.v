`timescale 1ns/1ps
module ysyx_22050854 (
    input clock,
    input reset,
    input io_interrupt,
    input io_master_awready,
    output io_master_awvalid, 
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
    input [1:0] io_master_rresp,
    input [63:0] io_master_rdata,
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
    output [1:0] io_slave_rresp,
    output [63:0] io_slave_rdata,
    output  io_slave_rlast,
    output [5:0] io_sram0_addr,
    output  io_sram0_cen,
    output  io_sram0_wen,
    output [127:0] io_sram0_wmask,
    output [127:0] io_sram0_wdata,
    input [127:0] io_sram0_rdata,
    output [5:0] io_sram1_addr,
    output  io_sram1_cen,
    output  io_sram1_wen,
    output [127:0] io_sram1_wmask,
    output [127:0] io_sram1_wdata,
    input [127:0] io_sram1_rdata,
    output [5:0] io_sram2_addr,
    output  io_sram2_cen,
    output  io_sram2_wen,
    output [127:0] io_sram2_wmask,
    output [127:0] io_sram2_wdata,
    input [127:0] io_sram2_rdata,
    output [5:0] io_sram3_addr,
    output  io_sram3_cen,
    output  io_sram3_wen,
    output [127:0] io_sram3_wmask,
    output [127:0] io_sram3_wdata,
    input [127:0] io_sram3_rdata,
    output [5:0] io_sram4_addr,
    output  io_sram4_cen,
    output  io_sram4_wen,
    output [127:0] io_sram4_wmask,
    output [127:0] io_sram4_wdata,
    input [127:0] io_sram4_rdata,
    output [5:0] io_sram5_addr,
    output  io_sram5_cen,
    output  io_sram5_wen,
    output [127:0] io_sram5_wmask,
    output [127:0] io_sram5_wdata,
    input [127:0] io_sram5_rdata,
    output [5:0] io_sram6_addr,
    output  io_sram6_cen,
    output  io_sram6_wen,
    output [127:0] io_sram6_wmask,
    output [127:0] io_sram6_wdata,
    input [127:0] io_sram6_rdata,
    output [5:0] io_sram7_addr,
    output  io_sram7_cen,
    output  io_sram7_wen,
    output [127:0] io_sram7_wmask,
    output [127:0] io_sram7_wdata,
    input [127:0] io_sram7_rdata
); 
    //No use, set 0
    assign io_slave_awready = 1'b0;
    assign io_slave_wready = 1'b0;
    assign io_slave_bvalid = 1'b0;
    assign io_slave_bid = 4'b0;
    assign io_slave_bresp = 2'b0;
    assign io_slave_arready = 1'b0;
    assign io_slave_rvalid = 1'b0;
    assign io_slave_rid = 4'b0;
    assign io_slave_rresp = 2'b0;
    assign io_slave_rdata = 64'b0;
    assign io_slave_rlast = 1'b0;

    wire rst_n;
    assign rst_n = ~reset;

    //-------------------------------------- IFU --------------------------------------------------------//
    //when IFU_suspend 1->0. the instruction is already at IDreg
    reg [31:0]pc_test;
    always @(posedge clock)begin
        if(reset)
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
    //如果在执行阶段需要暂停，且此时IFU发起了暂停
    reg [31:0]pc_real;
    always @(*)begin
        if(reset)
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

//如果发现jump的时候 IFU没有命中 那么原先的置后两个周期的指令无效不起作用
//需要等到IFU取到指令无效（具体周期不确定），定义以下寄存器来确定
    reg [31:0]PC_Jump_Suspend;
    reg Last_Jump_Suspend;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg0 (clock, reset, next_pc, PC_Jump_Suspend, jump & Suspend_IFU & ~last_JumpAndDataBlock);
    ysyx_22050854_Reg #(1,1'b0) Inst_Reg1 (clock, reset, 1'b1, Last_Jump_Suspend, jump & Suspend_IFU & ~last_JumpAndDataBlock);

//如果发现Datablock的时候 且该指令的第二个指令IFU没有命中 那么原先的置后两个周期的指令无效不起作用 且会损失一个指令
//需要等到IFU取到指令无效（具体周期不确定），定义以下寄存器来确定
    reg [31:0]PC_DataBlock_Suspend;
    reg Last_DataBlock_Suspend;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg2 ( clock, reset, next_pc, PC_DataBlock_Suspend, Data_Conflict_block & ~JumpAndDataBlock & Suspend_IFU );
    ysyx_22050854_Reg #(1,1'b0) Inst_Reg3 ( clock, reset, 1'b1, Last_DataBlock_Suspend, Data_Conflict_block & ~JumpAndDataBlock & Suspend_IFU );

//如果发现Datablock并且是跳转指令时，当前周期不保存，等下一周期不冲突后，再保存正确的跳转地址
//并且当前周期不存在于DataBlock中，下一周期也不存在于jump中，保证标记的唯一性
    reg [31:0]PC_JumpAndBlock_Suspend;
    reg Last_JumpAndBlock_Suspend;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg4 ( clock, reset, next_pc, PC_JumpAndBlock_Suspend, last_JumpAndDataBlock & Suspend_IFU );
    ysyx_22050854_Reg #(1,1'b0) Inst_Reg5 ( clock, reset, 1'b1, Last_JumpAndBlock_Suspend, last_JumpAndDataBlock & Suspend_IFU );

//如果ALU发起暂停的时候 IFU没有命中,正在寻找，而在ALU结束暂停之后，IFU取到指令，那么这个指令应当无效,当之前的逻辑只是ALU暂停时无效
//应该记录下来ALU暂停且IFU也暂停时的指令，等到IFU结束暂停之后，用这个指令取指
    reg [31:0]PC_ALUsuspend_IFUsuspend;
    reg Last_ALUsuspend_IFUsuspend;
    always @(posedge clock)begin
        if(reset)
        begin
            Last_ALUsuspend_IFUsuspend <= 1'b0;
            PC_ALUsuspend_IFUsuspend <= 32'h80000000;
        end
        else if(Suspend_ALU & Suspend_IFU)begin
            Last_ALUsuspend_IFUsuspend <= 1'b1;
            PC_ALUsuspend_IFUsuspend  <= EXEreg_pc + 32'd4;
            if(Last_DataBlock_Suspend)
                Last_DataBlock_Suspend <= 1'b0;     //*** 如果有DtaBlock，要置0 不然会重复
        end
    end

    reg [31:0]pc_record_1;
    reg [31:0]pc_record_2;
    always@(posedge clock)begin
        if(reset)
            pc_record_1 <= 32'b0;
        else 
            pc_record_1 <= pc_real; 
    end
    always@(posedge clock)begin
        if(reset)
            pc_record_2 <= 32'b0;
        else if( Icache_addr_ok )
            pc_record_2 <= pc_record_1;
    end

    //当取到跳转的跳转指令时，下个上升沿以及下下个上升沿都不能将指令送到IDreg中，而是将指令置为0，空走两个始终周期
    wire [31:0]pc_record;
    assign pc_record = jump ? next_pc : pc_record_2;

    //如果当前周期下是jalr 或者 beq指令 且发生了阻塞，则无法产生正确的next_pc,本周期不取指
    wire JumpAndDataBlock;
    assign JumpAndDataBlock = ( ( ID_reg_inst[6:0] == 7'b1100011) | (ID_reg_inst[6:0]) == 7'b1100111) & Data_Conflict_block;

    reg last_JumpAndDataBlock;
    ysyx_22050854_Reg #(1,1'b0) jumpandblock (clock, reset, JumpAndDataBlock, last_JumpAndDataBlock, 1'b1);
    reg last_Suspend_ALU;
    ysyx_22050854_Reg #(1,1'b0) record_lastSuspend (clock, reset, Suspend_ALU, last_Suspend_ALU, 1'b1);
    reg last_Suspend_IFU;
    ysyx_22050854_Reg #(1,1'b0) record_last_Suspend_IFU (clock, reset, Suspend_IFU, last_Suspend_IFU, 1'b1);
    reg last_Suspend_LSU;
    ysyx_22050854_Reg #(1,1'b0) record_last_Suspend_LSU (clock, reset, Suspend_LSU, last_Suspend_LSU, 1'b1);

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
        .clock(clock),
        .reset(reset),
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

        .sram0_addr(io_sram0_addr),
        .sram0_cen(io_sram0_cen),
        .sram0_wen(io_sram0_wen),
        .sram0_wmask(io_sram0_wmask),
        .sram0_wdata(io_sram0_wdata),
        .sram0_rdata(io_sram0_rdata),

        .sram1_addr(io_sram1_addr),
        .sram1_cen(io_sram1_cen),
        .sram1_wen(io_sram1_wen),
        .sram1_wmask(io_sram1_wmask),
        .sram1_wdata(io_sram1_wdata),
        .sram1_rdata(io_sram1_rdata),

        .sram2_addr(io_sram2_addr),
        .sram2_cen(io_sram2_cen),
        .sram2_wen(io_sram2_wen),
        .sram2_wmask(io_sram2_wmask),
        .sram2_wdata(io_sram2_wdata),
        .sram2_rdata(io_sram2_rdata),

        .sram3_addr(io_sram3_addr),
        .sram3_cen(io_sram3_cen),
        .sram3_wen(io_sram3_wen),
        .sram3_wmask(io_sram3_wmask),
        .sram3_wdata(io_sram3_wdata),
        .sram3_rdata(io_sram3_rdata)
    );

    wire [63:0]inst_64;
    wire [31:0]inst;
    assign inst_64 = (Icache_data_ok == 1'b1) ? Icache_ret_data : 64'h6666666666666666;
    assign inst = Icache_data_ok ? ( ( pc_record_2[2:0] == 3'b000 ) ? inst_64[31:0] : inst_64[63:32] ) : 32'd0;

    //---------------------------------------------                      ID_reg                             -----------------------------------------//
    reg ID_reg_valid;
    reg [31:0]ID_reg_inst;
    reg [31:0]ID_reg_pc;
    wire ID_reg_inst_enable;
    wire ID_reg_pc_enable;
    //如果更新前发现需要阻塞，就不更新了 如果ALU发起了暂停，IDreg也应该保持不变 //后来改了，ALU结束后重新取指，不过改不改不影响
    assign ID_reg_inst_enable = Icache_data_ok & (~Data_Conflict_block) & ~Suspend_ALU; 
    assign ID_reg_pc_enable = Icache_data_ok & (~Data_Conflict_block) & ~Suspend_ALU;
    wire IFUsuspend_with_Others;
    assign IFUsuspend_with_Others = (~Last_Jump_Suspend) & (~Last_DataBlock_Suspend) & (~Last_ALUsuspend_IFUsuspend) & (~Last_JumpAndBlock_Suspend);
    always@(posedge clock)begin
        if(reset)
            ID_reg_valid <= 1'b0;
        else
            ID_reg_valid <=  ( Icache_data_ok & (~jump) & (~EXEreg_jump) & (~EXEreg_Datablock) & (~Suspend_ALU) & IFUsuspend_with_Others & ~Suspend_LSU ) | Data_Conflict_block;
    end                                                                                                          

    ysyx_22050854_Reg #(32,32'b0) IDreg_gen0 (clock, (reset | jump | EXEreg_jump | EXEreg_Datablock), inst, ID_reg_inst, ID_reg_inst_enable);
    ysyx_22050854_Reg #(32,32'h80000000) IDreg_gen1 (clock, reset, pc_record, ID_reg_pc, ID_reg_pc_enable);

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
    .clock(clock),
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
    wire timer_interrupt;
    ysyx_22050854_CSRegister CSRfile_inst (
    .clock(clock),
    .reset(reset),
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

    // --------------------------------         流水线前递          ----------------------------------//
    reg [63:0]New_src1;
    reg [63:0]New_src2;
    always @(*)begin
        if(reset)
            New_src1 = 64'b0;
        else if( src1_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
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
        if(reset)
            New_src2 = 64'b0;
        else if( src2_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
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
    .reset(reset),
    .clock(clock),
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

    //----------------------------------------------- EXE_reg ------------------------------------------------//
    reg EXEreg_valid;
    wire EXEreg_inst_enable;
    reg [31:0]EXEreg_inst;
    wire EXEreg_pc_enable;
    reg [31:0]EXEreg_pc;
    wire EXEreg_alusrc1_enable;
    reg [63:0]EXEreg_alusrc1;
    wire EXEreg_alusrc2_enable;
    reg [63:0]EXEreg_alusrc2;
    wire EXEreg_ALUctr_enable;
    reg [3:0]EXEreg_ALUctr;
    wire EXEreg_MULctr_enable;
    reg [3:0]EXEreg_MULctr;
    wire EXEreg_ALUext_enable;
    reg [2:0]EXEreg_ALUext;
    wire EXEreg_regWr_enable;
    reg EXEreg_regWr;
    wire EXEreg_Rd_enable;
    reg [4:0]EXEreg_Rd;
    wire EXEreg_memRd_enable;
    reg EXEreg_memRd;
    wire EXEreg_memop_enable;
    reg [2:0]EXEreg_memop;
    wire EXEreg_memtoreg_enable;
    reg EXEreg_memtoreg;
    wire EXEreg_jump_enable;
    reg EXEreg_jump;
    wire EXEreg_Datablock_enable;
    reg EXEreg_Datablock;
    wire EXEreg_CSRrd_enable;
    reg EXEreg_CSRrd;
    wire EXEreg_CSRrdata_enable;
    reg [63:0]EXEreg_CSRrdata;

    //如果当前的ALU出现阻塞，则EXEreg不变，直到它计算完成
    assign EXEreg_inst_enable       =  ~Suspend_ALU & ~Suspend_LSU;  
    assign EXEreg_pc_enable         =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_alusrc1_enable    =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_alusrc2_enable    =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_ALUctr_enable     =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_MULctr_enable     =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_ALUext_enable     =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_regWr_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_Rd_enable         =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_memRd_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_memop_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_memtoreg_enable   =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_jump_enable       =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_Datablock_enable  =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_CSRrd_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_CSRrdata_enable   =  ~Suspend_ALU & ~Suspend_LSU;
    
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen0 (clock, reset,( (ID_reg_valid & (~Data_Conflict_block)) | Suspend_ALU | Suspend_LSU), EXEreg_valid, 1'b1);
    ysyx_22050854_Reg #(32,32'b0) EXEreg_geninst (clock, reset, ID_reg_inst, EXEreg_inst, EXEreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) EXEreg_genPC (clock, reset, ID_reg_pc, EXEreg_pc, EXEreg_pc_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen1 (clock, reset, alu_src1, EXEreg_alusrc1, EXEreg_alusrc1_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen2 (clock, reset, alu_src2, EXEreg_alusrc2, EXEreg_alusrc2_enable);
    ysyx_22050854_Reg #(4,4'b1111) EXEreg_gen3 (clock, reset, ALUctr, EXEreg_ALUctr, EXEreg_ALUctr_enable);
    ysyx_22050854_Reg #(4,4'b0) EXEreg_gen4 (clock, reset, MULctr, EXEreg_MULctr, EXEreg_MULctr_enable);
    ysyx_22050854_Reg #(3,3'b0) EXEreg_gen5 (clock, reset, ALUext, EXEreg_ALUext, EXEreg_ALUext_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen6 (clock, reset, RegWr, EXEreg_regWr, EXEreg_regWr_enable);
    ysyx_22050854_Reg #(5,5'b0) EXEreg_gen7 (clock, reset, rd, EXEreg_Rd, EXEreg_Rd_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen9 (clock, reset, MemRd, EXEreg_memRd, EXEreg_memRd_enable);
    ysyx_22050854_Reg #(3,3'b0) EXEreg_gen10 (clock, reset, MemOP, EXEreg_memop, EXEreg_memop_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen11 (clock, reset, MemtoReg, EXEreg_memtoreg, EXEreg_memtoreg_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen13 (clock, reset, jump, EXEreg_jump, EXEreg_jump_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen14 (clock, reset, Data_Conflict_block, EXEreg_Datablock, EXEreg_Datablock_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen20 (clock, reset, CSRrd, EXEreg_CSRrd, EXEreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen21 (clock, reset, csr_rdata, EXEreg_CSRrdata, EXEreg_CSRrdata_enable);

    //------------ALU------------//
    wire Suspend_ALU;
    wire [63:0]alu_out;
    ysyx_22050854_alu alu1(
    .clock(clock),
    .reset(reset),
    .EXEreg_valid(EXEreg_valid),   
    .ALUctr(EXEreg_ALUctr),
    .MULctr(EXEreg_MULctr),
    .ALUext(EXEreg_ALUext),
    .src1(EXEreg_alusrc1),
    .src2(EXEreg_alusrc2),
    .alu_busy(Suspend_ALU),
    .alu_out(alu_out)
    );

    //--------------------------------------------- MEM_reg ---------------------------------------------//
    reg MEMreg_valid;
    wire MEMreg_inst_enable;
    reg [31:0]MEMreg_inst;
    wire MEMreg_pc_enable;
    reg [31:0]MEMreg_pc;
    wire MEMreg_aluout_enable;
    reg [63:0]MEMreg_aluout;
    wire MEMreg_regwr_enable;
    reg MEMreg_regwr;
    wire MEMreg_rd_enable;
    reg [4:0]MEMreg_rd;
    wire MEMreg_memrd_enable;
    reg MEMreg_memrd;
    wire MEMreg_memop_enable;
    reg [2:0]MEMreg_memop;  //for get right data from 64bits data(from cache)
    wire MEMreg_memtoreg_enable;
    reg MEMreg_memtoreg;
    wire MEMreg_CSRrd_enable;
    reg MEMreg_CSRrd;
    wire MEMreg_CSRrdata_enable;
    reg [63:0]MEMreg_CSRrdata;

    assign MEMreg_inst_enable = 1'b1;
    assign MEMreg_pc_enable = 1'b1;
    assign MEMreg_aluout_enable = 1'b1;
    assign MEMreg_regwr_enable = 1'b1;
    assign MEMreg_rd_enable = 1'b1;
    assign MEMreg_memrd_enable = 1'b1;
    assign MEMreg_memop_enable = 1'b1;
    assign MEMreg_memtoreg_enable = 1'b1;
    assign MEMreg_CSRrd_enable = 1'b1;
    assign MEMreg_CSRrdata_enable = 1'b1;

    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen0 (clock, reset, ( EXEreg_valid & ~Suspend_ALU & ~Suspend_LSU ), MEMreg_valid, 1'b1); //如果ALU出现暂停信号，那么下周期MEMreg无效,如果LSU出现暂停，下周期MEMreg也无效
    ysyx_22050854_Reg #(32,32'b0) MEMreg_geninst (clock, reset, EXEreg_inst, MEMreg_inst, MEMreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) MEMreg_genPC (clock, reset, EXEreg_pc, MEMreg_pc, MEMreg_pc_enable);  
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen1 (clock, reset, alu_out, MEMreg_aluout, MEMreg_aluout_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen2 (clock, reset, EXEreg_regWr, MEMreg_regwr, MEMreg_regwr_enable);
    ysyx_22050854_Reg #(5,5'b0) MEMreg_gen3 (clock, reset, EXEreg_Rd, MEMreg_rd, MEMreg_rd_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen5 (clock, reset, EXEreg_memRd, MEMreg_memrd, MEMreg_memrd_enable);
    ysyx_22050854_Reg #(3,3'b0) MEMreg_gen6 (clock, reset, EXEreg_memop, MEMreg_memop, MEMreg_memop_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen7 (clock, reset, EXEreg_memtoreg, MEMreg_memtoreg, MEMreg_memtoreg_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen8 (clock, reset, EXEreg_CSRrd, MEMreg_CSRrd, MEMreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen9 (clock, reset, EXEreg_CSRrdata, MEMreg_CSRrdata, MEMreg_CSRrdata_enable);

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
    wire FenceI;
    assign FenceI = ID_reg_valid && ( ID_reg_inst[6:0] == 7'b0001111 )  && ( ID_reg_inst[14:12] == 3'b001 );

    ysyx_22050854_Dcache data_cache_inst (
        .clock(clock),
        .reset(reset),
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
        .fencei(FenceI),

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

        .sram4_addr(io_sram4_addr),
        .sram4_cen(io_sram4_cen),
        .sram4_wen(io_sram4_wen),
        .sram4_wmask(io_sram4_wmask),
        .sram4_wdata(io_sram4_wdata),
        .sram4_rdata(io_sram4_rdata),

        .sram5_addr(io_sram5_addr),
        .sram5_cen(io_sram5_cen),
        .sram5_wen(io_sram5_wen),
        .sram5_wmask(io_sram5_wmask),
        .sram5_wdata(io_sram5_wdata),
        .sram5_rdata(io_sram5_rdata),

        .sram6_addr(io_sram6_addr),
        .sram6_cen(io_sram6_cen),
        .sram6_wen(io_sram6_wen),
        .sram6_wmask(io_sram6_wmask),
        .sram6_wdata(io_sram6_wdata),
        .sram6_rdata(io_sram6_rdata),

        .sram7_addr(io_sram7_addr),
        .sram7_cen(io_sram7_cen),
        .sram7_wen(io_sram7_wen),
        .sram7_wmask(io_sram7_wmask),
        .sram7_wdata(io_sram7_wdata),
        .sram7_rdata(io_sram7_rdata)
    );

    reg AXI_Dcache_wlast;
    reg AXI_Dcache_wvalid;
    reg [63:0]AXI_Dcache_data_64;
    reg AXI_Dcache_data_first_over;
    reg [127:0]Dcache_to_AXI_data_temp;
//由于采用突发传输传输128位，而总线位宽为64位，所以需要传递两次，需要重新组织待传输的数据
//当检测到写地址信号时，第一个上升沿准备第一个写数据，并置写数据信号有效，第二个上升沿准备第二个写信号，同样置写数据信号有效
    always @(posedge clock)begin
        if(reset)begin
            AXI_Dcache_data_64 <= 64'b0;
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_wvalid <= 1'b0;
            AXI_Dcache_wlast <= 1'b0;
            Dcache_to_AXI_data_temp <= 128'b0;
        end
        else if( AXI_Dcache_data_first_over )begin
            AXI_Dcache_data_64 <= Dcache_to_AXI_data_temp[127:64];
            AXI_Dcache_wvalid <= 1'b1;
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_wlast <= 1'b1;
        end
        else if( AXI_Dcache_wr_req ) begin     //读请求只持续一个周期
            Dcache_to_AXI_data_temp <= AXI_Dcache_wr_data;
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
        .clock(clock),
        .reset(reset),

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

    reg [63:0]Data_while_SuspendLSU;
    always @(posedge clock)begin
        if(reset)
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

    //----------------------------------- WBreg -------------------------------------------------------------//
    reg WBreg_valid;
    wire WBreg_inst_enable;
    reg [31:0]WBreg_inst;
    wire WBreg_pc_enable;
    reg [31:0]WBreg_pc;
    wire WBreg_readmemdata_enable;
    reg [63:0]WBreg_readmemdata;
    wire WBreg_regwr_enable;
    reg WBreg_regwr;
    wire WBreg_rd_enable;
    reg [4:0]WBreg_rd;
    wire WBreg_aluout_enable;
    reg [63:0]WBreg_aluout;
    wire WBreg_memRd_enable;
    reg WBreg_memRd;
    wire WBreg_memtoreg_enable;
    reg WBreg_memtoreg;
    wire WBreg_CSRrd_enable;
    reg WBreg_CSRrd;
    wire WBreg_CSRrdata_enable;
    reg [63:0]WBreg_CSRrdata;

    assign WBreg_inst_enable = 1'b1;
    assign WBreg_pc_enable = 1'b1;
    assign WBreg_readmemdata_enable = 1'b1;
    assign WBreg_regwr_enable = 1'b1;
    assign WBreg_rd_enable = 1'b1;
    assign WBreg_memtoreg_enable = 1'b1;
    assign WBreg_aluout_enable = 1'b1;
    assign WBreg_memRd_enable = 1'b1;
    assign WBreg_CSRrd_enable = 1'b1;
    assign WBreg_CSRrdata_enable = 1'b1;

    ysyx_22050854_Reg #(32,32'b0) WBreg_geninst (clock, reset, MEMreg_inst, WBreg_inst, WBreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) WBreg_genPC (clock, reset, MEMreg_pc, WBreg_pc, WBreg_pc_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen0 (clock, reset, MEMreg_valid, WBreg_valid, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen1 (clock, reset, Memdata_to_WBreg, WBreg_readmemdata, WBreg_readmemdata_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen2 (clock, reset, MEMreg_regwr, WBreg_regwr, WBreg_regwr_enable);
    ysyx_22050854_Reg #(5,5'b0) WBreg_gen3 (clock, reset, MEMreg_rd, WBreg_rd, WBreg_rd_enable);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen4 (clock, reset, MEMreg_aluout, WBreg_aluout, WBreg_aluout_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen5 (clock, reset, MEMreg_memtoreg, WBreg_memtoreg, WBreg_memtoreg_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen6 (clock, reset, MEMreg_memrd, WBreg_memRd, WBreg_memRd_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen7 (clock, reset, MEMreg_CSRrd, WBreg_CSRrd, WBreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen8 (clock, reset, MEMreg_CSRrdata, WBreg_CSRrdata, WBreg_CSRrdata_enable);

    wire ebreak;
    assign ebreak = ( ( WBreg_inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011 ) &  WBreg_valid ) ? 1'b1 : 1'b0;

    //写回寄存器的数据，总共有三种可能 1.ALU计算值  2.从内存读出的数据 3.从CSR读出的数据
    wire [63:0]wr_reg_data;
    assign wr_reg_data = WBreg_memtoreg ? WBreg_readmemdata : ( WBreg_CSRrd ? WBreg_CSRrdata : WBreg_aluout );

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
        .clock(clock),
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

    //for difftest
    reg inst_finish;
    ysyx_22050854_Reg #(1,1'b0) inst_finish_gen (clock, reset, WBreg_valid, inst_finish, 1'b1);
    reg [31:0]inst_finish_pc;
    ysyx_22050854_Reg #(32,32'h0) inst_finishpc_gen (clock, reset, WBreg_pc, inst_finish_pc, 1'b1);
    reg [31:0]instruction_finsh;
    ysyx_22050854_Reg #(32,32'h0) instruction_finsh_gen (clock, reset, WBreg_inst, instruction_finsh, 1'b1);
    reg [31:0]access_mem_addr;
    ysyx_22050854_Reg #(32,32'h0) access_mem_addr_gen (clock, reset, WBreg_aluout[31:0], access_mem_addr, 1'b1);
    reg DIFFreg_memrd;
    ysyx_22050854_Reg #(1,1'b0) DIFFreg_memrd_gen (clock, reset, WBreg_memRd, DIFFreg_memrd, 1'b1);
    wire is_accessdevice;
    assign is_accessdevice = ( DIFFreg_memrd ) ? ( ( access_mem_addr > 32'h8fffffff ) ? 1'b1 : 1'b0 ) : 1'b0;

    //for debug
    wire [31:0]Data_Conflict_32;
    assign Data_Conflict_32 = {22'b0,ret_conflict_EXE,ret_conflict_MEM,ret_conflict_WB,store_conflict_EXE,store_conflict_MEM,store_conflict_WB,reg_Conflict_WB,reg_Conflict_MEM,reg_Conflict_EXE,Data_Conflict_block};

    import "DPI-C" function void get_next_pc_value(int next_pc);
    always@(*) get_next_pc_value(next_pc);
    import "DPI-C" function void get_pc_value(int pc_real);
    always@(*) get_pc_value(pc_real);
    import "DPI-C" function void get_inst_value(int inst);
    always@(*) get_inst_value(inst);

    wire [31:0]test_one;
    assign test_one = { 28'b0,Last_ALUsuspend_IFUsuspend    ,Last_Jump_Suspend   ,Last_DataBlock_Suspend    ,Last_JumpAndBlock_Suspend };
    import "DPI-C" function void get_PC_JUMP_Suspend_value(int test_one);
    always@(*) get_PC_JUMP_Suspend_value(test_one);

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

    import "DPI-C" function void get_Data_Conflict_value(int Data_Conflict_32);
    always@(*) get_Data_Conflict_value(Data_Conflict_32);

    wire [31:0]jump_32;
    assign jump_32 = {31'b0,jump};
    import "DPI-C" function void get_jump_value(int jump_32);
    always@(*) get_jump_value(jump_32);

    import "DPI-C" function void get_current_pc_value(int current_pc);
    always@(*) get_current_pc_value(current_pc);

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



    wire [31:0]Suspend_alu_32;
    assign Suspend_alu_32 = {31'b0,Suspend_ALU};
    import "DPI-C" function void get_Suspend_alu_value(int Suspend_alu_32);
    always@(*) get_Suspend_alu_value(Suspend_alu_32);

    import "DPI-C" function void get_MEMreginst_value(int MEMreg_inst);
    always@(*) get_MEMreginst_value(MEMreg_inst);
    import "DPI-C" function void get_MEMreg_pc_value(int MEMreg_pc);
    always@(*) get_MEMreg_pc_value(MEMreg_pc);
    wire [31:0]memreg;
    assign memreg = MEMreg_aluout[31:0];
    import "DPI-C" function void get_MEMreg_aluout_value(int memreg);
    always@(*) get_MEMreg_aluout_value(memreg);

    wire [31:0]MEMreg_valid_32;
    assign MEMreg_valid_32 = {31'b0,MEMreg_valid};
    import "DPI-C" function void get_MEMreg_valid_value(int MEMreg_valid);
    always@(*) get_MEMreg_valid_value(MEMreg_valid_32);

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

    wire [31:0]ebreak_32;
    assign ebreak_32 = { 31'b0,ebreak };
    import "DPI-C" function void get_ebreak_value(int ebreak_32);
    always@(*) get_ebreak_value(ebreak_32);

    wire [31:0]x10_32;
    assign x10_32 = x10[31:0];
    import "DPI-C" function void get_x10_value(int x10_32);
    always@(*) get_x10_value(x10_32);

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
//1.decode
`timescale 1ns/1ps  
//2.get operate num from resiger file
module ysyx_22050854_IDU(
    input [31:0]instr,
    output [4:0]rs1,
    output [4:0]rs2,
    output [4:0]rd,
    output [2:0]ExtOP,
    output  RegWr,
    output  [2:0]Branch,
    output  No_branch,
    output  MemtoReg,
    output  MemWr,
    output  MemRd,
    output  [2:0]MemOP,
    output  ALUsrc1,
    output  [1:0]ALUsrc2,
    output  [3:0]ALUctr,
    output  [3:0]MULctr,
    output  [2:0]ALUext
); 
    wire [6:0]op;
    wire [2:0]func3;
    wire [6:0]func7;

    assign op = instr[6:0];
    assign rs1 = instr[19:15];
    assign rs2 = ( instr == 32'h73 ) ? 5'd17 : instr[24:20]; //对于ecall指令，虽然指令上rs2的位置是全零，但按照指令的行为看，是要将x17的值写进CSR的mcause中
    assign rd = instr[11:7];
    assign func3 = instr[14:12];
    assign func7 = instr[31:25];

    //generate ExtOP for generate imm
    ysyx_22050854_MuxKeyWithDefault #(9,5,3) ExtOP_gen (ExtOP,op[6:2],3'b111,{
        5'b00000,3'b000, //lb lh lw ld  I
        5'b01000,3'b010, //sb sh sw sd  S
        5'b00100,3'b000, //addi slti ... I 
        5'b11001,3'b000, //jarl I
        5'b00110,3'b000, //addiw I
        5'b11000,3'b011, //BEQ BNE ... B
        5'b01101,3'b001, //lui  U
        5'b00101,3'b001, //auipc U
        5'b11011,3'b100  //jal J
    });

    //generate RegWr 是否写回寄存器
    wire RegWr_t;
    ysyx_22050854_MuxKeyWithDefault #(13,7,1) RegWr_gen (RegWr_t,op[6:0],1'b0,{
        7'b0110111,1'b1,  //lui
        7'b0010111,1'b1,  //auipc
        7'b0010011,1'b1,  //addi
        7'b0110011,1'b1,  //add 
        7'b1101111,1'b1,  //jar
        7'b1100111,1'b1,  //jarl
        7'b1100011,1'b0,  //beq bne ....
        7'b0000011,1'b1,  //lb lh lw ld lbu lhu lwu
        7'b0100011,1'b0,  //sb sh sw sd
        7'b0011011,1'b1,  //ADDIW
        7'b0111011,1'b1,  //ADDW
        7'b1110011,1'b1,   //ecall csrw csrr, but mret ebreak should not write register
        7'b0001111,1'b0   //fence.i 
    });
    assign RegWr = (instr == 32'h30200073) ? 0 : ( (instr == 32'h100073) ? 0 : RegWr_t);  //mret and ebreak not write

    //generate MemtoReg 写回寄存器的内容来自哪里 0-alu_out 1-mem_data
    assign MemtoReg = op == 7'b0000011 ? 1'b1 : 1'b0;

    //generate Branch 
    ysyx_22050854_MuxKey #(22,8,3) Branch_gen (Branch,{op[6:2],func3},{
        8'b11011000,3'b001, //jal
        8'b11011001,3'b001, //jal
        8'b11011010,3'b001, //jal
        8'b11011011,3'b001, //jal
        8'b11011100,3'b001, //jal
        8'b11011101,3'b001, //jal
        8'b11011110,3'b001, //jal
        8'b11011111,3'b001, //jal
        8'b11001000,3'b010, //jalr
        8'b11001001,3'b010, //jalr
        8'b11001010,3'b010, //jalr
        8'b11001011,3'b010, //jalr
        8'b11001100,3'b010, //jalr
        8'b11001101,3'b010, //jalr
        8'b11001110,3'b010, //jalr
        8'b11001111,3'b010, //jalr
        8'b11000000,3'b100, //beq
        8'b11000001,3'b101, //bneq
        8'b11000100,3'b110, //blt
        8'b11000101,3'b111, //bge
        8'b11000110,3'b110, //bltu
        8'b11000111,3'b111  //bgeu
    });

    //generate No_branch pc + 4
    ysyx_22050854_MuxKeyWithDefault #(11,7,1) No_branch_gen (No_branch,op,1'b0,{
        7'b0110111,1'b1,  //lui
        7'b0010111,1'b1,  //auipc
        7'b0000011,1'b1,  //ld
        7'b0100011,1'b1,  //sd
        7'b0010011,1'b1,  //addi
        7'b0110011,1'b1,  //add
        7'b1110011,1'b1,  //csrrw csrr but not ecall mret
        7'b0011011,1'b1,  //slliw
        7'b0111011,1'b1,  //sllw
        7'b0111011,1'b1,   //mulw
        7'b0001111,1'b1   //fence.I
    });

    //generate MemWr 是否写存储器
    assign MemWr = op == 7'b0100011 ? 1'b1 : 1'b0;

    //generate MemRd 是否读存储器
    assign MemRd = op == 7'b0000011 ? 1'b1 : 1'b0;

    //generate MemOP 如何写存储器
    ysyx_22050854_MuxKeyWithDefault #(11,8,3) MemOP_gen (MemOP,{op[6:2],func3},3'b111,{
        8'b00000000,3'b000,  //lb
        8'b00000001,3'b001,  //lh
        8'b00000010,3'b010,  //lw
        8'b00000011,3'b011,  //ld
        8'b00000100,3'b100,  //lbu
        8'b00000101,3'b101,  //lhu
        8'b00000110,3'b110,  //lwu
        8'b01000000,3'b000,  //sb
        8'b01000001,3'b001,  //sh
        8'b01000010,3'b010,  //sw
        8'b01000011,3'b011   //sd
    });

    //generate ALUsrc1    0---rs1  1---pc
   ysyx_22050854_MuxKeyWithDefault #(11,5,1) ALUsrc1_gen (ALUsrc1,op[6:2],1'b1,{
        5'b01101,1'b0, //lui (copy,don't need alu_src1)
        5'b00101,1'b1, //auipc
        5'b00100,1'b0, //addiq
        5'b01100,1'b0, //add mul
        5'b11011,1'b1, //jal
        5'b11001,1'b1, //jalr
        5'b11000,1'b0, //beq
        5'b00000,1'b0, //load
        5'b01000,1'b0, //store
        5'b00110,1'b0, //ADDIW sraiw
        5'b01110,1'b0  //ADDW MULW    
    });

    //generate ALUsrc2   00---rs2   01---imm  10---4
   ysyx_22050854_MuxKeyWithDefault #(11,5,2)  ALUsrc2_gen (ALUsrc2,op[6:2],2'b00,{
        5'b01101,2'b01, //lui
        5'b00101,2'b01, //auipc
        5'b00100,2'b01, //addi
        5'b01100,2'b00, //add mul
        5'b11011,2'b10, //jal
        5'b11001,2'b10, //jalr
        5'b11000,2'b00, //beq
        5'b00000,2'b01, //load
        5'b01000,2'b01, //store
        5'b00110,2'b01, //ADDIW
        5'b01110,2'b00 //ADDW MULW    
    });

    //generate ALUext for rv64I
    ysyx_22050854_MuxKey #(35,10,3) ALUext_gen (ALUext,{op[6:2],func3,func7[5],func7[0]},{
        10'b0011000000,3'b010,  // + addiw
        10'b0011000010,3'b010,  // + addiw
        10'b0011000001,3'b010,  // + addiw
        10'b0011000011,3'b010,  // + addiw
        10'b0111000000,3'b010,  // + addw
        10'b0111000010,3'b010,  // - subw
        10'b0011000100,3'b011,  // <<  slliw
        10'b0011010100,3'b011,  // >>  srliw
        10'b0011010110,3'b011,  // >>> sraiw
        10'b0111000100,3'b011,  // <<  sllw
        10'b0111010100,3'b011,  // >>  srlw
        10'b0111010110,3'b011,  // >>> sraw
        10'b0010001000,3'b001,  //  slti compare
        10'b0010001010,3'b001,  //  slti compare
        10'b0010001001,3'b001,  //  slti compare
        10'b0010001011,3'b001,  //  slti compare
        10'b0010001100,3'b001,  //  sltiu compare
        10'b0010001110,3'b001,  //  sltiu compare
        10'b0010001101,3'b001,  //  sltiu compare
        10'b0010001111,3'b001,  //  sltiu compare
        10'b0110001000,3'b001,  //  slt compare
        10'b0110001100,3'b001,  //  sltu compare
        10'b0110000001,3'b100,  //mul
        10'b0110000101,3'b101,  //mulh
        10'b0110001001,3'b101,  //mulhsu
        10'b0110001101,3'b101,  //mulhu
        10'b0110010001,3'b110,  //div
        10'b0110010101,3'b110,  //divu
        10'b0110011001,3'b111,  //rem
        10'b0110011101,3'b111,  //remu
        10'b0111000001,3'b100,  //mulw
        10'b0111010001,3'b110,  //divw
        10'b0111010101,3'b110,  //divuw
        10'b0111011001,3'b111,  //remw
        10'b0111011101,3'b111   //remuw
    });

    //generate ALUctr according to op funct3,funct7
    ysyx_22050854_MuxKeyWithDefault #(119,9,4) ALUctr_gen (ALUctr,{op[6:2],func3,func7[5]},4'b1111,{
        9'b011010000,4'b0011,  // lui copy
        9'b011010001,4'b0011,  // lui copy
        9'b011010010,4'b0011,  // lui copy
        9'b011010011,4'b0011,  // lui copy
        9'b011010100,4'b0011,  // lui copy
        9'b011010101,4'b0011,  // lui copy
        9'b011010110,4'b0011,  // lui copy
        9'b011010111,4'b0011,  // lui copy
        9'b011011000,4'b0011,  // lui copy
        9'b011011001,4'b0011,  // lui copy
        9'b011011010,4'b0011,  // lui copy
        9'b011011011,4'b0011,  // lui copy
        9'b011011100,4'b0011,  // lui copy
        9'b011011101,4'b0011,  // lui copy
        9'b011011110,4'b0011,  // lui copy
        9'b011011111,4'b0011,  // lui copy
        9'b001010000,4'b0000,  // auipc +
        9'b001010001,4'b0000,  // auipc +
        9'b001010010,4'b0000,  // auipc +
        9'b001010011,4'b0000,  // auipc +
        9'b001010100,4'b0000,  // auipc +
        9'b001010101,4'b0000,  // auipc +
        9'b001010110,4'b0000,  // auipc +
        9'b001010111,4'b0000,  // auipc +
        9'b001011000,4'b0000,  // auipc +
        9'b001011001,4'b0000,  // auipc +
        9'b001011010,4'b0000,  // auipc +
        9'b001011011,4'b0000,  // auipc +
        9'b001011100,4'b0000,  // auipc +
        9'b001011101,4'b0000,  // auipc +
        9'b001011110,4'b0000,  // auipc +
        9'b001011111,4'b0000,  // auipc +
        9'b001000000,4'b0000,  // + addi
        9'b001000001,4'b0000,  //   addi  
        9'b001000100,4'b0010,  //  slti compare
        9'b001000101,4'b0010,  //  slti compare
        9'b001000110,4'b1010,  //  sltiu compare
        9'b001000111,4'b1010,  //  sltiu compare
        9'b001001000,4'b0100,  // ^  xori
        9'b001001001,4'b0100,  // ^  xori
        9'b001001100,4'b0110,  // |  ori
        9'b001001101,4'b0110,  // |  ori
        9'b001001110,4'b0111,  // & andi
        9'b001001111,4'b0111,  // & andi
        9'b001000010,4'b0001,  // << slli 
        9'b001001010,4'b0101,  // >> srli
        9'b001001011,4'b1101,  // >>> srai
        9'b001100010,4'b0001,  // <<  slliw
        9'b001101010,4'b0101,  // >>  srliw
        9'b001101011,4'b1101,  // >>> sraiw
        9'b011100010,4'b0001,  // << sllw
        9'b011101010,4'b0101,  // >> srlw
        9'b011101011,4'b1101,  // >>> sraw
        9'b011100000,4'b0000,  // + addw
        9'b011100001,4'b1000,  // - subw
        9'b001100000,4'b0000,  // + addiw
        9'b001100001,4'b0000,  // + addiw  
        9'b011000000,4'b0000,  // + add
        9'b011000001,4'b1000,  // - sub
        9'b011000010,4'b0001,  // << sll
        9'b011000100,4'b0010,  // slt compare
        9'b011000110,4'b1010,  // sltu compare
        9'b011001000,4'b0100,  // ^ xor
        9'b011001010,4'b0101,  // >> srl
        9'b011001011,4'b1101,  // >>> sra
        9'b011001100,4'b0110,  // | or
        9'b011001110,4'b0111,  // & and
        9'b110110000,4'b0000,  // pc + 4 jal
        9'b110110001,4'b0000,  // pc + 4 jal
        9'b110110010,4'b0000,  // pc + 4 jal
        9'b110110011,4'b0000,  // pc + 4 jal
        9'b110110100,4'b0000,  // pc + 4 jal
        9'b110110101,4'b0000,  // pc + 4 jal
        9'b110110110,4'b0000,  // pc + 4 jal
        9'b110110111,4'b0000,  // pc + 4 jal
        9'b110111000,4'b0000,  // pc + 4 jal
        9'b110111001,4'b0000,  // pc + 4 jal
        9'b110111010,4'b0000,  // pc + 4 jal
        9'b110111011,4'b0000,  // pc + 4 jal
        9'b110111100,4'b0000,  // pc + 4 jal
        9'b110111101,4'b0000,  // pc + 4 jal
        9'b110111110,4'b0000,  // pc + 4 jal
        9'b110111111,4'b0000,  // pc + 4 jal
        9'b110010000,4'b0000,  // pc + 4 jalr
        9'b110010001,4'b0000,  // pc + 4 jalr 
        9'b110000000,4'b0010,  // signed compare beq
        9'b110000001,4'b0010,  // signed compare beq
        9'b110000010,4'b0010,  // signed compare bne
        9'b110000011,4'b0010,  // signed compare bne
        9'b110001000,4'b0010,  // signed compare blt
        9'b110001001,4'b0010,  // signed compare blt
        9'b110001010,4'b0010,  // signed compare bge
        9'b110001011,4'b0010,  // signed compare bge
        9'b110001100,4'b1010,  // unsigned compare bltu
        9'b110001101,4'b1010,  // unsigned compare bltu
        9'b110001110,4'b1010,  // unsigned compare bgeu
        9'b110001111,4'b1010,  // unsigned compare bgeu
        9'b000000000,4'b0000,  // + lb  rs1 + imm
        9'b000000001,4'b0000,  // + lb
        9'b000000010,4'b0000,  // + lh
        9'b000000011,4'b0000,  // + lh
        9'b000000100,4'b0000,  // + lw
        9'b000000101,4'b0000,  // + lw
        9'b000000110,4'b0000,  // + ld
        9'b000000111,4'b0000,  // + ld
        9'b000001000,4'b0000,  // + lbu
        9'b000001001,4'b0000,  // + lbu
        9'b000001010,4'b0000,  // + lhu
        9'b000001011,4'b0000,  // + lhu
        9'b000001100,4'b0000,  // + lwu
        9'b000001101,4'b0000,  // + lwu
        9'b010000000,4'b0000,  // + sb
        9'b010000001,4'b0000,  // + sb
        9'b010000010,4'b0000,  // + sh
        9'b010000011,4'b0000,  // + sh
        9'b010000100,4'b0000,  // + sw
        9'b010000101,4'b0000,  // + sw
        9'b010000110,4'b0000,  // + sd
        9'b010000111,4'b0000  // + sd
    });

    ysyx_22050854_MuxKeyWithDefault #(13,9,4)  gen_64M_ctr (MULctr,{op[6:2],func3,func7[0]},4'b0000,{
        9'b011000001,4'b1001,  //mul
        9'b011000011,4'b0001,  //mulh
        9'b011000101,4'b0010,  //mulhsu
        9'b011000111,4'b0011,  //mulhu
        9'b011001001,4'b0100,  //div
        9'b011001011,4'b0101,  //divu
        9'b011001101,4'b0110,  //rem
        9'b011001111,4'b0111,  //remu
        9'b011100001,4'b1000,  //mulw
        9'b011101001,4'b1100,  //divw
        9'b011101011,4'b1101,  //divuw
        9'b011101101,4'b1110,  //remw
        9'b011101111,4'b1111   //remuw
    });

endmodule
`timescale 1ns/1ps
module ysyx_22050854_imm_gen(
    input [31:0]instr,
    input [2:0]ExtOP,
    output reg[63:0]imm
);
    wire [63:0]immI,immU,immS,immB,immJ;
    assign immI = {{52{instr[31]}},instr[31:20]};
    assign immU = {{32{instr[31]}},instr[31:12],12'b0};
    assign immS = {{52{instr[31]}},instr[31:25],instr[11:7]};
    assign immB = {{52{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
    assign immJ = {{44{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};

    ysyx_22050854_MuxKeyWithDefault #(5,3,64) imm_gen (imm,ExtOP,64'b0,{
        3'b000,immI,
        3'b001,immU,
        3'b010,immS,
        3'b011,immB,
        3'b100,immJ
    });

endmodule
`timescale 1ns/1ps
module ysyx_22050854_src_gen(
    input ALUsrc1,
    input [1:0]ALUsrc2,
    input [31:0]pc,
    input [63:0]imm,
    input [63:0]src1,
    input [63:0]src2,
    output [63:0]alu_src1,
    output [63:0]alu_src2
);
    ysyx_22050854_MuxKeyWithDefault #(2,1,64) src1_gen(alu_src1,ALUsrc1,64'd0,{
        1'd0,src1,
        1'd1,{{32'b0},pc}
    });

    ysyx_22050854_MuxKeyWithDefault #(3,2,64) src2_gen(alu_src2,ALUsrc2,64'd0,{
        2'b00,src2,
        2'b01,imm,
        2'b10,64'd4
    });

endmodule

module ysyx_22050854_pc(
    input reset,
    input clock,
    input IDreg_valid,
    input Data_Conflict,
    input suspend,
    input [2:0]Branch,
    input No_branch,
    input is_csr_pc,
    input [31:0]csr_pc,
    input unsigned_compare,
    input [63:0]alu_src1,
    input [63:0]alu_src2,
    input [63:0]src1,
    input [63:0]imm,
    output jump,
    output reg[31:0]pc,
    output reg[31:0]next_pc
);
    wire zero;
    wire less;
    assign zero = ( ( $signed(alu_src1) ) - ( $signed(alu_src2) ) == 0 ) ? 1'b1 : 1'b0;
    assign less = unsigned_compare ? ( alu_src1 < alu_src2 ? 1'b1 : 1'b0 ) : ( ($signed(alu_src1)) < ($signed(alu_src2)) ? 1'b1 : 1'b0 );

    wire [2:0]PCsrc;
    wire [31:0]PCsrc1,PCsrc2;
    //default----00---pc + 4 但是这样的话 每个上升沿都会使pc+4
    //于是 我想再译出一位控制信号，当这个信号为1 时才有效
    //PCsrc[2]用于指示这是一个跳转指令,并且进行了跳转
    ysyx_22050854_MuxKeyWithDefault #(20,5,3) gen_PC3src (PCsrc,{Branch,zero,less},3'b000,{
        5'b00100,3'b110, //jal
        5'b00101,3'b110, //jal
        5'b00110,3'b110, //jal
        5'b00111,3'b110, //jal
        5'b01000,3'b111, //jalr
        5'b01001,3'b111, //jalr
        5'b01010,3'b111, //jalr
        5'b01011,3'b111, //jalr
        5'b10010,3'b110, //equal
        5'b10011,3'b110, //equal          //beq 但是不相等的默认为00 ,就是不跳转
        5'b10100,3'b110, //not equal
        5'b10101,3'b110, //not equal
        5'b11001,3'b110, //less           //blt bltu
        5'b11011,3'b110, //less
        5'b11000,3'b000, //not less 
        5'b11010,3'b000, //not less
        5'b11100,3'b110, //greater bgeu less = 0   //bge bgeu
        5'b11110,3'b110, //greater bgeu
        5'b11101,3'b000, //not greater bgeu less = 1
        5'b11111,3'b000  //not greater bgeu
    });
    //如果存在数据冲突且需要阻塞，那这个确定跳转的计算并不准确
    //ecall/mret的next_pc是从CSR中取出的，我的逻辑是译码过后就写CSR，CSR寄存器按理说不会出现阻塞的情况
    assign jump = ( ( PCsrc[2] & (~Data_Conflict) & ~suspend ) | is_csr_pc ) & IDreg_valid;

    //00---pc + 4  10---pc + imm   
    ysyx_22050854_MuxKey #(2,1,32) gen_PCsrc1 (PCsrc1,PCsrc[1],{
        1'b0,32'd4,
        1'b1,imm[31:0]
    });

    ysyx_22050854_MuxKey #(2,1,32) gen_PCsrc2 (PCsrc2,PCsrc[0],{
        1'b0,pc,
        1'b1,src1[31:0]
    });

    always@(*)begin
        if(reset)                         //复位
            next_pc = 32'h80000000;
        else if( (is_csr_pc == 1'b1) )     //ecall mret
            next_pc = csr_pc;
        else if( (Branch != 3'b000) )       //跳转指令
            next_pc = PCsrc1 + PCsrc2;
        else if( (No_branch == 1'b1) )      //非跳转指令 其实也包括ecall mret 但这里我利用先判断前者
            next_pc = pc + 32'd4;
        else                           //未定义指令
            next_pc = pc + 32'd0;
    end

    always@(posedge clock)begin
        if(reset)
            pc <= 32'h80000000;
        else if(~Data_Conflict & ~suspend & IDreg_valid) //如果遇到了数据阻塞或者暂停，PC保持不变
            pc <= next_pc;
    end

    import "DPI-C" function void get_PCsrc1_value(int PCsrc1);
    always@(*) get_PCsrc1_value(PCsrc1);

    import "DPI-C" function void get_PCsrc2_value(int PCsrc2);
    always@(*) get_PCsrc2_value(PCsrc2);

endmodule
//`timescale 1ns/1ps
module ysyx_22050854_RegisterFile  (
  input clock,
  input [63:0] wdata,
  input reg[4:0] waddr,
  input wen,
  input [4:0] raddra,
  input [4:0] raddrb,
  output reg[63:0] rdata1,
  output reg[63:0] rdata2,

  input [4:0]test_addr1,
  input [4:0]test_addr2,
  output reg[63:0]test_rdata1,
  output reg[63:0]test_rdata2
);
  reg [63:0] rf [31:0];
  always @(posedge clock) begin
    if(waddr==5'd0)
      rf[waddr] <= 64'd0;
    else begin
      if(wen) begin
        rf[waddr] <= wdata;
      end
    end
  end

  import "DPI-C" function void set_gpr_ptr(input logic [63:0] a []);
  initial set_gpr_ptr(rf);  // rf为通用寄存器的二维数组变量
  
  always @(*) begin
    rf[5'b0] = 64'b0;
  end

  always@(*)begin
    if(raddra == 5'd0)
      rdata1 = 64'd0;
    else
      rdata1 = rf[raddra];
  end

  always@(*)begin
    if(raddrb == 5'd0)
      rdata2 = 64'd0;
    else
      rdata2 = rf[raddrb];
  end

  always@(*)begin
    if(test_addr1==5'd0)
      test_rdata1 = 64'd0;
    else
      test_rdata1 = rf[test_addr1];
  end

  always@(*)begin
    if(test_addr2==5'd0)
      test_rdata2 = 64'd0;
    else
      test_rdata2 = rf[test_addr2];
  end

endmodule
module ysyx_22050854_CSRegister  (
  input clock,
  input reset,
  input [63:0] wdata1,
  input [63:0] wdata2,
  input [11:0] waddr1,
  input [11:0] waddr2,
  input wen,
  input wen2,
  input ren,
  input [11:0] raddr,
  output [63:0] rdata,
  output reg timer_interrupt
);
  reg [63:0] csrf [31:0]; //define 32 cs register
  wire [4:0]csr_addr1;
  wire [4:0]csr_addr2;
  wire [4:0]csr_raddr;
  import "DPI-C" function void set_csr_ptr(input logic [63:0] a []);
  initial set_csr_ptr(csrf);  // rf为通用寄存器的二维数组变量

  ysyx_22050854_MuxKey #(6,12,5) gen_csraddr1 (csr_addr1,waddr1,{
    12'h300,5'd2,  //mstatus
    12'h305,5'd0,  //mtvec
    12'h341,5'd1,  //mepc
    12'h342,5'd3,  //mcause
    12'h304,5'd4,  //mie
    12'h344,5'd5   //mip
  });

  ysyx_22050854_MuxKey #(6,12,5) gen_csraddr2 (csr_addr2,waddr2,{
    12'h300,5'd2,  //mstatus
    12'h305,5'd0,  //mtvec
    12'h341,5'd1, //mepc
    12'h342,5'd3, //mcause
    12'h304,5'd4,  //mie
    12'h344,5'd5   //mip
  });

  ysyx_22050854_MuxKey #(6,12,5) gen_csr_raddr (csr_raddr,raddr,{
    12'h300,5'd2,  //mstatus
    12'h305,5'd0,  //mtvec
    12'h341,5'd1, //mepc
    12'h342,5'd3, //mcause
    12'h304,5'd4,  //mie
    12'h344,5'd5   //mip
  });

  assign rdata = ren ? csrf[csr_raddr] : 64'd0;  //read csr

  always @(posedge clock) begin        //write csrs
    if(wen)
      csrf[csr_addr1] <= wdata1;
    if(wen2)
      csrf[csr_addr2] <= wdata2;
  end

  reg [63:0]mtime;
  reg [63:0]mtimecmp;
  //计时器逻辑，每个周期自增
  always @(posedge clock) begin
    if(reset)
      mtime <= 64'd0;
    else
      mtime <= mtime + 1'd1;
  end
  //中断逻辑 根据条件判断是否产生计时器中断
  always @(posedge clock) begin
    if(reset)begin
      csrf[5] <= 64'd0;
      timer_interrupt <= 1'd0;
      csrf[2][3] <= 1'd1; //mstatus 的 MIE位
      csrf[4][7] <= 1'd1; //mie 的 MTIE 位
    end
    else begin
      csrf[5][7] <= ( (csrf[2][3] & csrf[4][7]) & (mtime >= mtimecmp) );
      timer_interrupt <= csrf[5][7];
    end
  end
  //
  always @(posedge clock) begin
    if(reset)
      mtimecmp  <= 64'd100;
    else if(mtime >= mtimecmp)
      mtimecmp <= mtimecmp + 64'd100;
  end


endmodule
//operation
`timescale 1ns/1ps
`define ysyx_22050854_USE_MULTIPLIER_1

module ysyx_22050854_alu(
    input clock,
    input reset,
    input EXEreg_valid,
    input [3:0]ALUctr,
    input [3:0]MULctr,
    input [2:0]ALUext,
    input [63:0]src1,
    input [63:0]src2,
    output alu_busy,
    output [63:0]alu_out 
);
    wire [31:0]alu_temp_32;
    ysyx_22050854_MuxKey #(3,4,32) gen_alu_temp_32 (alu_temp_32, ALUctr, {
        4'b0001,src1[31:0] << src2[4:0], //slliw sllw
        4'b0101,src1[31:0] >> src2[4:0], //srliw srlw
        4'b1101,($signed(src1[31:0])) >>> src2[4:0] //sraiw sraw
    });

    wire [63:0]alu_temp;
    ysyx_22050854_MuxKeyWithDefault #(11,4,64) gen_alu_temp (alu_temp,ALUctr,64'd0,{
        4'b0000,src1 + src2,
        4'b0001,src1 << src2[5:0], //sll,slli
        4'b0010,($signed(src1)) - ($signed(src2)),  //slt beq bne blt bge 
        4'b0011,64'd0 + src2,  //lui copy
        4'b0100,src1 ^ src2,
        4'b0101,src1 >> src2[5:0],  //srl srli
        4'b0110,src1 | src2,
        4'b0111,src1 & src2,
        4'b1000,src1 - src2,  //sub
        4'b1101,($signed(src1)) >>> src2[5:0], //srai
        4'b1010,src1 - src2  //sltu bltu bgeu sltiu
    });

    wire less;
    assign less = ALUctr == 4'b0010 ? ( ($signed(src1)) < ($signed(src2)) ? 1 : 0) : (src1 < src2 ? 1 : 0);

    wire op_mul_t;
    wire op_mul;
    wire mul_valid;
    wire mulw;
    wire [1:0]mul_signed;
    wire mul_doing;
    wire mul_ready;
    wire mul_out_valid;
    wire [63:0]mul_result_hi;
    wire [63:0]mul_result_lo;
    ysyx_22050854_MuxKey #(5,4,1) gen_op_mul (op_mul_t,MULctr,{
        4'b1001,1'b1, //mul
        4'b0001,1'b1,
        4'b0010,1'b1,
        4'b0011,1'b1,
        4'b1000,1'b1
    });
    assign op_mul = op_mul_t & EXEreg_valid;
    assign mul_valid = op_mul & !mul_doing & !mul_out_valid;
    assign mulw = ( MULctr == 4'b1000 ) ? 1'b1 : 1'b0;
    ysyx_22050854_MuxKey #(5,4,2) gen_mul_signed (mul_signed, MULctr, {
        4'b1001,2'b11, //mul
        4'b0001,2'b11,
        4'b0010,2'b10,
        4'b0011,2'b00,
        4'b1000,2'b11
    });

    `ifdef ysyx_22050854_USE_MULTIPLIER_1
    ysyx_22050854_multiplier_v1 shiftadd_multiplier (
        .clock(clock),
        .reset(reset),
        .mul_valid(mul_valid), //1:input data valid
        .flush(1'b0),     //1:cancel multi
        .mulw(mulw),      //1:32 bit multi
        .mul_signed(mul_signed),  //2’b11（signed x signed）；2’b10（signed x unsigned）；2’b00（unsigned x unsigned）；
        .multiplicand(src1), //被乘数
        .multiplier(src2),   //乘数
        .mul_doing(mul_doing),
        .mul_ready(mul_ready),         //为高表示乘法器准备好，表示可以输入数据
        .out_valid(mul_out_valid),         //为高表示乘法器输出的结果有效
        .result_hi(mul_result_hi),
        .result_lo(mul_result_lo)
    );
    `else
    ysyx_22050854_multiplier_v2 use_multiplier_2 (
        .clock(clock),
        .reset(reset),
        .mul_valid(mul_valid), //1:input data valid
        .flush(1'b0),     //1:cancel multi
        .mulw(mulw),      //1:32 bit multi
        .mul_signed(mul_signed),  //2’b11（signed x signed）；2’b10（signed x unsigned）；2’b00（unsigned x unsigned）；
        .multiplicand(src1), //被乘数
        .multiplier(src2),   //乘数
        .mul_doing(mul_doing),
        .mul_ready(mul_ready),             //为高表示乘法器准备好，表示可以输入数据
        .out_valid(mul_out_valid),         //为高表示乘法器输出的结果有效
        .result_hi(mul_result_hi),
        .result_lo(mul_result_lo)
    );
    `endif

    wire op_div;
    wire div_valid;
    wire divw;
    wire div_signed;
    wire div_ready;
    wire div_out_valid;
    wire div_doing;
    wire [63:0]div_out_quoitient;
    wire [63:0]div_out_remainder;
    wire div_t;
    ysyx_22050854_MuxKey #(8,4,1) gen_op_div (div_t,MULctr,{
        4'b0100,1'b1,
        4'b0101,1'b1,
        4'b0110,1'b1,
        4'b0111,1'b1,
        4'b1100,1'b1,
        4'b1101,1'b1,
        4'b1110,1'b1,
        4'b1111,1'b1
    });
    assign op_div = div_t & EXEreg_valid;
    assign div_valid = op_div & !div_doing & !div_out_valid; //只持续两个周期
    assign divw = MULctr[3]; //由MULctr第4位决定
    assign div_signed = ~MULctr[0];
    ysyx_22050854_divider_1 shift_divider_1 (
        .clock(clock),
        .reset(reset),
        .dividend(src1),  //被除数
        .divisor(src2),   //除数
        .div_valid(div_valid),       //为高表示输入的数据有效，如果没有新的除法输入，在除法被接受的下一个周期要置低
        .divw(divw),            //为高表示输入是32位除法
        .div_signed(div_signed),      //为高表示是有符号除法
        .flush(1'b0),           //为高表示除法无效
        .div_doing(div_doing),
        .div_ready(div_ready),      //为高表示除法器空闲，可以输入数据
        .out_valid(div_out_valid),      //为高表示除法器输出结果有效
        .quotient(div_out_quoitient), //商
        .remainder(div_out_remainder) //余数
    );

    assign alu_busy = ( op_mul && !mul_out_valid ) | ( op_div && !div_out_valid );

    wire [31:0]div_doing_32;
    assign div_doing_32 = {31'b0,div_doing};
    import "DPI-C" function void get_div_doing_value(int div_doing_32);
    always@(*) get_div_doing_value(div_doing_32);

    ysyx_22050854_MuxKey #(8,3,64) gen_alu_out (alu_out, ALUext, {
        3'b000,alu_temp,
        3'b001,{63'd0,less},
        3'b010,{{32{alu_temp[31]}},alu_temp[31:0]}, //先截断，然后按符号位扩展 addw addiw subw
        3'b011,{{32{alu_temp_32[31]}},alu_temp_32},  //按符号位扩展 slliw sllw sraiw sraw
        3'b100,mul_result_lo, //mul mulw
        3'b101,mul_result_hi,  //mulh
        3'b110,div_out_quoitient, //div divu divw divwu
        3'b111,div_out_remainder    //rem remu remwu remw
    });

endmodule
/*
模块功能：
    根据RISCV指令集规则
    需要实现32 x 32 的有符号乘法   以及64 x 64 的signed x signed / signed x unsigned / unsigned x unsigned
    实现 32x32 / 64x64 位信号的有符号或无符号的相乘
    采用移位加的方法实现
    9.13优化 结束运算的另一个标志是乘数为0
*/


module ysyx_22050854_multiplier_v1(
    input clock,
    input reset,
    input mul_valid, //1:input data valid
    input flush,     //1:cancel multi
    input mulw,      //1:32 bit multi
    input [1:0]mul_signed,  //2’b11（signed x signed）；2’b10（signed x unsigned）；2’b00（unsigned x unsigned）；
    input [63:0]multiplicand, //被乘数
    input [63:0]multiplier,   //乘数
    output mul_doing,
    output mul_ready,         //为高表示乘法器准备好，表示可以输入数据
    output out_valid,         //为高表示乘法器输出的结果有效
    output [63:0]result_hi,
    output [63:0]result_lo
);

// 32 * 32
reg [63:0]multiplicand_temp;
reg [63:0]multiplier_temp;
reg mul32ss_go;  //32 x 32 符号相乘准备好标志  直到运算结束才置0
reg mul_ready_t;
always @(posedge clock)begin
    if(reset)begin
        mul32ss_go <= 1'b0;
        mul_ready_t <= 1'b1;
        multiplicand_temp <= 64'b0;
        multiplier_temp <= 64'b0;
    end
    else if(mul_valid & mulw & (mul_signed == 2'b11) & mul_ready_t)begin // 32位 有符号乘法
        multiplicand_temp <= { {32{multiplicand[31]}} , multiplicand[31:0] };
        multiplier_temp <= multiplier;
        mul32ss_go <= 1'b1;
        mul_ready_t <= 1'b0;
    end
    else if ( ((mul_count >= 7'd31) | ( multiplier_temp == 64'b0)) & mul32ss_go )begin  //当乘数为0或计数32次后 32 x 32运算结束 
        multiplicand_temp <= 64'b0;
        multiplier_temp <= 64'b0;
        mul32ss_go <= 1'b0;
        mul_ready_t <= 1'b1;
    end
end

reg [6:0]mul_count; //用于给移位计数 需要移位32次 采用6位数 大一位
always @(posedge clock)begin
    if(reset)begin
        mul_count <= 7'd0;
    end
    else if( mul32ss_go & ((mul_count >= 7'd31) | ( multiplier_temp == 64'b0)) )
        mul_count <= 7'd0;
    else if( mul64_go & ( (mul_count >= 7'd63) |  multiplier_temp == 64'b0) )
        mul_count <= 7'd0;
    else if( mul32ss_go | mul64_go )begin //计数的条件是乘法控制字有效
        mul_count <= mul_count + 7'b1;
    end
    else 
        mul_count <= 7'd0;
end

reg [63:0]mul32_result_temp; //存放32 x 32 位的乘积
//启动 32 x 32 位无符号数的运算
always @(posedge clock)begin
    if(reset)begin
        mul32_result_temp <= 64'b0;
    end
    else if(mul32ss_go & (mul_count < 7'd32))begin
        if( multiplier_temp[0] & ( mul_count < 7'd31 ) )begin //如果乘数的最低位为1
            mul32_result_temp <= mul32_result_temp + multiplicand_temp;
        end
        else if(multiplier_temp[0] & ( mul_count == 7'd31 ))begin //对于补码乘法，最后一次被累加的乘积需要使用补码减法来操作
            mul32_result_temp <= mul32_result_temp - multiplicand_temp;
        end
        multiplicand_temp <= ( multiplicand_temp << 1 ); //被乘数左移一位
        multiplier_temp <= ( multiplier_temp >> 1 ); //乘数右移一位
    end
    else begin
        mul32_result_temp <= 64'b0;
    end
end

reg mul32_over;
always @(posedge clock)begin
    if(reset)
        mul32_over <= 1'b0;
    else if( mul32ss_go & ((mul_count >= 7'd31) | ( multiplier_temp == 64'b0)) )
        mul32_over <= 1'b1;
    else
        mul32_over <= 1'b0;
end

//64 * 64 
reg [127:0]multiplicand_temp_128; //64位运算的被乘数寄存器
reg mul64_go;
reg mul64_multiplier_sign;
always @(posedge clock)begin
    if(reset)begin
        multiplicand_temp_128 <= 128'b0;
        mul64_go <= 1'b0;
        mul64_multiplier_sign <= 1'b0;
    end
    else if( mul_valid & (~mulw) &  mul_ready_t)begin
        mul_ready_t <= 1'b0;
        mul64_go <= 1'b1;
        mul64_multiplier_sign <= mul_signed[0]; //乘数是否有符号取决于mul_signed[0]
        multiplier_temp <= multiplier;
        if( mul_signed[1] )                   //如果被乘数是有符号相乘
            multiplicand_temp_128 <= { {64{multiplicand[63]}} , multiplicand };
        else
            multiplicand_temp_128 <= { 64'b0,multiplicand };
    end
    else if( ( (mul_count >= 7'd63) |  multiplier_temp == 64'b0) & mul64_go) begin  // 64 x 64 运算完成
        mul64_go <= 1'b0;
        mul_ready_t <= 1'b1;
        mul64_multiplier_sign <= 1'b0;
        multiplier_temp <= 64'd0;
        multiplicand_temp_128 <= 128'd0;
    end
end

reg [127:0]mul64_result_temp;
always @(posedge clock)begin
    if(reset)
        mul64_result_temp <= 128'b0;
    else if( mul64_go & ( mul_count < 7'd64) )begin
        if( multiplier_temp[0] & ( mul_count == 7'd63 ) & mul64_multiplier_sign )begin //对于补码乘法，最后一次被累加的乘积需要使用补码减法来操作
            mul64_result_temp <= mul64_result_temp - multiplicand_temp_128;
        end
        else if( multiplier_temp[0] )begin   //如果乘数的最低位为1
            mul64_result_temp <= mul64_result_temp + multiplicand_temp_128;
        end
        multiplicand_temp_128 <= ( multiplicand_temp_128 << 1 ); //被乘数左移一位
        multiplier_temp <= ( multiplier_temp >> 1 ); //乘数右移一位
    end
    else
        mul64_result_temp <= 128'b0;
end

reg mul64_over;
always @(posedge clock)begin
    if(reset)
        mul64_over <= 1'b0;
    else if(mul64_go & ( (mul_count >= 7'd63) |  multiplier_temp == 64'b0) )
        mul64_over <= 1'b1;
    else 
        mul64_over <= 1'b0;
end

assign mul_ready = mul_ready_t;
assign out_valid = mul32_over | mul64_over;  //只持续一周期
assign result_lo = out_valid ? ( mul32_over ? { {32{mul32_result_temp[31]}},mul32_result_temp[31:0] } : mul64_result_temp[63:0] ): 64'd0; //只持续一周期 用低64位表示输出
assign result_hi = mul64_over ? mul64_result_temp[127:64] : 64'b0;
assign mul_doing = mul32ss_go | mul64_go;

endmodule
/*
    模块名称：除法器
    功能：支持64 / 64 的有符号 / 无符号 除法 获得商和余数
         支持32 / 32 的有符号 / 无符号 除法 获得商和余数
*/

module ysyx_22050854_divider_1 (
    input clock,
    input reset,
    input [63:0]dividend,  //被除数
    input [63:0]divisor,   //除数
    input div_valid,       //为高表示输入的数据有效，如果没有新的除法输入，在除法被接受的下一个周期要置低
    input divw,            //为高表示输入是32位除法
    input div_signed,      //为高表示是有符号除法
    input flush,           //为高表示除法无效
    output div_doing,
    output div_ready,      //为高表示除法器空闲，可以输入数据
    output out_valid,      //为高表示除法器输出结果有效
    output [63:0]quotient, //商
    output [63:0]remainder //余数
);

//第一步 根据被除数和除数确定商和余数的符号 并计算被除数和除数的绝对值
// 规定余数的符号和被除数的符号保持一致
reg sign_quotient;   //0-正数 1-负数
reg sign_remainder;
reg [63:0]ABS_dividend_32;
reg [32:0]ABS_divisor_32;
reg [127:0]ABS_dividend_64;
reg [64:0]ABS_divisor_64;
reg div32_go;
reg div64_go;
reg div_ready_t;

wire [31:0]dividend_32;
assign dividend_32 = {27'b0,div32_index};
import "DPI-C" function void get_dividend_value(int dividend_32);
always@(*) get_dividend_value(dividend_32);

wire [31:0]divisor_32;
assign divisor_32 = {31'b0,div32_over};
import "DPI-C" function void get_divisor_value(int divisor_32);
always@(*) get_divisor_value(divisor_32);

always @(posedge clock)begin
    if(reset)begin
        sign_quotient <= 1'b0;
        sign_remainder <= 1'b0;
        ABS_dividend_32 <= 64'b0;
        ABS_divisor_32  <=33'b0;
        ABS_dividend_64 <= 128'b0;
        ABS_divisor_64 <= 65'b0;
        div32_go <= 1'b0;
        div64_go <= 1'b0;
        div_ready_t <= 1'b1;
    end
    else if( div_ready_t & div_valid & divw & div_signed )begin // 有符号的32位除法
        div32_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= dividend[31] ^ divisor[31];
        sign_remainder <= dividend[31];
        if( dividend[31] ) ABS_dividend_32[31:0] <= ~dividend[31:0] + 1; 
        else ABS_dividend_32[31:0] <= dividend[31:0];
        if( divisor[31] ) ABS_divisor_32[31:0] <= ~divisor[31:0] + 1;
        else ABS_divisor_32[31:0] <= divisor[31:0];
    end
    else if( div_ready_t & div_valid & divw & !div_signed )begin // 无符号的32位除法
        div32_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= 1'b0;  //对于无符号数运算 最后一步默认就是运算结果就可
        sign_remainder <= 1'b0; 
        ABS_dividend_32[31:0] <= dividend[31:0];
        ABS_divisor_32[31:0] <= divisor[31:0];       
    end
    else if( div_ready_t & div_valid & ~divw & div_signed )begin // 有符号的64位除法
        div64_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= dividend[63] ^ divisor[63];
        sign_remainder <= dividend[63];
        if( dividend[63] ) ABS_dividend_64[63:0] <= ~dividend + 1; 
        else ABS_dividend_64[63:0] <= dividend;
        if( divisor[63] ) ABS_divisor_64[63:0] <= ~divisor + 1;
        else ABS_divisor_64[63:0] <= divisor;
    end
    else if( div_ready_t & div_valid & ~divw & ~div_signed )begin // 无符号的64位除法
        div64_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= 1'b0;
        sign_remainder <= 1'b0;
        ABS_dividend_64[63:0] <= dividend;
        ABS_divisor_64[63:0] <= divisor;
    end
    else if( div32_over | div64_over )begin
        sign_quotient <= 1'b0;
        sign_remainder <= 1'b0;
        ABS_dividend_32 <= 64'b0;
        ABS_divisor_32  <= 33'b0;
        ABS_dividend_64 <= 128'b0;
        ABS_divisor_64 <= 65'b0;
        div_ready_t <= 1'b1;
    end
end

//计数器
reg [7:0]div_count;
always @(posedge clock)begin
    if(reset)
        div_count <= 8'b0;
    else if( div32_go & (div_count >= 8'd32) ) //得需要33个周期，因为获得余数还需要一个周期
        div_count <= 8'b0;
    else if( div64_go & (div_count >= 8'd64) )
        div_count <= 8'b0;
    else if( div32_go | div64_go )
        div_count <= div_count + 8'b1;
    else
        div_count <= 8'b0;
end

//第二步 迭代运算得到商和余数的绝对值
reg [31:0]div32_result_quotient;
reg [31:0]div32_result_remainder;
reg [63:0]div64_result_quotient;
reg [63:0]div64_result_remainder;
reg [4:0]div32_index;
reg [5:0]div64_index;
always @(posedge clock)begin
    if(reset)begin
        div32_result_quotient <= 32'b0;
        div32_result_remainder <= 32'b0;
        div64_result_quotient <= 64'b0;
        div64_result_remainder <= 64'b0;
        div32_index <= 5'd31;
        div64_index <= 6'd63;
    end
    else if( div32_go & (div_count < 8'd32 ))begin     //32x32 获得商
        if ( ( ABS_dividend_32[63:31] < ABS_divisor_32 ) )begin
            div32_result_quotient[div32_index] <= 1'b0;
            if(div_count != 8'd31) ABS_dividend_32 <= ABS_dividend_32 << 1;
        end
        else begin
            div32_result_quotient[div32_index] <= 1'b1;
            if( div_count != 8'd31 ) 
                ABS_dividend_32 <= { ABS_dividend_32 - {ABS_divisor_32,31'b0} } << 1; //够减，调整剩余被乘数,然后再左移一位
            else 
                ABS_dividend_32 <= { ABS_dividend_32 - {ABS_divisor_32,31'b0} };
        end
        div32_index <= div32_index - 5'd1;
    end
    else if( div32_go & (div_count == 8'd32) )begin     //32x32 获得余数
        div32_result_remainder <= ABS_dividend_32[62:31];
    end
    else if( div64_go & (div_count < 8'd64 ))begin      //64x64 获得商
        if ( ( ABS_dividend_64[127:63] < ABS_divisor_64 ) )begin
            div64_result_quotient[div64_index] <= 1'b0;
            if(div_count != 8'd63) ABS_dividend_64 <= ABS_dividend_64 << 1;
        end
        else begin
            div64_result_quotient[div64_index] <= 1'b1;
            if( div_count != 8'd63 ) 
                ABS_dividend_64 <= { ABS_dividend_64 - {ABS_divisor_64,63'b0} } << 1; //够减，调整剩余被乘数,然后再左移一位
            else 
                ABS_dividend_64 <= { ABS_dividend_64 - {ABS_divisor_64,63'b0} };
        end
        div64_index <= div64_index - 6'd1;
    end
    else if( div64_go & (div_count == 8'd64) )begin     //64x64 获得余数
        div64_result_remainder <= ABS_dividend_64[126:63];
    end  
    else if( div32_over | div64_over )begin
        div32_result_quotient <= 32'b0;
        div32_result_remainder <= 32'b0;
        div64_result_quotient <= 64'b0;
        div64_result_remainder <= 64'b0;
        div32_index <= 5'd31;
        div64_index <= 6'd63;
    end
end

reg div32_over;
reg div64_over;
always @(posedge clock)begin
    if(reset)begin
        div32_over <= 1'b0;
        div64_over <= 1'b0;
    end
    else if(div32_go & (div_count >= 8'd32)) begin//得需要33个周期，因为获得余数还需要一个周期
        div32_over <= 1'b1;
        div32_go <= 1'b0;
    end
    else if(div64_go & (div_count >= 8'd64))begin //得需要65个周期，因为获得余数还需要一个周期
        div64_over <= 1'b1;
        div64_go <= 1'b0;
    end
    else begin
        div32_over <= 1'b0;
        div64_over <= 1'b0;
    end
end

//第3步，调整最终的商和余数
wire [31:0]quotient_32;
wire [31:0]remainder_32;
assign quotient_32 = div32_over ? ( sign_quotient ? (~div32_result_quotient + 32'b1) : div32_result_quotient ) : 32'b0;
assign remainder_32 = div32_over ? ( sign_remainder ? (~div32_result_remainder + 32'b1) : div32_result_remainder ) : 32'b0;
assign quotient = div64_over ? ( sign_quotient ? (~div64_result_quotient + 64'b1) : div64_result_quotient ) : {{32{quotient_32[31]}},quotient_32};
assign remainder = div64_over ? ( sign_remainder ? (~div64_result_remainder + 64'b1) : div64_result_remainder ) :{{32{quotient_32[31]}},remainder_32};
assign div_doing = div32_go | div64_go;
assign out_valid = div32_over | div64_over;
assign div_ready = div_ready_t;

endmodulemodule ysyx_22050854_MuxKeyInternal #(NR_KEY = 2, KEY_LEN = 1, DATA_LEN = 1, HAS_DEFAULT = 0) (
  output reg [DATA_LEN-1:0] out,
  input [KEY_LEN-1:0] key,
  input [DATA_LEN-1:0] default_out,
  input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);

  localparam PAIR_LEN = KEY_LEN + DATA_LEN;
  wire [PAIR_LEN-1:0] pair_list [NR_KEY-1:0];
  wire [KEY_LEN-1:0] key_list [NR_KEY-1:0];
  wire [DATA_LEN-1:0] data_list [NR_KEY-1:0];

  generate
    for (genvar n = 0; n < NR_KEY; n = n + 1) begin
      assign pair_list[n] = lut[PAIR_LEN*(n+1)-1 : PAIR_LEN*n];
      assign data_list[n] = pair_list[n][DATA_LEN-1:0];
      assign key_list[n]  = pair_list[n][PAIR_LEN-1:DATA_LEN];
    end
  endgenerate

  reg [DATA_LEN-1 : 0] lut_out;
  reg hit;
  integer i;
  always @(*) begin
    lut_out = 0;
    hit = 0;
    for (i = 0; i < NR_KEY; i = i + 1) begin
      lut_out = lut_out | ({DATA_LEN{key == key_list[i]}} & data_list[i]);
      hit = hit | (key == key_list[i]);
    end
    if (!HAS_DEFAULT) out = lut_out;
    else out = (hit ? lut_out : default_out);
  end
endmodule

// 不带默认值的选择器模板
module ysyx_22050854_MuxKey #(NR_KEY = 2, KEY_LEN = 1, DATA_LEN = 1) (
  output [DATA_LEN-1:0] out,
  input [KEY_LEN-1:0] key,
  input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);
  ysyx_22050854_MuxKeyInternal #(NR_KEY, KEY_LEN, DATA_LEN, 0) i0 (out, key, {DATA_LEN{1'b0}}, lut);
endmodule

// 带默认值的选择器模板
module ysyx_22050854_MuxKeyWithDefault #(NR_KEY = 2, KEY_LEN = 1, DATA_LEN = 1) (
  output [DATA_LEN-1:0] out,
  input [KEY_LEN-1:0] key,
  input [DATA_LEN-1:0] default_out,
  input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);
  ysyx_22050854_MuxKeyInternal #(NR_KEY, KEY_LEN, DATA_LEN, 1) i0 (out, key, default_out, lut);
endmodule

module ysyx_22050854_Reg #(WIDTH = 1, RESET_VAL = 0) (
    input clock,
    input reset,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout,
    input wen
);
    always @(posedge clock) begin
        if(reset) dout <= RESET_VAL;
        else if(wen) dout <= din;
    end
endmodule

`timescale 1ns/1ps
/*
  这个模块实际上为模拟 接收到AXI信号后 SDRAM 的操作而设计
  接口信号为ysyxSoc的接口信号 就是一个不完整的AXI4 协议
  由于为仿真设计，所以其不具备通用性
  其功能为读/写 一个cache块的内容 
*/

module ysyx_22050854_AXI_SRAM_LSU (
    input clock,
    input rst_n,

    //read address channel
    input arvalid,
    output reg arready, 
    input [31:0]araddr,
    input [3:0]arid,
    input [7:0]arlen,
    input [2:0]arsize,
    input [1:0]arburst,

    //read data channel
    output reg [63:0]rdata,
    output reg [1:0]rresp,
    output reg rvalid,
    input rready,
    output reg [3:0]rid,
    output reg rlast,

    //write address channel
    input [31:0]awaddr,
    input awvalid,
    output reg awready,
    input [3:0]awid,
    input [7:0]awlen,
    input [2:0]awsize,
    input [1:0]awburst,

    //write data channel
    input [63:0]wdata,
    input wvalid,
    output reg wready,
    input [7:0]wstrb,
    input wlast,

    //write response channel
    output reg [1:0]bresp,
    output reg bvalid,
    input bready,
    output [3:0]bid
);

import "DPI-C" function void v_pmem_read(
input longint raddr, output longint rdata);

import "DPI-C" function void v_pmem_write(
input longint waddr, input longint wdata, input longint wmask);

reg first_over;
reg get_addr;
reg [63:0]first_addr;
reg [3:0]first_arid;
always @(posedge clock)begin
    if(!rst_n)begin
        arready <= 1'b1;
        get_addr <= 1'b0;
        first_addr <= 64'b0;
        first_arid <= 4'b0;
    end
    else if( arvalid && arready )begin
        first_addr <= {32'b0, araddr[31:4] , 4'b0 };
        first_arid <= arid;
        get_addr <= 1'b1;
    end
end

reg [63:0]Next_addr;
reg [3:0]Next_arid;
always @(posedge clock)begin
    if(!rst_n)begin
        rresp <= 2'b00;
        rvalid <= 1'b1;
        first_over <= 1'b0;
        rlast <= 1'b0;
        Next_arid <= 4'b0;
        Next_addr <= 64'b0;
        rid <= 4'b0;
    end
    else if(rvalid && rready && first_over)begin
        v_pmem_read(Next_addr ,rdata);
        rresp <= 2'b10;
        rlast <= 1'b1;
        rid <= Next_arid;

        first_over <= 1'b0;
    end
    else if( rvalid && rready && get_addr )begin
        v_pmem_read(first_addr,rdata);
        rresp <= 2'b10;
        rid <= first_arid;
        rlast <= 1'b0;

        first_over <= 1'b1;
        Next_addr <= { first_addr[63:4] , 1'b1, 3'b0 };
        Next_arid <= first_arid;
        
        if( ~arvalid ) get_addr <= 1'b0;
    end
    else begin
        rresp <= 2'b00;
        first_over <= 1'b0;
        rlast <= 1'b0;
        rid <= 4'b0;
    end
end

//write   
reg [63:0]dsram_write_addr;
reg [7:0]dsram_wtsb;
wire [63:0]wmask;
//assign wmask = { {8{dsram_wtsb[7]}}, {8{dsram_wtsb[6]}}, {8{dsram_wtsb[5]}}, {8{dsram_wtsb[4]}}, {8{dsram_wtsb[3]}}, {8{dsram_wtsb[2]}}, {8{dsram_wtsb[1]}}, {8{dsram_wtsb[0]}} };
assign wmask = 64'hffffffffffffffff;
always @(posedge clock)begin
    if(!rst_n) begin
        awready <= 1'd1;
    end
    else if(awvalid && awready) begin
        dsram_write_addr <= { 32'd0, awaddr};
    end
end

always @(posedge clock)begin
    if(!rst_n)begin
        wready <= 1'd1;
        bresp <= 2'b00;
    end
    else if( wvalid && wready )begin
        if(wlast) begin
            v_pmem_write( { dsram_write_addr[63:4],4'b1000},wdata,wmask);
            bresp <= 2'b01;
        end
        else begin
            v_pmem_write(dsram_write_addr,wdata,wmask);
        end
    end
    else begin
        bresp <= 2'b00;
    end
end

wire [31:0]awvalid_32;
assign awvalid_32 = { 31'b0, awvalid };
import "DPI-C" function void get_awvalid_32_value(int awvalid_32);
always@(*) get_awvalid_32_value(awvalid_32);

wire [31:0]dsram_write_addr_32;
assign dsram_write_addr_32 = dsram_write_addr[31:0];
import "DPI-C" function void get_dsram_write_addr_value(int dsram_write_addr_32);
always@(*) get_dsram_write_addr_value(dsram_write_addr_32);

wire [31:0]dsram_wdata_32;
assign dsram_wdata_32 = wdata[31:0];
import "DPI-C" function void get_dsram_wdata_32_value(int dsram_wdata_32);
always@(*) get_dsram_wdata_32_value(dsram_wdata_32);

endmodule/*
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

endmodule`timescale 1ns/1ps
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

endmodulemodule ysyx_22050854_Dcache (clock,reset,
    valid,op,index,tag,offset,wstrb,wdata,addr_ok,data_ok,rdata,unshoot,fencei,
    rd_req,rd_type,rd_addr,rd_rdy,ret_valid,ret_last,ret_data,wr_req,wr_type,wr_addr,wr_wstb,wr_data,wr_rdy,
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
output addr_ok;       //表示这次请求的地址传输OK
output data_ok;       //表示这次请求的数据传输OK
output [63:0]rdata;    //读cache的结果
output reg unshoot;
input fencei;

//Cache 与 AXI总线接口的交互接口
output reg rd_req;        //读请求有效信号，高电平valid
output reg [2:0]rd_type;       //读请求类型，3‘b000: 字节 001---半字  010---字 100-cache行
output reg [31:0]rd_addr;       //读请求起始地址
input rd_rdy;       //读请求能否被接受的握手信号，高电平有效
input ret_valid;      //返回数据有效   
input ret_last;     //返回数据是一次读请求对应最后一个返回的数据
input [63:0]ret_data;     //读返回数据
output reg wr_req;     //写请求信号，高电平有效
output reg [2:0]wr_type;     //写请求类型， 000---字节 001---半字  010---字  100----cache行
output reg [31:0]wr_addr;     //写请求地址
output reg [7:0]wr_wstb;   //写操作的字节掩码
output reg [127:0]wr_data;        //写数据
input wr_rdy;          //写请求能否被接收的握手信号，高电平有效，要求wr_rdy先于wr_req置起，wr_req看到wr_rdy置起后才可能置起

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

parameter IDLE = 6'b000001,LOOKUP = 6'b000010, MISS = 6'b000100, REPLACE = 6'b001000,REWAIT = 6'b010000,REFILL = 6'b100000;
reg [5:0]state;

reg [Index_Bits - 1 : 0]RB_index;
reg [Tag_Bits - 1 : 0]RB_tag;
reg [Offset_Bits - 1 : 0]RB_offset;
reg [7:0]RB_wstrb;
reg [127:0]RB_wdata;
reg RB_OP;
reg [127:0]RB_BWEN;

reg [Index_Bits - 1 : 0]HIT_index;
reg [Tag_Bits - 1 : 0]HIT_tag;
reg [Offset_Bits - 1 : 0]HIT_offset;
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
reg ADDR_OK;
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
                wr_type <= 3'b100;
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
                wr_type <= 3'b100;                  //写一个cache块
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
        RB_offset <= 4'd0;
        RB_OP <= 1'b0;
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
        rd_type <= 3'b0;
        rd_addr <= 32'b0;
        wr_req <= 1'b0;
        wr_type <= 3'b100;
        wr_addr <= 32'b0;
        wr_wstb <= 8'h0;
        wr_data <= 128'b0;

        Replace_cache_data <= 128'b0;

        RB_wstrb <= 8'b0;
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
                    wr_type <= 3'b100;
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
                    RB_offset <= offset;
                    RB_OP <= op;

                    ADDR_OK <= 1'b1;

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
                            rd_type <= 3'b100;
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
                    RB_offset <= offset;
                    RB_wstrb <= wstrb;
                    RB_wdata <= wdata_128;
                    RB_OP <= op;
                    RB_BWEN <= wstrb_to_bwen_128;
                    ADDR_OK <= 1'b1;

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
                            rd_type <= 3'b100;
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
                    ADDR_OK <= 1'b0;

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
                    HIT_index <= RB_index;  
                    HIT_tag <= RB_tag;
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
                    ADDR_OK <= 1'b0;
                    hit_way0 <= 1'b0;
                    hit_way1 <= 1'b0;
                end
                else if( valid & !op) begin   // read
                    RB_index <= index;  
                    RB_tag <= tag;
                    RB_offset <= offset;
                    ADDR_OK <= 1'b1;
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
                            rd_type <= 3'b100;
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
                    RB_offset <= offset;
                    RB_wstrb <= wstrb;
                    RB_wdata <= wdata_128;
                    RB_OP <= op;
                    RB_BWEN <= wstrb_to_bwen_128;
                    ADDR_OK <= 1'b1;

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
                            rd_type <= 3'b100;
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
                    state <= IDLE;
                    unshoot <= 1'b0;

                    wr_req <= 1'b1;
                    wr_type <= 3'b100;  //写一个cache块
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
        default:
            state <= IDLE;
    endcase 
    end
end

assign read_ramdata = Data_OK ? ( HIT_way0 ? ( HIT_index[6] ? sram5_rdata : sram4_rdata ) : ( HIT_way1 ? ( HIT_index[6] ? sram7_rdata : sram6_rdata) : 128'b0 ) ) : 128'b0;
assign rdata = Data_OK ? ( ( state == REPLACE ) ? (  RB_offset[3] ?  Bus_retdata[127:64] : Bus_retdata[63:0] ) : ( HIT_offset[3] ?  read_ramdata[127:64] : read_ramdata[63:0] ) ) : 64'b0;

assign data_ok = Data_OK;
assign addr_ok = ADDR_OK;

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
assign Dcache_state_32 = {26'b0,state};
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

endmodule /*
    I-cache 大小为4KB,一个ram大小为1KB，需要例化4个ram
    我想分成两路组相连，一路2KB，cache行大小为16B，128个行
    但这只是data 还有tag v d 呢 
    tag如何与data联系起来？

*/

module ysyx_22050854_Icache (clock,reset,
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

input clock;
input reset;
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
always @(posedge clock)begin
    if(reset)begin
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

        rd_req <= 1'b0;
        rd_type <= 3'b0;
        rd_addr <= 32'b0;
        Bus_retdata <= 128'b0; 
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