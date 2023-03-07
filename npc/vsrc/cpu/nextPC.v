`timescale 1ns/1ps
module ysyx_22050854_nextPC(
    input [2:0]Branch,
    input zero,
    input less,
    input [31:0]PC,
    input [63:0]src1,
    input [63:0]imm,
    output reg[31:0]next_pc
);
    wire [1:0]PCsrc;
    wire [31:0]PCsrc1,PCsrc2;
/*
    ysyx_22050854_MuxKey #(3,3,2) gen_PC1src (PCsrc,Branch,{
        000,00,
        001,10,
        010,11
    });
    ysyx_22050854_MuxKey #(4,4,2) gen_PC2src (PCsrc,{Branch,zero},{
        1000,00,
        1001,10,
        1011,10,
        1011,00
    });
    */
    ysyx_22050854_MuxKey #(4,4,2) gen_PC3src (PCsrc,{Branch,less},{
        4'b0000,2'b00,
        4'b1100,2'b00,
        4'b1101,2'b10,
        4'b1111,2'b00
    });

    ysyx_22050854_MuxKey #(2,1,32) gen_PCsrc1 (PCsrc1,PCsrc[1],{
        1'b0,32'd4,
        1'b1,imm[31:0]
    });

    ysyx_22050854_MuxKey #(2,1,32) gen_PCsrc2 (PCsrc2,PCsrc[0],{
        1'b0,PC,
        1'b1,src1[31:0]
    });

    always@(*)begin
        next_pc = PCsrc1 + PCsrc2;
    end

endmodule

