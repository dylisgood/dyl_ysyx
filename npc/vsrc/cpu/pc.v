
module ysyx_22050854_pc(
    input rst,
    input clk,
    input Data_Conflict,
    input suspend,
    input [2:0]Branch,
    input No_branch,
    input is_csr_pc,
    input [31:0]csr_pc,
    input unsigned_compare,
    input [63:0]alu_src1,
    input [63:0]alu_src2,
    input [63:0]src1,
    input [63:0]imm,
    output jump,
    output reg[31:0]pc,
    output reg[31:0]next_pc
);
    wire zero;
    wire less;
    assign zero = ( ( $signed(alu_src1) ) - ( $signed(alu_src2) ) == 0 ) ? 1'b1 : 1'b0;
    assign less = unsigned_compare ? ( alu_src1 < alu_src2 ? 1'b1 : 1'b0 ) : ( ($signed(alu_src1)) < ($signed(alu_src2)) ? 1'b1 : 1'b0 );

    reg [2:0]PCsrc;
    reg [31:0]PCsrc1,PCsrc2;
    //default----00---pc + 4 但是这样的话 每个上升沿都会使pc+4
    //于是 我想再译出一位控制信号，当这个信号为1 时才有效
    //PCsrc[2]用于指示这是一个跳转指令,并且进行了跳转
    ysyx_22050854_MuxKeyWithDefault #(20,5,3) gen_PC3src (PCsrc,{Branch,zero,less},3'b000,{
        5'b00100,3'b110, //jal
        5'b00101,3'b110, //jal
        5'b00110,3'b110, //jal
        5'b00111,3'b110, //jal
        5'b01000,3'b111, //jalr
        5'b01001,3'b111, //jalr
        5'b01010,3'b111, //jalr
        5'b01011,3'b111, //jalr
        5'b10010,3'b110, //equal
        5'b10011,3'b110, //equal          //beq 但是不相等的默认为00 ,就是不跳转
        5'b10100,3'b110, //not equal
        5'b10101,3'b110, //not equal
        5'b11001,3'b110, //less           //blt bltu
        5'b11011,3'b110, //less
        5'b11000,3'b000, //not less 
        5'b11010,3'b000, //not less
        5'b11100,3'b110, //greater bgeu less = 0   //bge bgeu
        5'b11110,3'b110, //greater bgeu
        5'b11101,3'b000, //not greater bgeu less = 1
        5'b11111,3'b000  //not greater bgeu
    });
    //如果存在数据冲突且需要阻塞，那这个确定跳转的计算并不准确
    //ecall/mret的next_pc是从CSR中取出的，我的逻辑是译码过后就写CSR，CSR寄存器按理说不会出现阻塞的情况
    assign jump = ( PCsrc[2] & (~Data_Conflict) ) | is_csr_pc;

    //00---pc + 4  10---pc + imm   
    ysyx_22050854_MuxKey #(2,1,32) gen_PCsrc1 (PCsrc1,PCsrc[1],{
        1'b0,32'd4,
        1'b1,imm[31:0]
    });

    ysyx_22050854_MuxKey #(2,1,32) gen_PCsrc2 (PCsrc2,PCsrc[0],{
        1'b0,pc,
        1'b1,src1[31:0]
    });

    always@(*)begin
        if(rst)                         //复位
            next_pc = 32'h80000000;
        else if( (suspend == 1'b1) )
            next_pc = pc;
        else if( (is_csr_pc == 1'b1) )     //ecall mret
            next_pc = csr_pc;
        else if( (Branch != 3'b000) )       //跳转指令
            next_pc = PCsrc1 + PCsrc2;
        else if( (No_branch == 1'b1) )      //非跳转指令 其实也包括ecall mret 但这里我利用先判断前者
            next_pc = pc + 32'd4;
        else                           //未定义指令
            next_pc = pc + 32'd0;
    end

    always@(posedge clk)begin
        if(rst)
            pc <= 32'h80000000;
        else if(~Data_Conflict)
            pc <= next_pc;
    end

/*     import "DPI-C" function void get_pc_value(int pc);
    always@(*) get_pc_value(pc); */

endmodule
