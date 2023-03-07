module ysyx_22050854_pc(
    input rst,
    input clk,
    input [2:0]Branch,
    input zero,
    input less,
    input [63:0]src1,
    input [63:0]imm,
    output reg[31:0]pc
);
    wire [1:0]PCsrc;
    wire [31:0]PCsrc1,PCsrc2;
    reg [31:0]next_pc;
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
        1'b0,pc,
        1'b1,src1[31:0]
    });

    always@(posedge clk)begin
        if(rst)
            next_pc = 32'h80000000;
        else
            next_pc = PCsrc1 + PCsrc2;
    end 

    always@(*)begin
        if(rst)
            pc = 32'h80000000;
        else
            pc = next_pc;
    end

endmodule
