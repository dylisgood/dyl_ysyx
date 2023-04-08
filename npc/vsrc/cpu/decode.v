//1.decode
`timescale 1ns/1ps  
//2.get operate num from resiger file
module ysyx_22050854_IDU(
    input [31:0]instr,
    output reg[4:0]rs1,
    output reg[4:0]rs2,
    output reg[4:0]rd,
    output reg[2:0]ExtOP,
    output reg RegWr,
    output [2:0]Branch,
    output reg MemtoReg,
    output reg MemWr,
    output reg [2:0]MemOP,
    output reg ALUsrc1,
    output reg [1:0]ALUsrc2,
    output reg [3:0]ALUctr,
    output ebreak
); 
    wire [6:0]op;
    wire [2:0]func3;
    wire [6:0]func7;
    wire [63:0]immI,immU,immS,immB,immJ;

    assign op = instr[6:0];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];
    assign func3 = instr[14:12];
    assign func7 = instr[31:25];

    ysyx_22050854_MuxKey #(1,32,1) ebreak_gen (ebreak,instr,{
        32'b0000_0000_0001_0000_0000_0000_0111_0011,1'b1
    });
    
    //generate ExtOP for generate imm
    ysyx_22050854_MuxKeyWithDefault #(9,5,3) ExtOP_gen (ExtOP,op[6:2],3'b111,{
        5'b00000,3'b000,
        5'b00100,3'b000, //addi
        5'b11001,3'b000,
        5'b00110,3'b000,
        5'b01001,3'b010,
        5'b11000,3'b011,
        5'b01101,3'b001, //lui
        5'b00101,3'b001, //auipc
        5'b11011,3'b100
    });

    //generate RegWr 是否写回寄存器
    ysyx_22050854_MuxKeyWithDefault #(11,5,1) RegWr_gen (RegWr,op[6:2],1'b0,{
        5'b01101,1'b1,  //lui
        5'b00101,1'b1,  //auipc
        5'b00100,1'b1,  //addi
        5'b01100,1'b1,
        5'b11011,1'b1,
        5'b11001,1'b1,
        5'b11000,1'b0,
        5'b00000,1'b1,
        5'b01000,1'b0,
        5'b00110,1'b1, //ADDIW
        5'b01110,1'b1  //ADDW
    });

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
        8'b11000000,3'b100,
        8'b11000001,3'b101,
        8'b11000100,3'b110,
        8'b11000101,3'b111,
        8'b11000110,3'b110,
        8'b11000111,3'b111
    });

    //generate MemtoReg 写回寄存器的内容来自哪里 0-alu_out 1-mem_data
    ysyx_22050854_MuxKeyWithDefault #(11,5,1) MemtoReg_gen (MemtoReg,op[6:2],1'b0,{
        5'b01101,1'b0, //lui
        5'b00101,1'b0, //auipc
        5'b00100,1'b0, //addi
        5'b01100,1'b0, 
        5'b11011,1'b0, //jal
        5'b11001,1'b0, //jalr
        5'b11000,1'b0,
        5'b00000,1'b1, //load
        5'b01000,1'b0, //store
        5'b00110,1'b0, //ADDIW
        5'b01110,1'b0  //ADDW       
    });

    //generate MemWr 是否写存储器
    ysyx_22050854_MuxKeyWithDefault #(11,5,1) MemWr_gen (MemtoReg,op[6:2],1'b0,{
        5'b01101,1'b0, //lui
        5'b00101,1'b0, //auipc
        5'b00100,1'b0, //addi
        5'b01100,1'b0,
        5'b11011,1'b0, //jal
        5'b11001,1'b0, //jalr
        5'b11000,1'b0,
        5'b00000,1'b0, //load
        5'b01000,1'b1, //store
        5'b00110,1'b0, //ADDIW
        5'b01110,1'b0  //ADDW       
    });

    //generate MemOP 如何写存储器
    ysyx_22050854_MuxKeyWithDefault #(10,8,3) MemOP_gen (MemOP,{op[6:2],func3},3'b111,{
        8'b00000000,3'b000,  //lb
        8'b00000001,3'b001,  //lh
        8'b00000010,3'b010,  //lw
        8'b00000100,3'b100,  //lbu
        8'b00000101,3'b101,  //lhu
        8'b00000110,3'b110,  //lwu
        8'b01000000,3'b000,  //sb
        8'b01000001,3'b001,  //sh
        8'b01000010,3'b010,  //sw
        8'b01000011,3'b011  //sd
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
        5'b00110,1'b0, //ADDIW
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

    //generate ALUctr according to op funct3,funct7
    ysyx_22050854_MuxKeyWithDefault #(85,9,4) ALUctr_gen (ALUctr,{op[6:2],func3,func7[5]},4'b1111,{
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
        9'b00100010x,4'b0010,  //  compare
        9'b00100011x,4'b1010,  //u compare
        9'b00100100x,4'b0100,  // ^
        9'b00100110x,4'b0110,  // |
        9'b00100111x,4'b0111,  // &
        9'b001000010,4'b0001,  // << 
        9'b001001010,4'b0101,  // >>
        9'b001001011,4'b1101,  // >>>
        9'b011000000,4'b0000,  // +
        9'b011000001,4'b1000,  // -
        9'b011000010,4'b0001,  // <<
        9'b011000100,4'b0010,  //compare
        9'b011000110,4'b1010,  //u compare
        9'b011001000,4'b0100,  // ^
        9'b011001010,4'b0101,  // >>
        9'b011001011,4'b1101,  // >>>
        9'b011001100,4'b0110,  // |
        9'b011001110,4'b0111,  // &
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
        9'b11000000x,4'b0010,  // compare
        9'b11000001x,4'b0010,
        9'b11000100x,4'b0010,
        9'b11000101x,4'b0010,
        9'b11000110x,4'b1010,  //u compare
        9'b11000111x,4'b1010,
        9'b00000000x,4'b0000,  // mem addr
        9'b00000001x,4'b0000,
        9'b00000010x,4'b0000,
        9'b00000011x,4'b0000,
        9'b00000100x,4'b0000,
        9'b00000101x,4'b0000,
        9'b01000000x,4'b0000,
        9'b01000001x,4'b0000,
        9'b01000010x,4'b0000          
    });

endmodule
