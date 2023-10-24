/*
模块功能：
    根据RISCV指令集规则
    需要实现32 x 32 的有符号乘法   以及64 x 64 的signed x signed / signed x unsigned / unsigned x unsigned
    实现 32x32 / 64x64 位信号的有符号或无符号的相乘
    采用Booth 二位乘的方法实现
*/

module ysyx_22050854_multiplier_2(
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
// 由于32位乘法只有带符号的乘法 所以我没有再给他扩展一位 乘数寄存器复用64位的
reg [63:0]multiplicand_temp; 
reg mul32ss_go;  //32 x 32 符号相乘准备好标志  直到运算结束才置0
reg mul_ready_t;
always @(posedge clock)begin
    if(reset)begin
        mul32ss_go <= 1'b0;
        mul_ready_t <= 1'b1;
        multiplicand_temp <= 64'b0;
    end
    else if( mul_valid & mulw & (mul_signed == 2'b11) & mul_ready_t )begin // 32位 有符号乘法
        multiplicand_temp <= { {32{multiplicand[31]}} , multiplicand[31:0] };
        multiplier_temp_128[32:1] <= multiplier[31:0];      //第 0 位存的是y-1
        mul32ss_go <= 1'b1;
        mul_ready_t <= 1'b0;
    end
    else if( mul32ss_go & ( multiplier_temp_128 == 67'b0  | ( mul_count >= 7'd15 ) ) )begin  //32 x 32运算结束
        multiplicand_temp <= 64'b0;
        multiplier_temp_128 <= 67'b0;
        mul32ss_go <= 1'b0;
        mul_ready_t <= 1'b1;
    end
end

reg [6:0]mul_count; //用于给移位计数 需要移位32次 采用6位数 大一位
always @(posedge clock)begin
    if(reset)begin
        mul_count <= 7'd0;
    end
    else if( mul32ss_go & ( ( multiplier_temp_128 == 67'b0) | ( mul_count >= 7'd15 )) )
        mul_count <= 7'd0;
    else if( mul64_go & ( multiplier_temp_128 == 67'b0 | mul_count >= 7'd32) )
        mul_count <= 7'd0;
    else if( mul32ss_go | mul64_go )begin //计数的条件是乘法控制字有效
        mul_count <= mul_count + 7'b1;
    end
    else
        mul_count <= 7'd0;
end

//Booth信号生成模块
wire [2:0]src;
wire y_add,y,y_sub;
wire sel_negative,sel_double_negative,sel_positive,sel_double_positive;
assign src = multiplier_temp_128[2:0];
assign {y_add,y,y_sub} = src;

assign sel_negative =  y_add & (y & ~y_sub | ~y & y_sub);
assign sel_positive = ~y_add & (y & ~y_sub | ~y & y_sub);
assign sel_double_negative =  y_add & ~y & ~y_sub;
assign sel_double_positive = ~y_add &  y &  y_sub;

// 求 32 * 32 位的部分积
wire [63:0]x;
assign x = multiplicand_temp;
reg [63:0]p;
always @(*)begin
    if(reset)
        p = 64'd0;
    else begin
        p[0] = ~( ~(sel_negative & ~x[0]) & ~(sel_double_negative & 1'b1) & ~(sel_positive & x[0] ) & ~(sel_double_positive & 1'b0) );
        for (int i = 1; i < 64; i = i + 1)begin
            p[i] = ~( ~(sel_negative & ~x[i]) & ~(sel_double_negative & ~x[i-1]) & ~(sel_positive & x[i] ) & ~(sel_double_positive & x[i-1]) );
        end
    end
end
wire [63:0]bufenji;
wire [63:0]c;
assign c = { 63'b0,(sel_negative | sel_double_negative) };
assign bufenji = p + c;

// 求65 * 65 位的部分积
wire [131:0]x_64;
assign x_64 = multiplicand_temp_128;
reg [131:0]p64;
always @(*)begin
    if(reset)
        p64 = 132'b0;
    else begin
        p64[0] = ~( ~(sel_negative & ~x_64[0]) & ~(sel_double_negative & 1'b1) & ~(sel_positive & x_64[0] ) & ~(sel_double_positive & 1'b0) );
        for (int i = 1; i < 132; i = i + 1)begin
            p64[i] = ~( ~(sel_negative & ~x_64[i]) & ~(sel_double_negative & ~x_64[i-1]) & ~(sel_positive & x_64[i] ) & ~(sel_double_positive & x_64[i-1]) );
        end
    end
end
wire [131:0]bufenji_64;
wire [131:0]c_64;
assign c_64 = { 131'b0, (sel_negative | sel_double_negative) };
assign bufenji_64 = p64 + c_64;

//启动 32 x 32 位符号数的运算
reg [63:0]mul32_result_temp; //存放32 x 32 位的乘积
always @(posedge clock)begin
    if(reset)begin
        mul32_result_temp <= 64'b0;
    end
    else if( mul32ss_go & ( multiplier_temp_128 != 67'b0 | ( mul_count < 7'd16 ) ) )begin  //总共移位16次就够了--->现在改为了由乘数是否为0判断
        mul32_result_temp <= mul32_result_temp + bufenji;
        multiplicand_temp <= ( multiplicand_temp << 2 ); //被乘数左移2位
        multiplier_temp_128 <= ( multiplier_temp_128 >> 2 ); //乘数右移2位
    end
    else if(mul32_over) begin
        mul32_result_temp <= 64'b0;
    end
end

reg mul32_over;
always @(posedge clock)begin
    if(reset)
        mul32_over <= 1'b0;
    else if( mul32ss_go & ( multiplier_temp_128 == 67'b0 | mul_count >= 7'd15) )
        mul32_over <= 1'b1;
    else
        mul32_over <= 1'b0;
end

//64 * 64
// 握手 存数
reg [131:0]multiplicand_temp_128; //64位运算的被乘数寄存器
reg [66:0]multiplier_temp_128;     //y-1 一位 ， 为了支持无符号运算 最高位再加一位 加一位好像不够
reg mul64_go;
always @(posedge clock)begin
    if(reset)begin
        multiplicand_temp_128 <= 132'b0;
        multiplier_temp_128 <= 67'b0;
        mul64_go <= 1'b0;
    end
    else if( mul_valid & (~mulw) &  mul_ready_t)begin    //根据是否有符号号位来存数
        mul_ready_t <= 1'b0;
        mul64_go <= 1'b1;
        if( mul_signed[1] )  multiplicand_temp_128 <= { {68{multiplicand[63]}} , multiplicand };//如果被乘数是有符号相乘
        else multiplicand_temp_128 <= { 68'b0,multiplicand };
        if( mul_signed[0] )  multiplier_temp_128[66:0] <= {multiplier[63],multiplier[63],multiplier,1'b0};  //如果乘数是有符号相乘  //扩展为65位乘法，最低位存放的是y-1 为0
        else multiplier_temp_128[66:0] <= {2'b0,multiplier,1'b0};
    end
    else if( mul64_go & ( multiplier_temp_128 == 67'b0 | mul_count >= 7'd32) ) begin  // 65 x 65 运算完成 需要33个部分积
        mul64_go <= 1'b0;
        mul_ready_t <= 1'b1;
        multiplier_temp_128 <= 67'd0;
        multiplicand_temp_128 <= 132'd0;
    end
end

// 65 * 65 运算
reg [131:0]mul64_result_temp;
always @(posedge clock)begin
    if(reset)
        mul64_result_temp <= 132'b0;
    else if( mul64_go & ( multiplier_temp_128 != 67'b0 |  mul_count < 7'd33 ) )begin  //0-32 共有34个部分积 但是只需要加33次
        mul64_result_temp <= mul64_result_temp + bufenji_64;
        multiplicand_temp_128 <= ( multiplicand_temp_128 << 2 ); //被乘数左移2位
        multiplier_temp_128 <= ( multiplier_temp_128 >> 2 ); //乘数右移2位
    end
    else if(mul64_over)
        mul64_result_temp <= 132'b0;
end

reg mul64_over;
always @(posedge clock)begin
    if(reset)
        mul64_over <= 1'b0;
    else if( mul64_go & ( multiplier_temp_128 == 67'b0 | mul_count >= 7'd32) )
        mul64_over <= 1'b1;
    else 
        mul64_over <= 1'b0;
end

assign mul_ready = mul_ready_t;
assign out_valid = mul32_over | mul64_over;  //只持续一周期
assign result_lo = out_valid ? ( mul32_over ? { {32{mul32_result_temp[31]}},mul32_result_temp[31:0] } : mul64_result_temp[63:0] ): 64'd0; //只持续一周期 用低64位表示输出
assign result_hi = mul64_over ? {mul64_result_temp[131],mul64_result_temp[126:64]} : 64'b0;  //这个不确定
assign mul_doing = mul32ss_go | mul64_go;

endmodule
