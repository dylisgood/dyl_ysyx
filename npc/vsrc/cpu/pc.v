
module ysyx_22050854_pc(
    input rst,
    input clk,
    input [2:0]Branch,
    input No_branch,
    input zero,
    input less,
    input [63:0]src1,
    input [63:0]imm,
    output reg[31:0]pc,
    output reg[31:0]next_pc
);
    reg [2:0]PCsrc;
    reg [31:0]PCsrc1,PCsrc2;
    //reg [31:0]next_pc;
    //default----00---pc + 4 但是这样的话 每个上升沿都会使pc+4
    //于是 我想再译出一位控制信号，当这个信号为1 时才有效
    //PCsrc[2]用于指示这是一个跳转指令
    ysyx_22050854_MuxKeyWithDefault #(16,5,3) gen_PC3src (PCsrc,{Branch,zero,less},3'b000,{
        5'b00100,3'b110, //jal
        5'b00101,3'b110, //jal
        5'b00110,3'b110, //jal
        5'b00111,3'b110, //jal
        5'b01000,3'b111, //jalr
        5'b01001,3'b111, //jalr
        5'b01010,3'b111, //jalr
        5'b01011,3'b111, //jalr
        5'b10010,3'b110, //equal
        5'b10011,3'b110, //equal
        5'b10100,3'b110, //not equal
        5'b10101,3'b110, //not equal
        5'b11001,3'b110, //less
        5'b11011,3'b110, //less
        5'b11100,3'b110, //greater
        5'b11110,3'b110  //greater
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
            next_pc <= 32'h80000000;
        else if(Branch!=3'b000)       //跳转指令
            next_pc <= PCsrc1 + PCsrc2;
        else if(No_branch==1'b1)      //非跳转指令
            next_pc <= pc + 32'd4;
        else                           //非法指令
            next_pc <= pc + 32'd0;
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
