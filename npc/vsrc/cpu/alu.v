//operation
`timescale 1ns/1ps
module ysyx_22050854_alu(
    input [3:0]ALUctr,
    input [3:0]MULctr,
    input [2:0]ALUext,
    input [63:0]src1,
    input [63:0]src2,
    output signed [63:0]alu_out,
    output less,
    output zero 
);

    reg signed [31:0]alu_temp_32;
    ysyx_22050854_MuxKey #(3,4,32) gen_alu_temp_32 (alu_temp_32, ALUctr, {
        4'b0001,src1[31:0] << src2[4:0], //slliw sllw
        4'b0101,src1[31:0] >> src2[4:0], //srliw srlw
        4'b1101,($signed(src1[31:0])) >>> src2[4:0] //sraiw sraw
    });

    reg signed [63:0]alu_temp;
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
    
    assign zero = alu_temp == 64'd0 ? 1 : 0;
    assign less = ALUctr == 4'b0010 ? ( ($signed(src1)) < ($signed(src2)) ? 1 : 0) : (src1 < src2 ? 1 : 0);

    reg signed [127:0]mul_temp_128;
    ysyx_22050854_MuxKey #(4,4,128) gen_mul_temp_128 (mul_temp_128,MULctr,{
        4'b0000,{64'd0,src1} * {64'd0,src2},  //mul
        4'b0001,($signed({{64{src1[63]}},src1})) * ($signed({{64{src2[63]}},src2})),  //mulh
        4'b0010,($signed({{64{src1[63]}},src1})) * {64'd0,src2}, //mulhsu
        4'b0011,{64'd0,src1} * {64'd0,src2}  //mulhu
    });

    reg signed [63:0]mul_temp;
    ysyx_22050854_MuxKey #(4,4,64) gen_mul_temp (mul_temp,MULctr,{
        4'b0100,($signed(src1)) / ($signed(src2)),  //div
        4'b0101,src1 / src2,  //divu,
        4'b0110,($signed(src1)) % ($signed(src2)),   //rem
        4'b0111,src1 % src2   //remu
    });

    reg signed [31:0]mul_temp_32;
    ysyx_22050854_MuxKey #(5,4,32) gen_mul_temp_32 (mul_temp_32,MULctr,{
        4'b1000,($signed(src1[31:0])) * ($signed(src2[31:0])), //mulw
        4'b1100,($signed(src1[31:0])) / ($signed(src2[31:0])), //divw
        4'b1101,src1[31:0] / src2[31:0], //divuw
        4'b1110,($signed(src1[31:0])) % ($signed(src2[31:0])), //remw
        4'b1111,src1[31:0] % src2[31:0] //remuw
    });

    ysyx_22050854_MuxKey #(8,3,64) gen_alu_out (alu_out, ALUext, {
        3'b000,alu_temp,
        3'b001,{63'd0,less},
        3'b010,{{32{alu_temp[31]}},alu_temp[31:0]}, //先截断，然后按符号位扩展 addw addiw subw
        3'b011,{{32{alu_temp_32[31]}},alu_temp_32},  //按符号位扩展 slliw sllw sraiw sraw
        3'b100,mul_temp_128[63:0],
        3'b101,mul_temp_128[127:64],
        3'b110,mul_temp,
        3'b111,{{32{mul_temp_32[31]}},mul_temp_32} 
    });


endmodule
