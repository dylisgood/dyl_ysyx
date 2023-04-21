`timescale 1ns/1ps
module ysyx_22050854_cpu(
    input rst,
    input clk,
    //input [31:0]inst,
    output [31:0]next_pc,
    output ebreak,
    output [63:0]alu_src1,
    output [63:0]alu_src2,
    output [63:0]x10
);   
    import "DPI-C" function void v_pmem_read(
    input longint raddr, output longint rdata);

    import "DPI-C" function void v_pmem_write(
    input longint waddr, input longint wdata, input longint wmask);

    reg [63:0]inst_64;
    reg [63:0]pc_64;
    reg [31:0]inst;
    always @(negedge clk) begin
    if(!rst)begin
        pc_64={32'd0,next_pc};
        v_pmem_read(pc_64, inst_64);
        inst = (next_pc[2:0] == 3'b000) ? inst_64[31:0] : inst_64[63:32];
    end
    else
        inst_64 = 64'd0;
    end
    import "DPI-C" function void get_inst_value(int inst);
    always@(*) get_inst_value(inst);

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
        .instr(inst),
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
        .MULctr(MULctr),
        .ebreak(ebreak)        
    );   

    wire [63:0]imm;
    ysyx_22050854_imm_gen gen_imm(
    .instr(inst),
    .ExtOP(ExtOP),
    .imm(imm)
);

    wire [63:0]wr_reg_data;
    wire [63:0]read_mem_data;
    ysyx_22050854_MuxKey #(2,1,64) gen_write_reg (wr_reg_data,MemtoReg,{
        1'b0,alu_out,
        1'b1,read_mem_data
    });

    wire [63:0]src1;
    wire [63:0]src2;
    ysyx_22050854_RegisterFile regfile_inst(
    .clk(clk),
    .wdata(wr_reg_data),
    .waddr(rd),
    .wen(RegWr),
    .raddra(rs1),
    .raddrb(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .test_addr1(),
    .test_addr2(5'd10),
    .test_rdata1(),
    .test_rdata2(x10)    
    );

/*     wire [63:0]alu_src1;
    wire [63:0]alu_src2; */
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

    /* wire [31:0]next_pc; */
    wire [31:0]pc;
    ysyx_22050854_pc gen_pc(
    .rst(rst),
    .clk(clk),
    .Branch(Branch),
    .No_branch(No_branch),
    .zero(zero),
    .less(less),
    .src1(src1),
    .imm(imm),
    .pc(pc),
    .next_pc(next_pc)
    );

    reg [63:0] rdata;
    wire [63:0] wmask; //用于产生有关写存储器的掩码，决定写存储器的字节数
    ysyx_22050854_MuxKey #(4,3,64) gen_wmask (wmask,MemOP,{
        3'b000,64'h00000000000000ff,  // sb   000
        3'b001,64'h000000000000ffff,  // sh
        3'b010,64'h00000000ffffffff,  // sw
        3'b011,64'hffffffffffffffff   // sd
    });

    //读取数据存储器
    always @(*) begin
    if(MemRd==1'b1 && alu_out >= 64'h80000000) begin
        v_pmem_read(alu_out, rdata);
    end
    else begin
        rdata = 64'd0;
    end
    end
    
    always @(posedge clk) begin
    if(MemWr==1'b1 && alu_out >= 64'h80000000) begin
        v_pmem_write(alu_out, src2, wmask);
    end
    end

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
