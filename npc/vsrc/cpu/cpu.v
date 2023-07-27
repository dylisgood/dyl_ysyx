`timescale 1ns/1ps
module ysyx_22050854_cpu(
    input rst,
    input clk,
    //input suspend,
    output timer_interrupt,
    output ebreak,
    output [63:0]x10
);   
    import "DPI-C" function void v_pmem_read(
    input longint raddr, output longint rdata);

    import "DPI-C" function void v_pmem_write(
    input longint waddr, input longint wdata, input longint wmask);

    reg suspend;

    wire rst_n;
    assign rst_n = ~rst;
    wire isram_arready;
    wire isram_rresp;
    wire isram_rvalid;
    wire [63:0]isram_rdata;
    wire isram_arvalid;
    wire isram_rready;
    wire isram_rready_t;
    reg wr_reg_over;
    always @(*)begin
        wr_reg_over = RegWr ? (wen ? 1'b1 : 1'b0) : 1'b0; //addi load
    end
    reg wr_mem_over;
    always @(*)begin
        wr_mem_over = MemWr ? (dsram_bresp ? 1'b1 : 1'b0) : 1'b0;  //store
    end
    reg wr_csr_over;
    always @(*)begin
        wr_csr_over = ( CSRwr | CSRwr2 ) ?  (CSRwr_wen1 | CSRwr_wen2) : 1'b0;
    end
    //一个指令的结束 可以是写寄存器使能  写存储器回应 CSR相关 或beq更新pc
    assign isram_rready_t = wr_reg_over | wr_mem_over | (inst[6:0] == 7'b1110011) | (inst[6:0] == 7'b1100011);
    assign isram_rready = next_pc == 32'h80000000 ? 1'b1 : isram_rready_t;
    ysyx_22050854_SRAM_IFU cpu_ifu(
        .clk(clk),
        .rst_n(rst_n),

        .araddr(next_pc),
        .arvalid(isram_rready),
        .arready(isram_arready),

        .rdata(isram_rdata),
        .rresp(isram_rresp),
        .rvalid(isram_rvalid),
        .rready(isram_rready)
    );

    //
    wire [63:0]pc_64;
    reg [31:0]inst;
    reg [31:0]inst_bak;
    wire [63:0]inst_64;
    assign pc_64 = { 32'd0, next_pc };
    assign inst_64 = isram_rresp == 1'b1 ? isram_rdata : 64'd0;
    always @(posedge clk) begin
        if(isram_rresp)
            inst_bak <= inst; //每一次取到指令后，将这个指令存下来 作为备份
    end

    //instruction
    always @(*)begin
        if(isram_rresp)  begin//如果是刚取到指令
            inst = ( pc[2:0] == 3'b000 ) ? inst_64[31:0] : inst_64[63:32];
        end
        else if(!isram_arready) //如果是在取指过程中，即发出取指请求的第一个周期,则让其为全0指令
            inst = 32'd0;
        else begin          //其他情况下，比如load store这种多周期指令，在这条指令没有执行完之前 一直都保持这个指令
            inst = inst_bak;
        end
    end

    import "DPI-C" function void get_inst_value(int inst);
    always@(*) get_inst_value(inst);

    assign ebreak = ( inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011 ) ? 1'b1 : 1'b0;

    reg [4:0]rs1,rs2;
    reg [4:0]rd;
    always@(*)begin
        rs1 = inst[19:15];
        rs2 = ( inst == 32'h73 ) ? 5'd17 : inst[24:20];
        rd = inst[11:7];
    end
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
        .instr(inst),
/*         .rs1(rs1),                          
        .rs2(rs2),
        .rd(rd), */
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
    .instr(inst),
    .ExtOP(ExtOP),
    .imm(imm)
);

    wire [63:0]wr_reg_data;
    wire [63:0]read_mem_data;
    assign wr_reg_data = MemtoReg ? read_mem_data : (CSRrd ? csr_rdata : alu_out);

    wire [63:0]src1;
    wire [63:0]src2;
    wire wen_t;
    wire wen;
    assign wen_t = (inst == 32'h30200073) ? 0 : ( (inst == 32'h100073) ? 0 : RegWr); //mret ebreak not write back
    wire wen_t2;
    assign wen_t2 = MemRd ? (dsram_rresp ? 1'b1 : 1'b0) : wen_t; //if load, need to wait until read memory over
    assign wen = wen_t2 & ~suspend;
    wire wreg_resp;
    ysyx_22050854_RegisterFile regfile_inst(
    .clk(clk),
    .wdata(wr_reg_data),
    .waddr(rd),
    .wen(wen),
    .wreg_resp(wreg_resp),
    .raddra(rs1),
    .raddrb(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .test_addr1(),
    .test_addr2(5'd10),
    .test_rdata1(),
    .test_rdata2(x10)    
    );

    wire CSRwr;
    wire CSRwr2;
    wire CSRrd;
    wire [11:0]csr_waddr1,csr_waddr2;
    assign csr_waddr1 = ( inst == 32'h73 ) ? 12'h341 : inst[31:20]; //if ecall, mepc
    assign csr_waddr2 = ( inst == 32'h73 ) ? 12'h342 : inst[31:20]; //if ecall, waddr = mcause

    wire [63:0]csr_wdata1,csr_wdata2;
    wire [63:0]csrwdata_t;
    ysyx_22050854_MuxKey #(6,8,64) csrwdata_gen (csrwdata_t, {inst[14:12],inst[6:2]}, {
        8'b00111100, src1,
        8'b01011100, csr_rdata | src1,
        8'b01111100, csr_rdata & ~src1,
        8'b10111100, {59'd0,inst[19:15]},
        8'b11011100, csr_rdata | {59'd0,inst[19:15]},
        8'b11111100, csr_rdata & ~{59'd0,inst[19:15]}
    });
    assign csr_wdata1 = ( inst == 32'h73 ) ? ( { 32'd0, pc } + 64'd4 ) : csrwdata_t; //ecall->mepc
    assign csr_wdata2 = ( inst == 32'h73 ) ? src2 : 64'h0;  //mcause

    wire CSRwr_t;
    ysyx_22050854_MuxKey #(6,8,1) csrwr_t_gen (CSRwr_t, {inst[14:12],inst[6:2]}, {
        8'b00111100,1'b1,
        8'b01011100,1'b1,
        8'b01111100,1'b1,
        8'b10111100,1'b1,
        8'b11011100,1'b1,
        8'b11111100,1'b1
    });
    assign CSRwr = ( inst == 32'h73 ) ? 1'b1 : CSRwr_t; //mret and ebreak not write
    assign CSRwr2 = ( inst == 32'h73 ) ? 1'b1 : 1'b0;   //only ecall need to write two csr
    assign CSRrd = ( inst[6:2] == 5'b11100 ) ? (inst == 32'h100073 ? 1'b0 : 1'b1) : 1'b0; //ebreak not read
    
    wire [11:0]csr_raddr;
    assign csr_raddr = (inst == 32'h73) ? 12'h305 : (inst == 32'h30200073 ? 12'h341 : inst[31:20]); //ecall-mtvec(305) mret-mepc(341)
    
    wire [63:0]csr_rdata;
    wire CSRwr_wen1;
    wire CSRwr_wen2;
    assign CSRwr_wen1 = CSRwr & ~suspend;
    assign CSRwr_wen2 = CSRwr2 & ~suspend;
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

    wire [63:0]alu_src1;
    wire [63:0]alu_src2;
    ysyx_22050854_src_gen gen_src(
        .ALUsrc1(ALUsrc1),
        .ALUsrc2(ALUsrc2),
        .pc(pc),
        .imm(imm),
        .src1(src1),
        .src2(src2),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2)
    );

    wire [63:0]alu_out;
    wire less,zero;
    ysyx_22050854_alu alu1(
    .ALUctr(ALUctr),
    .MULctr(MULctr),
    .ALUext(ALUext),
    .src1(alu_src1),
    .src2(alu_src2),
    .alu_out(alu_out),
    .less(less),
    .zero(zero) 
    );

    wire [31:0]next_pc;
    wire ecall_or_mret;
    assign ecall_or_mret = ( inst == 32'h73 ) ? 1 : (inst == 32'h30200073 ? 1'b1 : 1'b0);
    wire [31:0]pc;
    ysyx_22050854_pc gen_pc(
    .rst(rst),
    .clk(clk),
    .suspend(suspend),
    .Branch(Branch),
    .No_branch(No_branch),
    .is_csr_pc(ecall_or_mret),
    .csr_pc(csr_rdata[31:0]),
    .zero(zero),
    .less(less),
    .src1(src1),
    .imm(imm),
    .last_inst_over(isram_rready_t),
    .pc(pc),
    .next_pc(next_pc)
    );

    reg [63:0] rdata;
    wire dsram_arvalid;
    assign dsram_arvalid = ( MemRd==1'b1 && !suspend && isram_rresp); //确保是新鲜的指令
    wire dsram_arready;
    wire dsram_rresp;
    wire dsram_rvalid;
    wire dsram_rready;
    assign dsram_rready = ( MemRd==1'b1 && !suspend && isram_rresp);
    wire dsram_awvalid;
    assign dsram_awvalid = ( MemWr && !suspend && isram_rresp);
    wire dsram_awready;
    wire dsram_wvalid;
    assign dsram_wvalid = ( MemWr && !suspend && isram_rresp );
    wire dsram_wready;
    wire [7:0]dsram_wstrb;
    wire dsram_bresp;
    wire dsram_bvalid;
    ysyx_22050854_MuxKey #(4,3,8) gen_dsram_wstrb (dsram_wstrb,MemOP,{
        3'b000,8'b00000001,  // sb   000
        3'b001,8'b00000011,  // sh
        3'b010,8'b00001111,  // sw
        3'b011,8'b11111111   // sd
    });
    ysyx_22050854_SRAM_LSU cpu_lsu (
        .clk(clk),
        .rst_n(rst_n),

        //read address channel
        .araddr(alu_out[31:0]),
        .arvalid(dsram_arvalid),
        .arready(dsram_arready), 

        //read data channel
        .rdata(rdata),
        .rresp(dsram_rresp),
        .rvalid(dsram_rvalid),
        .rready(dsram_rready),

        //write address channel
        .awaddr(alu_out[31:0]),
        .awvalid(dsram_awvalid),
        .awready(dsram_awready),

        //write data channel
        .wdata(src2),
        .wvalid(dsram_wvalid),
        .wready(dsram_wready),
        .wstrb(dsram_wstrb),

        //write response channel
        .bresp(dsram_bresp),
        .bvalid(dsram_bvalid),
        .bready(1'b1)
    );


/*     wire [63:0] wmask; //用于产生有关写存储器的掩码，决定写存储器的字节数
    ysyx_22050854_MuxKey #(4,3,64) gen_wmask (wmask,MemOP,{
        3'b000,64'h00000000000000ff,  // sb   000
        3'b001,64'h000000000000ffff,  // sh
        3'b010,64'h00000000ffffffff,  // sw
        3'b011,64'hffffffffffffffff   // sd
    });

    //读取数据存储器 异步读取
    always @(*) begin
    if( MemRd==1'b1 && !suspend) begin
        v_pmem_read(alu_out, rdata);
    end
    else begin
        rdata = 64'd44;
    end
    end

    //write memory
    always @(posedge clk) begin
    if(MemWr==1'b1 && alu_out >= 64'h80000000 && !suspend) begin
        v_pmem_write(alu_out, src2, wmask);
    end
    end
 */
    //因为从存储器读出的数据总是8字节的,所以要根据地址以及位数获得不同的数据
    ysyx_22050854_MuxKey #(41,6,64) gen_read_mem_data (read_mem_data,{alu_out[2:0],MemOP},{
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
    


endmodule 
