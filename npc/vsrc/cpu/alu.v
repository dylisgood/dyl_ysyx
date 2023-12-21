`define ysyx_22050854_USE_MULTIPLIER_1

module ysyx_22050854_alu(
    input clock,
    input reset,
    input EXEreg_valid,
    input [3:0]ALUctr,
    input [3:0]MULctr,
    input [2:0]ALUext,
    input [63:0]src1,
    input [63:0]src2,
    output alu_busy,
    output reg [63:0]alu_out 
);
    reg [31:0]alu_temp_32;
    always @(*)begin
        if(reset)
            alu_temp_32 = 32'b0;
        else begin
            case({EXEreg_valid,ALUctr})
                5'b10001: alu_temp_32 = src1[31:0] << src2[4:0]; //slliw sllw
                5'b10101: alu_temp_32 = src1[31:0] >> src2[4:0]; //srliw srlw
                5'b11101: alu_temp_32 = ($signed(src1[31:0])) >>> src2[4:0]; //sraiw sraw
                default: alu_temp_32 = 32'd0;
            endcase
        end
    end

    reg [63:0]alu_temp;
    always @(*)begin
        if(reset)
            alu_temp = 64'd0;
        else begin
            case({EXEreg_valid,ALUctr})
                5'b10000: alu_temp = src1 + src2;
                5'b10001: alu_temp = src1 << src2[5:0]; //sll,slli
                5'b10010: alu_temp = ($signed(src1)) - ($signed(src2));  //slt beq bne blt bge 
                5'b10011: alu_temp = 64'd0 + src2;                         //lui copy
                5'b10100: alu_temp = src1 ^ src2;
                5'b10101: alu_temp = src1 >> src2[5:0];  //srl srli
                5'b10110: alu_temp = src1 | src2;
                5'b10111: alu_temp = src1 & src2;
                5'b11000: alu_temp = src1 - src2;        //sub
                5'b11101: alu_temp = ($signed(src1)) >>> src2[5:0];    //srai
                5'b11010: alu_temp = src1 - src2;  //sltu bltu bgeu sltiu
                default: alu_temp = 64'd0;
            endcase
        end
    end

    wire less;
    assign less = ALUctr == 4'b0010 ? ( ($signed(src1)) < ($signed(src2)) ? 1 : 0) : (src1 < src2 ? 1 : 0);

    wire op_mul_t;
    wire op_mul;
    wire mul_valid;
    wire mulw;
    reg [1:0]mul_signed;
    wire mul_doing;
    wire mul_ready;
    wire mul_out_valid;
    wire [63:0]mul_result_hi;
    wire [63:0]mul_result_lo;
    assign op_mul_t = (MULctr == 4'b1001) || (MULctr == 4'b0001) || (MULctr == 4'b0010) || (MULctr == 4'b0011) || (MULctr == 4'b1000);
    assign op_mul = op_mul_t & EXEreg_valid;
    assign mul_valid = op_mul & !mul_doing & !mul_out_valid & mul_ready;
    assign mulw = ( MULctr == 4'b1000 ) ? 1'b1 : 1'b0;
    always @(*) begin
        if(reset)
            mul_signed = 2'b00;
        else begin
            case(MULctr)
                4'b1001: mul_signed =  2'b11; //mul
                4'b0001: mul_signed =  2'b11;
                4'b0010: mul_signed =  2'b10;
                4'b0011: mul_signed =  2'b00;
                4'b1000: mul_signed =  2'b11;
                default: mul_signed = 2'b00;
            endcase
        end
    end
`ifdef ysyx_22050854_USE_MULTIPLIER_1
    ysyx_22050854_multiplier_v1 shiftadd_multiplier (
        .clock(clock),
        .reset(reset),
        .mul_valid(mul_valid), //1:input data valid
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
`else
    ysyx_22050854_multiplier_v2 use_multiplier_2 (
        .clock(clock),
        .reset(reset),
        .mul_valid(mul_valid), //1:input data valid
        .mulw(mulw),      //1:32 bit multi
        .mul_signed(mul_signed),  //2’b11（signed x signed）；2’b10（signed x unsigned）；2’b00（unsigned x unsigned）；
        .multiplicand(src1), //被乘数
        .multiplier(src2),   //乘数
        .mul_doing(mul_doing),
        .mul_ready(mul_ready),             //为高表示乘法器准备好，表示可以输入数据
        .out_valid(mul_out_valid),         //为高表示乘法器输出的结果有效
        .result_hi(mul_result_hi),
        .result_lo(mul_result_lo)
    );
`endif

    wire op_div;
    wire div_valid;
    wire divw;
    wire div_signed;
    wire div_ready;
    wire div_out_valid;
    wire div_doing;
    wire [63:0]div_out_quoitient;
    wire [63:0]div_out_remainder;
    reg div_t;
    always @(*) begin
        if(reset)
             div_t = 1'b0;
        else begin
            case(MULctr)
                4'b0100: div_t = 1'b1;
                4'b0101: div_t = 1'b1;
                4'b0110: div_t = 1'b1;
                4'b0111: div_t = 1'b1;
                4'b1100: div_t = 1'b1;
                4'b1101: div_t = 1'b1;
                4'b1110: div_t = 1'b1;
                4'b1111: div_t = 1'b1;
                default: div_t = 1'b0;
            endcase
        end
    end
    assign op_div = div_t & EXEreg_valid;
    assign div_valid = op_div & !div_doing & !div_out_valid & div_ready; //只持续两个周期
    assign divw = MULctr[3]; //由MULctr第4位决定
    assign div_signed = ~MULctr[0];
    ysyx_22050854_divider_1 shift_divider_1 (
        .clock(clock),
        .reset(reset),
        .dividend(src1),                //被除数
        .divisor(src2),                 //除数
        .div_valid(div_valid),          //为高表示输入的数据有效，如果没有新的除法输入，在除法被接受的下一个周期要置低
        .divw(divw),                    //为高表示输入是32位除法
        .div_signed(div_signed),        //为高表示是有符号除法
        .div_doing(div_doing),
        .div_ready(div_ready),          //为高表示除法器空闲，可以输入数据
        .out_valid(div_out_valid),      //为高表示除法器输出结果有效
        .quotient(div_out_quoitient),   //商
        .remainder(div_out_remainder)   //余数
    );

    assign alu_busy = ( op_mul && !mul_out_valid ) | ( op_div && !div_out_valid );

    always @(*) begin
        if(reset)
            alu_out = 64'b0;
        else begin
            case({EXEreg_valid,ALUext})
                4'b1000: alu_out =  alu_temp;
                4'b1001: alu_out =  {63'd0,less};
                4'b1010: alu_out =  {{32{alu_temp[31]}},alu_temp[31:0]};  //先截断，然后按符号位扩展 addw addiw subw
                4'b1011: alu_out =  {{32{alu_temp_32[31]}},alu_temp_32};  //按符号位扩展 slliw sllw sraiw sraw
                4'b1100: alu_out =  mul_result_lo; //mul mulw
                4'b1101: alu_out =  mul_result_hi;  //mulh
                4'b1110: alu_out =  div_out_quoitient; //div divu divw divwu
                4'b1111: alu_out =  div_out_remainder;    //rem remu remwu remw
                default: alu_out =  64'd0;
            endcase
        end
    end

endmodule

