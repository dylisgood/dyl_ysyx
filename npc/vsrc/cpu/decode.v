module ysyx_22050854_IDU(
    input [31:0]instr,
    output [4:0]rs1,
    output [4:0]rs2,
    output [4:0]rd,
    output reg [2:0]ExtOP,
    output  RegWr,
    output  [2:0]Branch,
    output  reg No_branch,
    output  MemtoReg,
    output  MemWr,
    output  MemRd,
    output  reg [2:0]MemOP,
    output  reg ALUsrc1,
    output  reg [1:0]ALUsrc2,
    output  [3:0]ALUctr,
    output  reg [3:0]MULctr,
    output  [2:0]ALUext
); 
    wire [6:0]op;
    wire [2:0]func3;
    wire func7_5;
    wire func7_0;

    assign op = instr[6:0];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];
    assign func3 = instr[14:12];
    assign func7_0 = instr[25];
    assign func7_5 = instr[30];

    //generate ExtOP for generate imm
    always @(*)begin
        case(op[6:2])
            5'b00000: ExtOP = 3'b000; //lb lh lw ld  I
            5'b01000: ExtOP = 3'b010; //sb sh sw sd  S
            5'b00100: ExtOP = 3'b000; //addi slti ... I 
            5'b11001: ExtOP = 3'b000; //jarl I
            5'b00110: ExtOP = 3'b000; //addiw I
            5'b11000: ExtOP = 3'b011; //BEQ BNE ... B
            5'b01101: ExtOP = 3'b001; //lui  U
            5'b00101: ExtOP = 3'b001; //auipc U
            5'b11011: ExtOP = 3'b100; //jal J
            default : ExtOP = 3'b111;
        endcase
    end

    //generate RegWr 是否写回寄存器
    reg RegWr_t;
    always @(*)begin
        case(op[6:0])
            7'b0110111: RegWr_t = 1'b1;  //lui
            7'b0010111: RegWr_t = 1'b1;  //auipc
            7'b0010011: RegWr_t = 1'b1;  //addi
            7'b0110011: RegWr_t = 1'b1;  //add 
            7'b1101111: RegWr_t = 1'b1;  //jar
            7'b1100111: RegWr_t = 1'b1;  //jarl
            7'b1100011: RegWr_t = 1'b0;  //beq bne ....
            7'b0000011: RegWr_t = 1'b1;  //lb lh lw ld lbu lhu lwu
            7'b0100011: RegWr_t = 1'b0;  //sb sh sw sd
            7'b0011011: RegWr_t = 1'b1;  //ADDIW
            7'b0111011: RegWr_t = 1'b1;  //ADDW
            7'b1110011: RegWr_t = 1'b1;   //ecall csrw csrr, but mret ebreak should not write register
            7'b0001111: RegWr_t = 1'b0;  //fence.i 
            default: RegWr_t = 1'b0;
        endcase
    end
    assign RegWr = ( (instr == 32'h30200073) || (instr == 32'h100073) ) ? 0 : RegWr_t;  //mret and ebreak not write

    //generate MemtoReg 写回寄存器的内容来自哪里 0-alu_out 1-mem_data
    assign MemtoReg = op == 7'b0000011 ? 1'b1 : 1'b0;

    //generate Branch
    reg [2:0]Branch_temp; 
    always @(*) begin
        case({op[6:2],func3})
            8'b11000000: Branch_temp = 3'b100; //beq
            8'b11000001: Branch_temp = 3'b101; //bneq
            8'b11000100: Branch_temp = 3'b110; //blt
            8'b11000101: Branch_temp = 3'b111; //bge
            8'b11000110: Branch_temp = 3'b110; //bltu
            8'b11000111: Branch_temp = 3'b111; //bgeu
            default: Branch_temp = 3'b000;
        endcase
    end
    assign Branch = op[6:2] == 5'b11011 ? 3'b001 : //jal
                    op[6:2] == 5'b11001 ? 3'b010 : //jalr
                    Branch_temp;

    //generate No_branch pc + 4
    always @(*)begin
        case(op)
            7'b0110111: No_branch = 1'b1;  //lui
            7'b0010111: No_branch = 1'b1;  //auipc
            7'b0000011: No_branch = 1'b1;  //ld
            7'b0100011: No_branch = 1'b1;  //sd
            7'b0010011: No_branch = 1'b1;  //addi
            7'b0110011: No_branch = 1'b1;  //add
            7'b1110011: No_branch = 1'b1;  //csrrw csrr but not ecall mret
            7'b0011011: No_branch = 1'b1;  //slliw
            7'b0111011: No_branch = 1'b1;  //sllw
            7'b0001111: No_branch = 1'b1;  //fence.I
            default: No_branch = 1'b0;
        endcase
    end

    //generate MemWr 是否写存储器
    assign MemWr = op == 7'b0100011 ? 1'b1 : 1'b0;

    //generate MemRd 是否读存储器
    assign MemRd = op == 7'b0000011 ? 1'b1 : 1'b0;

    //generate MemOP 如何写存储器
    always @(*) begin
        case({op[6:2],func3})
            8'b00000000: MemOP = 3'b000;  //lb
            8'b00000001: MemOP = 3'b001;  //lh
            8'b00000010: MemOP = 3'b010;  //lw
            8'b00000011: MemOP = 3'b011;  //ld
            8'b00000100: MemOP = 3'b100;  //lbu
            8'b00000101: MemOP = 3'b101;  //lhu
            8'b00000110: MemOP = 3'b110;  //lwu
            8'b01000000: MemOP = 3'b000;  //sb
            8'b01000001: MemOP = 3'b001;  //sh
            8'b01000010: MemOP = 3'b010;  //sw
            8'b01000011: MemOP = 3'b011;  //sd
            default: MemOP = 3'b111;
        endcase
    end

    //generate ALUsrc1    0---rs1  1---pc
    always @(*) begin
        case(op[6:2])
            5'b01101: ALUsrc1 = 1'b0; //lui (copy,don't need alu_src1)
            5'b00101: ALUsrc1 = 1'b1; //auipc
            5'b00100: ALUsrc1 = 1'b0; //addiq
            5'b01100: ALUsrc1 = 1'b0; //add mul
            5'b11011: ALUsrc1 = 1'b1; //jal
            5'b11001: ALUsrc1 = 1'b1; //jalr
            5'b11000: ALUsrc1 = 1'b0; //beq
            5'b00000: ALUsrc1 = 1'b0; //load
            5'b01000: ALUsrc1 = 1'b0; //store
            5'b00110: ALUsrc1 = 1'b0; //ADDIW sraiw
            5'b01110: ALUsrc1 = 1'b0; //ADDW MULW
            default: ALUsrc1 = 1'b1;    
        endcase
    end

    //generate ALUsrc2   00---rs2   01---imm  10---4
    always @(*) begin
        case(op[6:2])
            5'b01101: ALUsrc2 = 2'b01; //lui
            5'b00101: ALUsrc2 = 2'b01; //auipc
            5'b00100: ALUsrc2 = 2'b01; //addi
            5'b01100: ALUsrc2 = 2'b00; //add mul
            5'b11011: ALUsrc2 = 2'b10; //jal
            5'b11001: ALUsrc2 = 2'b10; //jalr
            5'b11000: ALUsrc2 = 2'b00; //beq
            5'b00000: ALUsrc2 = 2'b01; //load
            5'b01000: ALUsrc2 = 2'b01; //store
            5'b00110: ALUsrc2 = 2'b01; //ADDIW
            5'b01110: ALUsrc2 = 2'b00; //ADDW MULW  
            default: ALUsrc2 = 2'b00;
        endcase
    end

    //generate ALUext for rv64I
    reg [2:0]ALUext_temp;
    always @(*) begin
        case({ op[6:2],func3,func7_5,func7_0 })
            10'b0111000000: ALUext_temp =  3'b010;  // + addw
            10'b0111000010: ALUext_temp =  3'b010;  // - subw
            10'b0011000100: ALUext_temp =  3'b011;  // <<  slliw
            10'b0011010100: ALUext_temp =  3'b011;  // >>  srliw
            10'b0011010110: ALUext_temp =  3'b011;  // >>> sraiw
            10'b0111000100: ALUext_temp =  3'b011;  // <<  sllw
            10'b0111010100: ALUext_temp =  3'b011;  // >>  srlw
            10'b0111010110: ALUext_temp =  3'b011;  // >>> sraw
            10'b0110001000: ALUext_temp =  3'b001;  //  slt compare
            10'b0110001100: ALUext_temp =  3'b001;  //  sltu compare
            10'b0110000001: ALUext_temp =  3'b100;  //mul
            10'b0110000101: ALUext_temp =  3'b101;  //mulh
            10'b0110001001: ALUext_temp =  3'b101;  //mulhsu
            10'b0110001101: ALUext_temp =  3'b101;  //mulhu
            10'b0110010001: ALUext_temp =  3'b110;  //div
            10'b0110010101: ALUext_temp =  3'b110;  //divu
            10'b0110011001: ALUext_temp =  3'b111;  //rem
            10'b0110011101: ALUext_temp =  3'b111;  //remu
            10'b0111000001: ALUext_temp =  3'b100;  //mulw
            10'b0111010001: ALUext_temp =  3'b110;  //divw
            10'b0111010101: ALUext_temp =  3'b110;  //divuw
            10'b0111011001: ALUext_temp =  3'b111;  //remw
            10'b0111011101: ALUext_temp =  3'b111;  //remuw
            default: ALUext_temp = 3'b0;
        endcase  
    end
/*     always @(*) begin
        case({ op[6:2],func3,func7_5,func7_0 })
            10'b0111000000: ALUext_temp =  3'b010;  // + addw
            10'b0111000010: ALUext_temp =  3'b010;  // - subw
            10'b0011000100: ALUext_temp =  3'b011;  // <<  slliw
            10'b0011010100: ALUext_temp =  3'b011;  // >>  srliw
            10'b0011010110: ALUext_temp =  3'b011;  // >>> sraiw
            10'b0111000100: ALUext_temp =  3'b011;  // <<  sllw
            10'b0111010100: ALUext_temp =  3'b011;  // >>  srlw
            10'b0111010110: ALUext_temp =  3'b011;  // >>> sraw
            10'b0110001000: ALUext_temp =  3'b001;  //  slt compare
            10'b0110001100: ALUext_temp =  3'b001;  //  sltu compare
            10'b0110000001: ALUext_temp =  3'b100;  //mul
            10'b0110000101: ALUext_temp =  3'b101;  //mulh
            10'b0110001001: ALUext_temp =  3'b101;  //mulhsu
            10'b0110001101: ALUext_temp =  3'b101;  //mulhu
            10'b0110010001: ALUext_temp =  3'b110;  //div
            10'b0110010101: ALUext_temp =  3'b110;  //divu
            10'b0110011001: ALUext_temp =  3'b110;  //rem
            10'b0110011101: ALUext_temp =  3'b110;  //remu
            10'b0111000001: ALUext_temp =  3'b111;  //mulw
            10'b0111010001: ALUext_temp =  3'b111;  //divw
            10'b0111010101: ALUext_temp =  3'b111;  //divuw
            10'b0111011001: ALUext_temp =  3'b111;  //remw
            10'b0111011101: ALUext_temp =  3'b111;  //remuw
            default: ALUext_temp = 3'b0;
        endcase  
    end 
*/

    assign ALUext = {op[6:2],func3} == 8'b00110000 ? 3'b010 :            //addiw
                    {op[6:2],func3[2:1]} == 7'b0010001 ? 3'b001 :        //slti sltiu
                    ALUext_temp;


    //generate ALUctr according to op funct3,funct7
    reg [3:0]ALUctr_temp;
    always @(*) begin
        case({op[6:2],func3,func7_5 })
            9'b001000000: ALUctr_temp = 4'b0000;  // + addi
            9'b001000001: ALUctr_temp = 4'b0000;  //   addi  
            9'b001000100: ALUctr_temp = 4'b0010;  //  slti compare
            9'b001000101: ALUctr_temp = 4'b0010;  //  slti compare
            9'b001000110: ALUctr_temp = 4'b1010;  //  sltiu compare
            9'b001000111: ALUctr_temp = 4'b1010;  //  sltiu compare
            9'b001001000: ALUctr_temp = 4'b0100;  // ^  xori
            9'b001001001: ALUctr_temp = 4'b0100;  // ^  xori
            9'b001001100: ALUctr_temp = 4'b0110;  // |  ori
            9'b001001101: ALUctr_temp = 4'b0110;  // |  ori
            9'b001001110: ALUctr_temp = 4'b0111;  // & andi
            9'b001001111: ALUctr_temp = 4'b0111;  // & andi
            9'b001000010: ALUctr_temp = 4'b0001;  // << slli
            9'b001001010: ALUctr_temp = 4'b0101;  // >> srli
            9'b001001011: ALUctr_temp = 4'b1101;  // >>> srai
            9'b001100010: ALUctr_temp = 4'b0001;  // <<  slliw
            9'b001101010: ALUctr_temp = 4'b0101;  // >>  srliw
            9'b001101011: ALUctr_temp = 4'b1101;  // >>> sraiw
            9'b011100010: ALUctr_temp = 4'b0001;  // << sllw
            9'b011101010: ALUctr_temp = 4'b0101;  // >> srlw
            9'b011101011: ALUctr_temp = 4'b1101;  // >>> sraw
            9'b011100000: ALUctr_temp = 4'b0000;  // + addw
            9'b011100001: ALUctr_temp = 4'b1000;  // - subw
            9'b001100000: ALUctr_temp = 4'b0000;  // + addiw
            9'b001100001: ALUctr_temp = 4'b0000;  // + addiw
            9'b011000000: ALUctr_temp = 4'b0000;  // + add
            9'b011000001: ALUctr_temp = 4'b1000;  // - sub
            9'b011000010: ALUctr_temp = 4'b0001;  // << sll
            9'b011000100: ALUctr_temp = 4'b0010;  // slt compare
            9'b011000110: ALUctr_temp = 4'b1010;  // sltu compare
            9'b011001000: ALUctr_temp = 4'b0100;  // ^ xor
            9'b011001010: ALUctr_temp = 4'b0101;  // >> srl
            9'b011001011: ALUctr_temp = 4'b1101;  // >>> sra
            9'b011001100: ALUctr_temp = 4'b0110;  // | or
            9'b011001110: ALUctr_temp = 4'b0111;  // & and
            9'b110010000: ALUctr_temp = 4'b0000;  // pc + 4 jalr
            9'b110010001: ALUctr_temp = 4'b0000;  // pc + 4 jalr
            default : ALUctr_temp = 4'b1111;
        endcase 
    end
    assign ALUctr = op[6:2] == 5'b01101 ? 4'b0011 :    //lui copy
                    op[6:2] == 5'b00101 ? 4'b0000 :    //auipc
                    op[6:2] == 5'b11011 ? 4'b0000 :    //jal
                    op[6:2] == 5'b00000 ? 4'b0000 :    //all load instructions
                    op[6:2] == 5'b01000 ? 4'b0000 :    //all store instructions
                    { op[6:2],func3[1] } == 6'b110000 ? 4'b0010 :   //beq bne blt bge 
                    { op[6:2],func3[2:1] } == 7'b1100011 ? 4'b1010 : //bltu bgeu
                    ALUctr_temp;

    always @(*) begin
        case({op[6:2],func3,func7_0 })
            9'b011000001: MULctr = 4'b1001;  //mul
            9'b011000011: MULctr = 4'b0001;  //mulh
            9'b011000101: MULctr = 4'b0010;  //mulhsu
            9'b011000111: MULctr = 4'b0011;  //mulhu
            9'b011001001: MULctr = 4'b0100;  //div
            9'b011001011: MULctr = 4'b0101;  //divu
            9'b011001101: MULctr = 4'b0110;  //rem
            9'b011001111: MULctr = 4'b0111;  //remu
            9'b011100001: MULctr = 4'b1000;  //mulw
            9'b011101001: MULctr = 4'b1100;  //divw
            9'b011101011: MULctr = 4'b1101;  //divuw
            9'b011101101: MULctr = 4'b1110;  //remw
            9'b011101111: MULctr = 4'b1111;  //remuw
            default: MULctr = 4'b0000;
        endcase    
    end

endmodule


