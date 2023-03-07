//operation
`timescale 1ns/1ps
module ysyx_22050854_alu(
    input [3:0]ALUctr,
    input [63:0]src1,
    input [63:0]src2,
    output reg[63:0]alu_out,
    output less,
    output zero 
);

    ysyx_22050854_MuxKeyWithDefault #(3,4,64) i0 (alu_out,ALUctr,64'd0,{
        4'b0000,src1 + src2,
        4'b0001,src1 << src2[4:0],
        4'b0010,src1 - src2
    });

    assign zero = alu_out == 64'd0 ? 1 : 0;
    assign less = 0;
    

endmodule
