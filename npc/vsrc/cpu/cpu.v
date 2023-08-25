`timescale 1ns/1ps
module ysyx_22050854_cpu(
    input rst,
    input clk,
    //input suspend,
    output timer_interrupt,
    output ebreak,
    output [63:0]x10
);   
    reg suspend;
    wire rst_n;
    assign rst_n = ~rst;

    //------------------- IF -------------------//
    wire isram_arready;
    wire isram_rresp;
    wire isram_rvalid;
    wire [63:0]isram_rdata;
    wire isram_arvalid;
    wire isram_rready;
    reg [31:0]pc_test;
    always @(posedge clk)begin
        if(rst)
            pc_test <= 32'h80000000;
        else if(jump | Data_Conflict_block | arvalid_n_t) //如果是跳转指令或遇到了数据冲突
            pc_test <= next_pc + 32'd4;
        else
            pc_test <= pc_test + 32'd4;
    end

    import "DPI-C" function void get_next_pc_value(int next_pc);
    always@(*) get_next_pc_value(next_pc);
    wire [31:0]pc_real;
    //如果译码阶段发现是jump 但不阻塞 则可根据next_pc取指
    //如果译码阶段发现阻塞 但不是jump 则可根据next_pc取指
    //如果译码阶段发现既是jump又是阻塞，则不能取指，因为阻塞产生的jump并不准确
    //如果上周期既是jump又是阻塞，则可以取指，因为本周期能计算出是否真正jump
    assign pc_real = (jump | Data_Conflict_block | arvalid_n_t) ? next_pc : pc_test;
    import "DPI-C" function void get_pc_value(int pc_real);
    always@(*) get_pc_value(pc_real);
    reg [31:0]pc_record_1;
    reg [31:0]pc_record_2;
    always@(posedge clk)begin
        pc_record_1 <= pc_real; 
    end
    always@(posedge clk)begin
        pc_record_2 <= pc_record_1;
    end
    wire arvalid_n;
    //如果当前周期下是jalr 或者 beq指令 且发生了阻塞，则无法产生正确的next_pc,本周期不取指
    assign arvalid_n = ( ( ID_reg_inst[6:0] == 7'b1100011) | (ID_reg_inst[6:0]) == 7'b1100111) & Data_Conflict_block ;
    reg arvalid_n_t;
    ysyx_22050854_Reg #(1,1'b0) jumpandblock (clk, rst, arvalid_n, arvalid_n_t, 1'b1);
    ysyx_22050854_SRAM_IFU cpu_ifu(
        .clk(clk),
        .rst_n(rst_n),

        .araddr(pc_real),
        .arvalid(~arvalid_n),
        .arready(isram_arready),

        .rdata(isram_rdata),
        .rresp(isram_rresp),
        .rvalid(isram_rvalid),
        .rready(1'b1)
    );

    //
    reg [31:0]inst;
    wire [63:0]inst_64;
    assign inst_64 = (isram_rresp == 1'b1) ? isram_rdata : 64'h6666666666666666;

    //instruction
    reg [31:0]pc_last;
    always@(*)begin
        pc_last = pc_test - 32'd8;
    end
    always @(*)begin
        if(isram_rresp)  begin//如果是刚取到指令
            inst = ( pc_record_2[2:0] == 3'b000 ) ? inst_64[31:0] : inst_64[63:32];  //这里利用了pc_test比当前实际指令的PC刚好大8位，后三位相同
        end
        else
            inst = 32'd0;
    end
/*     reg [31:0]block_inst1;
    always@(posedge clk)begin //发现阻塞后的上升沿
        if(rst)
            block_inst1 <= 32'h0;
        else if(Data_Conflict_block)
            block_inst1 <= inst;
    end */


    import "DPI-C" function void get_inst_value(int inst);
    always@(*) get_inst_value(inst);

    assign ebreak = ( WBreg_inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011 ) ? 1'b1 : 1'b0;
    
    //---------------------------------------------ID_reg-----------------------------------------//
    reg ID_reg_valid;
    reg ID_reg_inst_enable;
    reg [31:0]ID_reg_inst;
    reg ID_reg_pc_enable;
    reg [31:0]ID_reg_pc;
    always@(*)begin
        ID_reg_inst_enable = isram_rresp & (~Data_Conflict_block); //如果更新前发现需要阻塞，就不更新了
        ID_reg_pc_enable = isram_rresp & (~Data_Conflict_block);
    end
    always@(posedge clk)begin
        if(rst)
            ID_reg_valid <= 1'b0;
        else
            ID_reg_valid <= isram_rresp & (~jump) & (~EXEreg_jump) & (~EXEreg_Datablock); //EXEjump/block,表明上一周期发起了新的pc请求，按理说这一周期是取不到的，所以无效
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

    wire [63:0]imm;
    ysyx_22050854_imm_gen gen_imm(
    .instr(ID_reg_inst),
    .ExtOP(ExtOP),
    .imm(imm)
);

    wire [63:0]src1;
    wire [63:0]src2;
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
        .src1(src1),
        .src2(src2),
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
        10'b0011110011, real_CSRsrc1,
        10'b0101110011, csr_rdata | real_CSRsrc1,
        10'b0111110011, csr_rdata & ~real_CSRsrc1,
        10'b1011110011, {59'd0,ID_reg_inst[19:15]},
        10'b1101110011, csr_rdata | {59'd0,ID_reg_inst[19:15]},
        10'b1111110011, csr_rdata & ~{59'd0,ID_reg_inst[19:15]}
    });
    assign csr_wdata1 = ( ID_reg_inst == 32'h73 ) ? ( { 32'd0, ID_reg_pc } + 64'd4 ) : csrwdata_t; //ecall->mepc
    assign csr_wdata2 = ( ID_reg_inst == 32'h73 ) ? real_CSRsrc2 : 64'h0;  //ecall->mcause

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
    wire mem_conflict_EXE;   //sd 之后紧跟 ld ,且内存地址冲突，导致还没写入内存就要取走，这个不会形成阻塞
    wire store_conflict_EXE; //还有一种冲突是当store指令的源操作数(要写入内存的数据)与之前指令的目的寄存器重合时（如ld 之后 sd / add 之后 sd）
    wire ret_conflict_EXE;
    assign rs1_conflict_EXE = (( ALUsrc1 == 1'b0 ) & ( rs1 == EXEreg_Rd ) & ( EXEreg_Rd != 0)); //当且仅当alu操作数是寄存器，且前一条指令要写回， 且写回地址不是x0时 ,rd = rs 才冲突
    assign rs2_conflict_EXE = (( ALUsrc2 == 2'b00 ) & ( rs2 == EXEreg_Rd) & ( EXEreg_Rd != 0));
    assign reg_Conflict_EXE = ID_reg_valid & EXEreg_valid & EXEreg_regWr  & ( rs1_conflict_EXE | rs2_conflict_EXE ); //与前一条指令冲突
    assign mem_conflict_EXE = ID_reg_valid & EXEreg_valid & EXEreg_memWr & MemRd & ( ( readmemaddr & 64'hfffffff8 ) ==  ( alu_out & 64'hfffffff8 ) ); //当前周期的 ld地址 与 上一周期的 sd 地址重合
    assign store_conflict_EXE = ID_reg_valid & MemWr & (rs2 == EXEreg_Rd) & (EXEreg_Rd != 0) & (EXEreg_valid) & (EXEreg_regWr);
    assign ret_conflict_EXE = ID_reg_valid & (ID_reg_inst[6:0] == 7'b1100111) & (rs1 == EXEreg_Rd) & EXEreg_regWr & EXEreg_valid & (EXEreg_Rd != 0);

    wire rs1_conflict_MEM;
    wire rs2_conflict_MEM;
    wire reg_Conflict_MEM;
    wire mem_conflict_MEM;
    wire store_conflict_MEM;
    wire ret_conflict_MEM;
    assign rs1_conflict_MEM = (( ALUsrc1 == 1'b0 ) & ( rs1 == MEMreg_rd) & (MEMreg_rd != 0));
    assign rs2_conflict_MEM = (( ALUsrc2 == 2'b00) & ( rs2 == MEMreg_rd) & (MEMreg_rd != 0));
    assign reg_Conflict_MEM = ID_reg_valid & MEMreg_valid & MEMreg_regwr & (rs1_conflict_MEM | rs2_conflict_MEM); //与前两条指令冲突
    assign mem_conflict_MEM = ID_reg_valid & MEMreg_valid & ( MEMreg_memwr ) & ( MemRd ) & ( ( readmemaddr & 64'hfffffff8 ) ==  ( MEMreg_aluout & 64'hfffffff8 ) ); //当前周期的 ld 与 上两个周期的 sd 地址重合
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
    wire mem_Conflict;
    assign mem_Conflict = mem_conflict_EXE | mem_conflict_MEM;

    //需要阻塞的情况
    wire Data_Conflict_block;
    assign Data_Conflict_block = ( reg_Conflict_EXE | store_conflict_EXE | ret_conflict_EXE | CSRsrc_confilct_EXE ) & EXEreg_memRd; //目前是只有上一条指令是load的情况才需要阻塞

    wire [31:0]Data_Conflict_32;
    assign Data_Conflict_32 = {21'b0,ret_conflict_EXE,ret_conflict_MEM,ret_conflict_WB,store_conflict_EXE,store_conflict_MEM,store_conflict_WB,mem_conflict_MEM,mem_conflict_EXE,reg_Conflict_WB,reg_Conflict_MEM,reg_Conflict_EXE};
    import "DPI-C" function void get_Data_Conflict_value(int Data_Conflict_32);
    always@(*) get_Data_Conflict_value(Data_Conflict_32);

/*
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
*/

    // --------------                   流水线前递          ----------------//

    reg [63:0]real_alusrc1;
    reg [63:0]real_alusrc2;
    //寄存器 ALU源操作数 前递
    //其实按理说 我要改的只是从寄存器读出来的src的前递之后的值，但是我这里直接改了alu的操作说
    //我判断冲突的条件是rs1 rs2 是alu操作数为前提的 比如ALU操作数如果是立即数是没有冲突的
    //最终也会回到alu_src1
    always @(*)begin
        if( reg_Conflict_EXE & rs1_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            real_alusrc1 = alu_out;
        else if( reg_Conflict_EXE & rs1_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            real_alusrc1 = csr_rdata;
        else if(reg_Conflict_MEM & rs1_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            real_alusrc1 = MEMreg_aluout;
        else if(reg_Conflict_MEM & rs1_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            real_alusrc1 = MEMreg_CSRrdata;
        else if(reg_Conflict_MEM & rs1_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            real_alusrc1 = read_mem_data;
        else if( reg_Conflict_WB & rs1_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            real_alusrc1 = WBreg_aluout;
        else if( reg_Conflict_WB & rs1_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            real_alusrc1 = WBreg_CSRrdata;
        else if( reg_Conflict_WB & rs1_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            real_alusrc1 = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            real_alusrc1 = alu_src1;
    end
    always @(*)begin
        if( reg_Conflict_EXE & rs2_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            real_alusrc2 = alu_out;
        else if( reg_Conflict_EXE & rs2_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            real_alusrc2 = csr_rdata;
        else if(reg_Conflict_MEM & rs2_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            real_alusrc2 = MEMreg_aluout;
        else if(reg_Conflict_MEM & rs2_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            real_alusrc2 = MEMreg_CSRrdata;
        else if(reg_Conflict_MEM & rs2_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            real_alusrc2 = read_mem_data;
        else if( reg_Conflict_WB & rs2_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            real_alusrc2 = WBreg_aluout;
        else if( reg_Conflict_WB & rs2_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            real_alusrc2 = WBreg_CSRrdata;
        else if( reg_Conflict_WB & rs2_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            real_alusrc2 = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            real_alusrc2 = alu_src2;
    end
    //CSR指令 源操作数前递
    reg [63:0]real_CSRsrc1;
    reg [63:0]real_CSRsrc2;
    always @(*)begin
        if( CSRsrc1_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            real_CSRsrc1 = alu_out;
        else if( CSRsrc1_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            real_CSRsrc1 = csr_rdata;
        else if(CSRsrc1_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            real_CSRsrc1 = MEMreg_aluout;
        else if(CSRsrc1_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            real_CSRsrc1 = MEMreg_CSRrdata;
        else if(CSRsrc1_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            real_CSRsrc1 = read_mem_data;
        else if( CSRsrc1_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            real_CSRsrc1 = WBreg_aluout;
        else if( CSRsrc1_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            real_CSRsrc1 = WBreg_CSRrdata;
        else if( CSRsrc1_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            real_CSRsrc1 = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            real_CSRsrc1 = src1;
    end
    always @(*)begin
        if( CSRsrc2_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            real_CSRsrc2 = alu_out;
        else if( CSRsrc2_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            real_CSRsrc2 = csr_rdata;
        else if(CSRsrc2_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            real_CSRsrc2 = MEMreg_aluout;
        else if(CSRsrc2_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            real_CSRsrc2 = MEMreg_CSRrdata;
        else if(CSRsrc2_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            real_CSRsrc2 = read_mem_data;
        else if( CSRsrc2_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            real_CSRsrc2 = WBreg_aluout;
        else if( CSRsrc2_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            real_CSRsrc2 = WBreg_CSRrdata;
        else if( CSRsrc2_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            real_CSRsrc2 = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            real_CSRsrc2 = src2;
    end

    //内存数据前递 (store 之后 load )
    //再修改内存冲突的判断之后，与前一条以及前二条的冲突是可以同时存在的
    reg [63:0]real_readmemdata_EXE;
    reg [63:0]real_readnendata_MEM;
    always @(*)begin
        if( mem_conflict_EXE )
            real_readmemdata_EXE = EXEreg_writememdata;
        else
            real_readmemdata_EXE = 64'd0;
    end
    always @(*)begin
        if( mem_conflict_MEM )
            real_readnendata_MEM = MEMreg_writememdata;
        else
            real_readnendata_MEM = 64'd0;
    end

    //这是在load 指令前 有store 且发生内存冲突时使用的
    //不管地址了，假设编译出来的指令 sd ld的目标内存地址一致
    //本段 就算出经过当前store指令之后，内存8字节对其处 的数据 根据store地址以及存储器操作数决定
    wire [63:0]real_readmemdata_EXE_64;
    ysyx_22050854_MuxKey #(21,6,64) gen_real_readmemdata_EXE_64_00 (real_readmemdata_EXE_64,{ alu_out[2:0],EXEreg_memop },{
        6'b000000, {56'b0,real_readmemdata_EXE[7:0]},    // sb
        6'b000001, {48'b0,real_readmemdata_EXE[15:0]},   // sh
        6'b000010, {32'b0,real_readmemdata_EXE[31:0]},   // sw
        6'b000011, real_readmemdata_EXE,                 // sd

        6'b001000, {48'b0,real_readmemdata_EXE[7:0],8'b0},    // sb
        6'b001001, {40'b0,real_readmemdata_EXE[15:0],8'b0},   // sh
        6'b001010, {24'b0,real_readmemdata_EXE[31:0],8'b0},   // sw

        6'b010000, {40'b0,real_readmemdata_EXE[7:0],16'b0},    // sb
        6'b010001, {32'b0,real_readmemdata_EXE[15:0],16'b0},   // sh
        6'b010010, {16'b0,real_readmemdata_EXE[31:0],16'b0},   // sw

        6'b011000, {32'b0,real_readmemdata_EXE[7:0],24'b0},    // sb
        6'b011001, {24'b0,real_readmemdata_EXE[15:0],24'b0},   // sh
        6'b011010, {8'b0,real_readmemdata_EXE[31:0],24'b0},   // sw

        6'b100000, {24'b0,real_readmemdata_EXE[7:0],32'b0},    // sb
        6'b100001, {16'b0,real_readmemdata_EXE[15:0],32'b0},   // sh
        6'b100010, {real_readmemdata_EXE[31:0],32'b0},   // sw

        6'b101000, {16'b0,real_readmemdata_EXE[7:0],40'b0},    // sb
        6'b101001, {8'b0,real_readmemdata_EXE[15:0],40'b0},   // sh

        6'b110000, {8'b0,real_readmemdata_EXE[7:0],48'b0},    // sb
        6'b110001, {real_readmemdata_EXE[15:0],48'b0},   // sh

        6'b111000, {real_readmemdata_EXE[7:0],56'b0}    // sb
    });
    wire [63:0]real_readmemdata_EXE_64_mask;
    ysyx_22050854_MuxKey #(21,6,64) gen_real_readmemdata_EXE_64 (real_readmemdata_EXE_64_mask,{ alu_out[2:0],EXEreg_memop },{
        6'b000000, {56'b0,8'hff},    // sb
        6'b000001, {48'b0,16'hffff},   // sh
        6'b000010, {32'b0,32'hffffffff},   // sw
        6'b000011, 64'hffffffffffffffff,   // sd

        6'b001000, {48'b0,8'hff,8'b0},    // sb
        6'b001001, {40'b0,16'hffff,8'b0},   // sh
        6'b001010, {24'b0,32'hffffffff,8'b0},   // sw

        6'b010000, {40'b0,8'hff,16'b0},    // sb
        6'b010001, {32'b0,16'hffff,16'b0},   // sh
        6'b010010, {16'b0,32'hffffffff,16'b0},   // sw

        6'b011000, {32'b0,8'hff,24'b0},    // sb
        6'b011001, {24'b0,16'hffff,24'b0},   // sh
        6'b011010, {8'b0,32'hffffffff,24'b0},   // sw

        6'b100000, {24'b0,8'hff,32'b0},    // sb
        6'b100001, {16'b0,16'hffff,32'b0},   // sh
        6'b100010, {32'hffffffff,32'h0},   // sw

        6'b101000, {16'b0,8'hff,40'b0},    // sb
        6'b101001, {8'b0,16'hffff,40'b0},   // sh

        6'b110000, {8'b0,8'hff,48'b0},    // sb
        6'b110001, {16'hffff,48'b0},   // sh

        6'b111000, {8'hff,56'b0}    // sb
    });

    wire [63:0]real_readmemdata_MEM_64;
    ysyx_22050854_MuxKey #(21,6,64) gen_real_readmemdata_MEM_64 (real_readmemdata_MEM_64,{ MEMreg_aluout[2:0],MEMreg_memop },{
        6'b000000, {56'b0,real_readnendata_MEM[7:0]},    // sb
        6'b000001, {48'b0,real_readnendata_MEM[15:0]},   // sh
        6'b000010, {32'b0,real_readnendata_MEM[31:0]},   // sw
        6'b000011, real_readnendata_MEM,                 // sd

        6'b001000, {48'b0,real_readnendata_MEM[7:0],8'b0},    // sb
        6'b001001, {40'b0,real_readnendata_MEM[15:0],8'b0},   // sh
        6'b001010, {24'b0,real_readnendata_MEM[31:0],8'b0},   // sw

        6'b010000, {40'b0,real_readnendata_MEM[7:0],16'b0},    // sb
        6'b010001, {32'b0,real_readnendata_MEM[15:0],16'b0},   // sh
        6'b010010, {16'b0,real_readnendata_MEM[31:0],16'b0},   // sw

        6'b011000, {32'b0,real_readnendata_MEM[7:0],24'b0},    // sb
        6'b011001, {24'b0,real_readnendata_MEM[15:0],24'b0},   // sh
        6'b011010, {8'b0,real_readnendata_MEM[31:0],24'b0},   // sw

        6'b100000, {24'b0,real_readnendata_MEM[7:0],32'b0},    // sb
        6'b100001, {16'b0,real_readnendata_MEM[15:0],32'b0},   // sh
        6'b100010, {real_readnendata_MEM[31:0],32'b0},   // sw

        6'b101000, {16'b0,real_readnendata_MEM[7:0],40'b0},    // sb
        6'b101001, {8'b0,real_readnendata_MEM[15:0],40'b0},   // sh

        6'b110000, {8'b0,real_readnendata_MEM[7:0],48'b0},    // sb
        6'b110001, {real_readnendata_MEM[15:0],48'b0},   // sh

        6'b111000, {real_readnendata_MEM[7:0],56'b0}    // sb
    });
    wire [63:0]real_readmemdata_MEM_64_mask;
    ysyx_22050854_MuxKey #(21,6,64) gen_real_readmemdata_EXE_64_11 (real_readmemdata_MEM_64_mask,{ MEMreg_aluout[2:0],MEMreg_memop },{
        6'b000000, {56'b0,8'hff},    // sb
        6'b000001, {48'b0,16'hffff},   // sh
        6'b000010, {32'b0,32'hffffffff},   // sw
        6'b000011, 64'hffffffffffffffff,   // sd

        6'b001000, {48'b0,8'hff,8'b0},    // sb
        6'b001001, {40'b0,16'hffff,8'b0},   // sh
        6'b001010, {24'b0,32'hffffffff,8'b0},   // sw

        6'b010000, {40'b0,8'hff,16'b0},    // sb
        6'b010001, {32'b0,16'hffff,16'b0},   // sh
        6'b010010, {16'b0,32'hffffffff,16'b0},   // sw

        6'b011000, {32'b0,8'hff,24'b0},    // sb
        6'b011001, {24'b0,16'hffff,24'b0},   // sh
        6'b011010, {8'b0,32'hffffffff,24'b0},   // sw

        6'b100000, {24'b0,8'hff,32'b0},    // sb
        6'b100001, {16'b0,16'hffff,32'b0},   // sh
        6'b100010, {32'hffffffff,32'h0},   // sw

        6'b101000, {16'b0,8'hff,40'b0},    // sb
        6'b101001, {8'b0,16'hffff,40'b0},   // sh

        6'b110000, {8'b0,8'hff,48'b0},    // sb
        6'b110001, {16'hffff,48'b0},   // sh

        6'b111000, {8'hff,56'b0}    // sb
    });

    wire [63:0]real_readmemdata_right;
    assign real_readmemdata_right = real_readmemdata_EXE_64 | real_readmemdata_MEM_64;

    //针对store指令，写入内存数据的前递 src2
    reg [63:0]real_storememdata; //(realsrc2)
    always @(*)begin
        if( store_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            real_storememdata = alu_out;
        else if( store_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            real_storememdata = csr_rdata;
        else if(store_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            real_storememdata = MEMreg_aluout;
        else if(store_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            real_storememdata = MEMreg_CSRrdata;
        else if(store_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            real_storememdata = read_mem_data;
        else if( store_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            real_storememdata = WBreg_aluout;
        else if( store_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            real_storememdata = WBreg_CSRrdata;
        else if( store_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            real_storememdata = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            real_storememdata = src2;
    end

    //根据store命令的格式 获得正确的存入内存的数据
    //即使没有冲突，从src2读取出来的数据 我提前给他格式化一下应该是没问题的，因为在C语言的写内存函数中还是要将wdata按照掩码格式化
    wire [63:0]real_storememdata_right;
    ysyx_22050854_MuxKey #(4,3,64) gen_real_storememdata_right (real_storememdata_right,MemOP,{
        3'b000,{56'b0,real_storememdata[7:0]},  // sb   000
        3'b001,{48'b0,real_storememdata[15:0]},  // sh
        3'b010,{32'b0,real_storememdata[31:0]},  // sw
        3'b011,{real_storememdata}   // sd
    });

    //针对jalr(ret)指令 获取正确的src1
    reg [63:0]real_src1;
    always @(*)begin
        if( ret_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            real_src1 = alu_out;
        else if( ret_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            real_src1 = csr_rdata;
        else if(ret_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            real_src1 = MEMreg_aluout;
        else if(ret_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            real_src1 = MEMreg_CSRrdata;
        else if(ret_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            real_src1 = read_mem_data;
        else if( ret_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            real_src1 = WBreg_aluout;
        else if( ret_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            real_src1 = WBreg_CSRrdata;
        else if( ret_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            real_src1 = WBreg_readmemdata; //keng
        else                                                                        //不冲突
            real_src1 = src1;
    end

    //-------------- GEN readmemaddr -----------//在译码级就计算出load的地址
    wire [63:0]readmemaddr;
    assign readmemaddr = MemRd ? (real_alusrc1 + real_alusrc2) : 64'd0;
  
    //----------------- GEN PC -----------------//
    wire [31:0]pc;
    wire [31:0]next_pc;
    wire jump;
    wire ecall_or_mret;
    assign ecall_or_mret = ( ID_reg_inst == 32'h73 ) ? 1 : ( ID_reg_inst == 32'h30200073 ? 1'b1 : 1'b0);
    ysyx_22050854_pc gen_pc(
    .rst(rst),
    .clk(clk),
    .Data_Conflict(Data_Conflict_block),
    .suspend(suspend),
    .Branch(Branch),
    .No_branch(No_branch),
    .is_csr_pc(ecall_or_mret),
    .csr_pc(csr_rdata[31:0]),
    .unsigned_compare(ALUctr[3]),
    .alu_src1(real_alusrc1),
    .alu_src2(real_alusrc2),
    .src1(real_src1),
    .imm(imm),
    .jump(jump),
    .pc(pc),
    .next_pc(next_pc)
    );
    wire [31:0]jump_32;
    assign jump_32 = {31'b0,jump};
    import "DPI-C" function void get_jump_value(int jump_32);
    always@(*) get_jump_value(jump_32);

    //----------------------------------------------- EXE_reg ------------------------------------------------//
    reg EXEreg_valid;
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen0 (clk, rst,( ID_reg_valid & (~Data_Conflict_block) ), EXEreg_valid, 1'b1);
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
    reg EXEreg_memconflict_enable;
    reg EXEreg_memconflict;
    reg EXEreg_memconflict_data_enable;
    reg [63:0]EXEreg_memconflict_data;
    reg [63:0]EXEreg_real_readmemdata_EXE_64_mask;
    reg [63:0]EXEreg_real_readmemdata_MEM_64_mask;
    reg EXEreg_CSRrd_enable;
    reg EXEreg_CSRrd;
    reg EXEreg_CSRrdata_enable;
    reg [63:0]EXEreg_CSRrdata;

    always@(*)begin
        EXEreg_inst_enable = 1'b1;
        EXEreg_pc_enable = 1'b1;
        EXEreg_alusrc1_enable = 1'b1;
        EXEreg_alusrc2_enable = 1'b1;
        EXEreg_ALUctr_enable = 1'b1;
        EXEreg_MULctr_enable = 1'b1;
        EXEreg_ALUext_enable = 1'b1;
        EXEreg_regWr_enable = 1'b1;
        EXEreg_Rd_enable = 1'b1;
        EXEreg_memWr_enable = 1'b1;
        EXEreg_memRd_enable = 1'b1;
        EXEreg_memop_enable = 1'b1;
        EXEreg_memtoreg_enable = 1'b1;
        EXEreg_writememdata_enable = 1'b1;
        EXEreg_jump_enable = 1'b1;
        EXEreg_Datablock_enable = 1'b1;
        EXEreg_readmemaddr_enable = 1'b1;
        EXEreg_memconflict_enable = 1'b1;
        EXEreg_memconflict_data_enable = 1'b1;
        EXEreg_CSRrd_enable = 1'b1;
        EXEreg_CSRrdata_enable = 1'b1;
    end
    ysyx_22050854_Reg #(32,32'b0) EXEreg_geninst (clk, rst, ID_reg_inst, EXEreg_inst, EXEreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) EXEreg_genPC (clk, rst, ID_reg_pc, EXEreg_pc, EXEreg_pc_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen1 (clk, rst, real_alusrc1, EXEreg_alusrc1, EXEreg_alusrc1_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen2 (clk, rst, real_alusrc2, EXEreg_alusrc2, EXEreg_alusrc2_enable);
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
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen16 (clk, rst, mem_Conflict, EXEreg_memconflict, EXEreg_memconflict_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen17 (clk, rst, real_readmemdata_right, EXEreg_memconflict_data, EXEreg_memconflict_data_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen18 (clk, rst, real_readmemdata_EXE_64_mask, EXEreg_real_readmemdata_EXE_64_mask, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen19 (clk, rst, real_readmemdata_MEM_64_mask, EXEreg_real_readmemdata_MEM_64_mask, 1'b1);
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
    wire [31:0]real_readmemdata_right_32;
    assign real_readmemdata_right_32 = real_readmemdata_right[31:0];
    import "DPI-C" function void get_real_readmemdata_right_value(int EXEreg_writememdata_32);
    always@(*) get_real_readmemdata_right_value(real_readmemdata_right_32);

    //------------ALU------------//
    wire [63:0]alu_out;
    ysyx_22050854_alu alu1(
    .ALUctr(EXEreg_ALUctr),
    .MULctr(EXEreg_MULctr),
    .ALUext(EXEreg_ALUext),
    .src1(EXEreg_alusrc1),
    .src2(EXEreg_alusrc2),
    .alu_out(alu_out)
    );

    //--------------------------------------------- MEM_reg ---------------------------------------------//
    reg MEMreg_valid;
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen0 (clk, rst, EXEreg_valid, MEMreg_valid, 1'b1);
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
    reg MEMreg_memconflict_enable;
    reg MEMreg_memconflict;
    reg MEMreg_memconflict_data_enable;
    reg [63:0]MEMreg_memconflict_data;
    reg [63:0]MEMreg_real_readmemdata_EXE_64_mask;
    reg [63:0]MEMreg_real_readmemdata_MEM_64_mask;
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
        MEMreg_memconflict_enable = 1'b1;
        MEMreg_memconflict_data_enable = 1'b1;
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
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen9 (clk, rst, EXEreg_readmemaddr, MEMreg_readmemaddr, MEMreg_readmemaddr_enable);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen10 (clk, rst, EXEreg_memconflict, MEMreg_memconflict, MEMreg_memconflict_enable);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_ge11 (clk, rst, EXEreg_memconflict_data, MEMreg_memconflict_data, MEMreg_memconflict_data_enable);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_ge12 (clk, rst, EXEreg_real_readmemdata_EXE_64_mask, MEMreg_real_readmemdata_EXE_64_mask, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_ge13 (clk, rst, EXEreg_real_readmemdata_MEM_64_mask, MEMreg_real_readmemdata_MEM_64_mask, 1'b1);
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
    wire [63:0] rdata_t;
/*     wire [31:0]rdata_32;
    assign rdata_32 = rdata[31:0];
    import "DPI-C" function void get_rdata_value(int rdata_32);
    always@(*) get_rdata_value(rdata_32);    */ 
    wire dsram_arvalid;
    assign dsram_arvalid = MemRd & ID_reg_valid;
    wire dsram_arready;
    wire dsram_rresp;
    wire dsram_rvalid;
    wire dsram_rready;
    assign dsram_rready = MemRd & ID_reg_valid;
    wire dsram_awvalid;
    assign dsram_awvalid = MEMreg_memwr & MEMreg_valid;
    wire dsram_awready;
    wire dsram_wvalid;
    assign dsram_wvalid = MEMreg_memwr & MEMreg_valid;
    wire dsram_wready;
    wire [7:0]dsram_wstrb;
    wire dsram_bresp;
    wire dsram_bvalid;
    ysyx_22050854_MuxKey #(4,3,8) gen_dsram_wstrb (dsram_wstrb,MEMreg_memop,{
        3'b000,8'b00000001,  // sb   000
        3'b001,8'b00000011,  // sh
        3'b010,8'b00001111,  // sw
        3'b011,8'b11111111   // sd
    });
    ysyx_22050854_SRAM_LSU cpu_lsu (
        .clk(clk),
        .rst_n(rst_n),

        //read address channel
        .araddr(readmemaddr[31:0]),
        .arvalid(dsram_arvalid),
        .arready(dsram_arready), 

        //read data channel
        .rdata(rdata_t),
        .rresp(dsram_rresp),
        .rvalid(dsram_rvalid),
        .rready(dsram_arready),

        //write address channel
        .awaddr(MEMreg_aluout[31:0]),
        .awvalid(dsram_awvalid),
        .awready(dsram_awready),

        //write data channel
        .wdata(MEMreg_writememdata),
        .wvalid(dsram_wvalid),
        .wready(dsram_wready),
        .wstrb(dsram_wstrb),

        //write response channel
        .bresp(dsram_bresp),
        .bvalid(dsram_bvalid),
        .bready(1'b1)
    );

    //因为从存储器读出的数据总是8字节的,所以要根据地址以及位数获得不同的数据
    wire [63:0]read_mem_data;
    assign rdata = MEMreg_memconflict ? ( (rdata_t & (~MEMreg_real_readmemdata_EXE_64_mask) & ( ~MEMreg_real_readmemdata_MEM_64_mask)) | MEMreg_memconflict_data) : rdata_t;
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
    
    wire [31:0]dsram_rresp_32;
    assign dsram_rresp_32 = {31'b0,dsram_rresp};
    import "DPI-C" function void get_dsram_rresp_value(int dsram_rresp_32);
    always@(*) get_dsram_rresp_value(dsram_rresp_32);
    wire [31:0]wr_reg_data_32;
    assign wr_reg_data_32 = wr_reg_data[31:0];
    import "DPI-C" function void get_wr_reg_data_value(int wr_reg_data_32);
    always@(*) get_wr_reg_data_value(wr_reg_data_32);
    wire [31:0]rdata_32;
    assign rdata_32 = read_mem_data[31:0];
    import "DPI-C" function void get_rdata_value(int rdata_32);
    always@(*) get_rdata_value(rdata_32);

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
    reg WBreg_memop_enable;
    reg [2:0]WBreg_memop;
    reg WBreg_memRd_enable;
    reg WBreg_memRd;
    reg WBreg_memwr;  //for debug, 判断是否是访问外设的命令，若是，跳过difftest
    reg WBreg_memtoreg_enable;
    reg WBreg_memtoreg;
    reg WBreg_memconflict_enable;
    reg WBreg_memconflict;
    reg WBreg_memconflict_data_enable;
    reg [63:0]WBreg_memconflict_data;
    reg WBreg_CSRrd_enable;
    reg WBreg_CSRrd;
    reg WBreg_CSRrdata_enable;
    reg [63:0]WBreg_CSRrdata;
    always@(*)begin
        WBreg_inst_enable = 1'b1;
        WBreg_pc_enable = 1'b1;
        WBreg_readmemdata_enable = dsram_rresp;
        WBreg_regwr_enable = 1'b1;
        WBreg_rd_enable = 1'b1;
        WBreg_memtoreg_enable = 1'b1;
        WBreg_aluout_enable = 1'b1;
        WBreg_memop_enable = 1'b1;
        WBreg_memRd_enable = 1'b1;
        WBreg_memconflict_enable = 1'b1;
        WBreg_memconflict_data_enable = 1'b1;
        WBreg_CSRrd_enable = 1'b1;
        WBreg_CSRrdata_enable = 1'b1;
    end
    ysyx_22050854_Reg #(32,32'b0) WBreg_geninst (clk, rst, MEMreg_inst, WBreg_inst, WBreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) WBreg_genPC (clk, rst, MEMreg_pc, WBreg_pc, WBreg_pc_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen0 (clk, rst, MEMreg_valid, WBreg_valid, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen1 (clk, rst, read_mem_data, WBreg_readmemdata, WBreg_readmemdata_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen2 (clk, rst, MEMreg_regwr, WBreg_regwr, WBreg_regwr_enable);
    ysyx_22050854_Reg #(5,5'b0) WBreg_gen3 (clk, rst, MEMreg_rd, WBreg_rd, WBreg_rd_enable);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen4 (clk, rst, MEMreg_aluout, WBreg_aluout, WBreg_aluout_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen5 (clk, rst, MEMreg_memtoreg, WBreg_memtoreg, WBreg_memtoreg_enable);
    ysyx_22050854_Reg #(3,3'b0) WBreg_gen6 (clk, rst, MEMreg_memop, WBreg_memop, WBreg_memop_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen7 (clk, rst, MEMreg_memrd, WBreg_memRd, WBreg_memRd_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen8 (clk, rst, MEMreg_memconflict, WBreg_memconflict, WBreg_memconflict_enable);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen9 (clk, rst, MEMreg_memconflict_data, WBreg_memconflict_data, WBreg_memconflict_data_enable);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen10 (clk, rst, MEMreg_memrd, WBreg_memwr, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) WBreg_ge11 (clk, rst, MEMreg_CSRrd, WBreg_CSRrd, WBreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) WBreg_ge12 (clk, rst, MEMreg_CSRrdata, WBreg_CSRrdata, WBreg_CSRrdata_enable);

    //写回寄存器的数据，总共有三种可能 1.alu计算值  2.从内存读出的数据 3.从CSR读出的数据
    wire [63:0]wr_reg_data;
    //assign wr_reg_data = WBreg_memtoreg ? ( WBreg_memconflict ? WBreg_memconflict_data : WBreg_readmemdata ): (CSRrd ? csr_rdata : WBreg_aluout);
    assign wr_reg_data = WBreg_memtoreg ? ( WBreg_readmemdata ): (WBreg_CSRrd ? WBreg_CSRrdata : WBreg_aluout);

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
    reg DIFFreg_memwr;
    ysyx_22050854_Reg #(1,1'b0) DIFFreg_memwr_gen (clk, rst, WBreg_memwr, DIFFreg_memwr, 1'b1);
    reg DIFFreg_memrd;
    ysyx_22050854_Reg #(1,1'b0) DIFFreg_memrd_gen (clk, rst, WBreg_memRd, DIFFreg_memrd, 1'b1);
    wire is_accessdevice;
    assign is_accessdevice = ( DIFFreg_memrd ) ? ( (access_mem_addr > 32'h8fffffff) ? 1'b1 : 1'b0 ) : 1'b0;

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


endmodule 
