
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
    //default----00---pc + 4
    ysyx_22050854_MuxKey #(16,5,2) gen_PC3src (PCsrc,{Branch,zero,less},{
        5'b00100,2'b10, //jal
        5'b00101,2'b10, //jal
        5'b00110,2'b10, //jal
        5'b00111,2'b10, //jal
        5'b01000,2'b11, //jalr
        5'b01001,2'b11, //jalr
        5'b01010,2'b11, //jalr
        5'b01011,2'b11, //jalr
        5'b10010,2'b10, //equal
        5'b10011,2'b10, //equal
        5'b10100,2'b10, //not equal
        5'b10101,2'b10, //not equal
        5'b11001,2'b10, //less
        5'b11011,2'b10, //less
        5'b11100,2'b10, //greater
        5'b11110,2'b10  //greater
    });

    //00---pc+4  10---pc+imm   
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
    import "DPI-C" function void get_pc_value(int pc);
    always@(*) get_pc_value(pc);

endmodule
