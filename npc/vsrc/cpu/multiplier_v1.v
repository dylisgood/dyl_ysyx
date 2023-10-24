/*
模块功能：
    根据RISCV指令集规则
    需要实现32 x 32 的有符号乘法   以及64 x 64 的signed x signed / signed x unsigned / unsigned x unsigned
    实现 32x32 / 64x64 位信号的有符号或无符号的相乘
    采用移位加的方法实现
    9.13优化 结束运算的另一个标志是乘数为0
*/


module ysyx_22050854_multiplier_v1(
    input clock,
    input reset,
    input mul_valid, //1:input data valid
    input flush,     //1:cancel multi
    input mulw,      //1:32 bit multi
    input [1:0]mul_signed,  //2’b11（signed x signed）；2’b10（signed x unsigned）；2’b00（unsigned x unsigned）；
    input [63:0]multiplicand, //被乘数
    input [63:0]multiplier,   //乘数
    output mul_doing,
    output mul_ready,         //为高表示乘法器准备好，表示可以输入数据
    output out_valid,         //为高表示乘法器输出的结果有效
    output [63:0]result_hi,
    output [63:0]result_lo
);

// 32 * 32
reg [63:0]multiplicand_temp;
reg [63:0]multiplier_temp;
reg mul32ss_go;  //32 x 32 符号相乘准备好标志  直到运算结束才置0
reg mul_ready_t;
always @(posedge clock)begin
    if(reset)begin
        mul32ss_go <= 1'b0;
        mul_ready_t <= 1'b1;
        multiplicand_temp <= 64'b0;
        multiplier_temp <= 64'b0;
    end
    else if(mul_valid & mulw & (mul_signed == 2'b11) & mul_ready_t)begin // 32位 有符号乘法
        multiplicand_temp <= { {32{multiplicand[31]}} , multiplicand[31:0] };
        multiplier_temp <= multiplier;
        mul32ss_go <= 1'b1;
        mul_ready_t <= 1'b0;
    end
    else if ( ((mul_count >= 7'd31) | ( multiplier_temp == 64'b0)) & mul32ss_go )begin  //当乘数为0或计数32次后 32 x 32运算结束 
        multiplicand_temp <= 64'b0;
        multiplier_temp <= 64'b0;
        mul32ss_go <= 1'b0;
        mul_ready_t <= 1'b1;
    end
end

reg [6:0]mul_count; //用于给移位计数 需要移位32次 采用6位数 大一位
always @(posedge clock)begin
    if(reset)begin
        mul_count <= 7'd0;
    end
    else if( mul32ss_go & ((mul_count >= 7'd31) | ( multiplier_temp == 64'b0)) )
        mul_count <= 7'd0;
    else if( mul64_go & ( (mul_count >= 7'd63) |  multiplier_temp == 64'b0) )
        mul_count <= 7'd0;
    else if( mul32ss_go | mul64_go )begin //计数的条件是乘法控制字有效
        mul_count <= mul_count + 7'b1;
    end
    else 
        mul_count <= 7'd0;
end

reg [63:0]mul32_result_temp; //存放32 x 32 位的乘积
//启动 32 x 32 位无符号数的运算
always @(posedge clock)begin
    if(reset)begin
        mul32_result_temp <= 64'b0;
    end
    else if(mul32ss_go & (mul_count < 7'd32))begin
        if( multiplier_temp[0] & ( mul_count < 7'd31 ) )begin //如果乘数的最低位为1
            mul32_result_temp <= mul32_result_temp + multiplicand_temp;
        end
        else if(multiplier_temp[0] & ( mul_count == 7'd31 ))begin //对于补码乘法，最后一次被累加的乘积需要使用补码减法来操作
            mul32_result_temp <= mul32_result_temp - multiplicand_temp;
        end
        multiplicand_temp <= ( multiplicand_temp << 1 ); //被乘数左移一位
        multiplier_temp <= ( multiplier_temp >> 1 ); //乘数右移一位
    end
    else begin
        mul32_result_temp <= 64'b0;
    end
end

reg mul32_over;
always @(posedge clock)begin
    if(reset)
        mul32_over <= 1'b0;
    else if( mul32ss_go & ((mul_count >= 7'd31) | ( multiplier_temp == 64'b0)) )
        mul32_over <= 1'b1;
    else
        mul32_over <= 1'b0;
end

//64 * 64 
reg [127:0]multiplicand_temp_128; //64位运算的被乘数寄存器
reg mul64_go;
reg mul64_multiplier_sign;
always @(posedge clock)begin
    if(reset)begin
        multiplicand_temp_128 <= 128'b0;
        mul64_go <= 1'b0;
        mul64_multiplier_sign <= 1'b0;
    end
    else if( mul_valid & (~mulw) &  mul_ready_t)begin
        mul_ready_t <= 1'b0;
        mul64_go <= 1'b1;
        mul64_multiplier_sign <= mul_signed[0]; //乘数是否有符号取决于mul_signed[0]
        multiplier_temp <= multiplier;
        if( mul_signed[1] )                   //如果被乘数是有符号相乘
            multiplicand_temp_128 <= { {64{multiplicand[63]}} , multiplicand };
        else
            multiplicand_temp_128 <= { 64'b0,multiplicand };
    end
    else if( ( (mul_count >= 7'd63) |  multiplier_temp == 64'b0) & mul64_go) begin  // 64 x 64 运算完成
        mul64_go <= 1'b0;
        mul_ready_t <= 1'b1;
        mul64_multiplier_sign <= 1'b0;
        multiplier_temp <= 64'd0;
        multiplicand_temp_128 <= 128'd0;
    end
end

reg [127:0]mul64_result_temp;
always @(posedge clock)begin
    if(reset)
        mul64_result_temp <= 128'b0;
    else if( mul64_go & ( mul_count < 7'd64) )begin
        if( multiplier_temp[0] & ( mul_count == 7'd63 ) & mul64_multiplier_sign )begin //对于补码乘法，最后一次被累加的乘积需要使用补码减法来操作
            mul64_result_temp <= mul64_result_temp - multiplicand_temp_128;
        end
        else if( multiplier_temp[0] )begin   //如果乘数的最低位为1
            mul64_result_temp <= mul64_result_temp + multiplicand_temp_128;
        end
        multiplicand_temp_128 <= ( multiplicand_temp_128 << 1 ); //被乘数左移一位
        multiplier_temp <= ( multiplier_temp >> 1 ); //乘数右移一位
    end
    else
        mul64_result_temp <= 128'b0;
end

reg mul64_over;
always @(posedge clock)begin
    if(reset)
        mul64_over <= 1'b0;
    else if(mul64_go & ( (mul_count >= 7'd63) |  multiplier_temp == 64'b0) )
        mul64_over <= 1'b1;
    else 
        mul64_over <= 1'b0;
end

assign mul_ready = mul_ready_t;
assign out_valid = mul32_over | mul64_over;  //只持续一周期
assign result_lo = out_valid ? ( mul32_over ? { {32{mul32_result_temp[31]}},mul32_result_temp[31:0] } : mul64_result_temp[63:0] ): 64'd0; //只持续一周期 用低64位表示输出
assign result_hi = mul64_over ? mul64_result_temp[127:64] : 64'b0;
assign mul_doing = mul32ss_go | mul64_go;

endmodule
