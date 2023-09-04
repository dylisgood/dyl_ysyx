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
    ysyx_22050854_MuxKeyWithDefault #(12,7,1) RegWr_gen (RegWr_t,op[6:0],1'b0,{
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
        7'b1110011,1'b1   //ecall csrw csrr, but mret ebreak should not write register
    });
    assign RegWr = (instr == 32'h30200073) ? 0 : ( (instr == 32'h100073) ? 0 : RegWr_t);  //mret and ebreak not write

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
    ysyx_22050854_MuxKeyWithDefault #(10,7,1) No_branch_gen (No_branch,op,1'b0,{
        7'b0110111,1'b1,  //lui
        7'b0010111,1'b1,  //auipc
        7'b0000011,1'b1,  //ld
        7'b0100011,1'b1,  //sd
        7'b0010011,1'b1,  //addi
        7'b0110011,1'b1,  //add
        7'b1110011,1'b1,  //csrrw csrr but not ecall mret
        7'b0011011,1'b1,  //slliw
        7'b0111011,1'b1,  //sllw
        7'b0111011,1'b1   //mulw
    });

    
    //generate MemtoReg 写回寄存器的内容来自哪里 0-alu_out 1-mem_data
    assign MemtoReg = op == 7'b0000011 ? 1'b1 : 1'b0;

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
    //MemOP = func3 ?

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
