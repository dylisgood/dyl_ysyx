//operation
`timescale 1ns/1ps
module ysyx_22050854_alu(
    input clk,
    input rst,
    input EXEreg_valid,
    input [3:0]ALUctr,
    input [3:0]MULctr,
    input [2:0]ALUext,
    input [63:0]src1,
    input [63:0]src2,
    output alu_busy,
    output signed [63:0]alu_out 
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

    wire less;
    assign less = ALUctr == 4'b0010 ? ( ($signed(src1)) < ($signed(src2)) ? 1 : 0) : (src1 < src2 ? 1 : 0);

    wire op_mul_t;
    wire op_mul;
    wire mul_valid;
    wire mulw;
    wire [1:0]mul_signed;
    wire mul_doing;
    wire mul_ready;
    wire mul_out_valid;
    wire [63:0]mul_result_hi;
    wire [63:0]mul_result_lo;
    ysyx_22050854_MuxKey #(5,4,1) gen_op_mul (op_mul_t,MULctr,{
        4'b1001,1'b1, //mul
        4'b0001,1'b1,
        4'b0010,1'b1,
        4'b0011,1'b1,
        4'b1000,1'b1
    });
    assign op_mul = op_mul_t & EXEreg_valid;
    assign mul_valid = op_mul & !mul_doing & !mul_out_valid;
    assign mulw = ( MULctr == 4'b1000 ) ? 1'b1 : 1'b0;
    ysyx_22050854_MuxKey #(5,4,2) gen_mul_signed (mul_signed, MULctr, {
        4'b1001,2'b11, //mul
        4'b0001,2'b11,
        4'b0010,2'b10,
        4'b0011,2'b00,
        4'b1000,2'b11
    });
    ysyx_22050854_multiplier_1 shiftadd_nultiplier (
        .clk(clk),
        .rst(rst),
        .mul_valid(mul_valid), //1:input data valid
        .flush(1'b0),     //1:cancel multi
        .mulw(mulw),      //1:32 bit multi
        .mul_signed(mul_signed),  //2’b11（signed x signed）；2’b10（signed x unsigned）；2’b00（unsigned x unsigned）；
        .multiplicand(src1), //被乘数
        .multiplier(src2),   //乘数
        .mul_doing(mul_doing),
        .mul_ready(mul_ready),         //为高表示乘法器准备好，表示可以输入数据
        .out_valid(mul_out_valid),         //为高表示乘法器输出的结果有效
        .result_hi(mul_result_hi),
        .result_lo(mul_result_lo)
    );

    wire op_div;
    wire div_valid;
    wire divw;
    wire div_signed;
    wire div_ready;
    wire div_out_valid;
    wire div_doing;
    wire [63:0]div_out_quoitient;
    wire [63:0]div_out_remainder;
    wire div_t;
    ysyx_22050854_MuxKey #(8,4,1) gen_op_div (div_t,MULctr,{
        4'b0100,1'b1,
        4'b0101,1'b1,
        4'b0110,1'b1,
        4'b0111,1'b1,
        4'b1100,1'b1,
        4'b1101,1'b1,
        4'b1110,1'b1,
        4'b1111,1'b1
    });
    assign op_div = div_t & EXEreg_valid;
    assign div_valid = op_div & !div_doing & !div_out_valid; //只持续两个周期
    //assign div_valid = op_div;
    assign divw = MULctr[3]; //由MULctr第4位决定
    //assign divw= 1'b1;
    assign div_signed = ~MULctr[0];
    //assign div_signed = 1'b1;
    ysyx_22050854_divider_1 shift_divider_1 (
        .clk(clk),
        .rst(rst),
        .dividend(src1),  //被除数
        .divisor(src2),   //除数
        .div_valid(div_valid),       //为高表示输入的数据有效，如果没有新的除法输入，在除法被接受的下一个周期要置低
        .divw(divw),            //为高表示输入是32位除法
        .div_signed(div_signed),      //为高表示是有符号除法
        .flush(1'b0),           //为高表示除法无效
        .div_doing(div_doing),
        .div_ready(div_ready),      //为高表示除法器空闲，可以输入数据
        .out_valid(div_out_valid),      //为高表示除法器输出结果有效
        .quotient(div_out_quoitient), //商
        .remainder(div_out_remainder) //余数
    );

    assign alu_busy = ( op_mul && !mul_out_valid ) | ( op_div && !div_out_valid);

    wire [31:0]div_doing_32;
    assign div_doing_32 = {31'b0,div_doing};
    import "DPI-C" function void get_div_doing_value(int div_doing_32);
    always@(*) get_div_doing_value(div_doing_32);

    ysyx_22050854_MuxKey #(8,3,64) gen_alu_out (alu_out, ALUext, {
        3'b000,alu_temp,
        3'b001,{63'd0,less},
        3'b010,{{32{alu_temp[31]}},alu_temp[31:0]}, //先截断，然后按符号位扩展 addw addiw subw
        3'b011,{{32{alu_temp_32[31]}},alu_temp_32},  //按符号位扩展 slliw sllw sraiw sraw
        3'b100,mul_result_lo, //mul mulw
        3'b101,mul_result_hi,  //mulh
        3'b110,div_out_quoitient, //div divu divw divwu
        3'b111,div_out_remainder    //rem remu remwu remw
    });

endmodule
