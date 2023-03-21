`timescale 1ns/1ps
module ysyx_22050854_cpu(
    input rst,
    input clk,
    input [31:0]inst,
    output [31:0]pc,
    output ebreak,
    output reg [63:0]x5,
    output reg [63:0]x6
);   
    //ysyx_22050854_ifu fetch_instr(.clk(clk), .pc(pc), .instr(instr));   
    wire [4:0]rs1,rs2,rd;
    wire [2:0]ExtOP;
    wire RegWr;
    wire [2:0]Branch;
    wire MemtoReg;
    wire MemWr;
    wire [2:0]MemOP;
    wire ALUsrc1;
    wire [1:0]ALUsrc2;
    wire [3:0]ALUctr;
    ysyx_22050854_IDU instr_decode(
        .instr(inst),
        .rs1(rs1),                          
        .rs2(rs2),
        .rd(rd),
        .ExtOP(ExtOP),
        .RegWr(RegWr),
        .Branch(Branch),
        .MemtoReg(MemtoReg),
        .MemWr(MemWr),
        .MemOP(MemOP),
        .ALUsrc1(ALUsrc1),
        .ALUsrc2(ALUsrc2),
        .ALUctr(ALUctr),
        .ebreak(ebreak)        
    );   

    wire [63:0]imm;
    ysyx_22050854_imm_gen gen_imm(
    .instr(inst),
    .ExtOP(ExtOP),
    .imm(imm)
);

    wire [63:0]src1;
    wire [63:0]src2;
    ysyx_22050854_RegisterFile regfile_inst(
    .clk(clk),
    .wdata(alu_out),
    .waddr(rd),
    .wen(RegWr),
    .raddra(rs1),
    .raddrb(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .test_addr1(5'd5),
    .test_addr2(5'd6),
    .test_rdata1(x5),
    .test_rdata2(x6)    
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
    .src1(alu_src1),
    .src2(alu_src2),
    .alu_out(alu_out),
    .less(less),
    .zero(zero) 
);

    ysyx_22050854_pc gen_pc(
    .rst(rst),
    .clk(clk),
    .Branch(Branch),
    .zero(zero),
    .less(less),
    .src1(src1),
    .imm(imm),
    .pc(pc)
);

/*     wire [63:0]mem_data = 64'd0;
    ysyx_22050854_write_back rd_wb(
    .clk(clk),
    .MemtoReg(MemtoReg),
    .RegWr(RegWr),
    .alu_out(alu_out),
    .mem_data(mem_data),
    .rd(rd)
);   */



/*   register i_re1 (
  .clk(clk),
  .wdata(64'd5),
  .waddr(5'd6),
  .wen(1'd1),
  .ren(1'd0),
  .raddra(),
  .rdata()
); */

endmodule 
