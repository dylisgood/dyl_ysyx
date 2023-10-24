/*
模块功能：
    根据RISCV指令集规则
    需要实现32 x 32 的有符号乘法   以及64 x 64 的signed x signed / signed x unsigned / unsigned x unsigned
    实现 32x32 / 64x64 位信号的有符号或无符号的相乘
    采用 Booth 二位乘 + 华莱士树 的方法实现
    多周期
*/

module ysyx_22050854_multiplier_v2(
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
reg REG0_valid;
reg REG0_mul32;
reg [63:0]REG0_multiplicand_32;
reg [131:0]REG0_multiplicand_64; //64位运算的被乘数寄存器
reg [66:0]REG0_multiplier;     //y-1 一位 ， 为了支持无符号运算 最高位再加一位 加一位好像不够 
reg mul_ready_t;
always @(posedge clock)begin
    if(reset)begin
        REG0_valid <= 1'b0;
        REG0_mul32 <= 1'b0;
        REG0_multiplicand_32 <= 64'b0;
        REG0_multiplicand_64 <= 132'b0;
        REG0_multiplier <= 67'b0;
    end
    else if( mul_valid & mulw & (mul_signed == 2'b11) & mul_ready_t )begin // 32位 有符号乘法
        REG0_multiplicand_32 <= { {32{multiplicand[31]}} , multiplicand[31:0] };
        REG0_multiplier[32:1] <= multiplier[31:0];      //第 0 位存的是y-1
        REG0_valid <= 1'b1;
        REG0_mul32 <= 1'b1;
        mul_ready_t <= 1'b0;
    end
    else if( mul_valid & (~mulw) &  mul_ready_t )begin    //根据是否有符号号位来存数
        mul_ready_t <= 1'b0;
        REG0_valid <= 1'b1;
        REG0_mul32 <= 1'b0;
        if( mul_signed[1] )  REG0_multiplicand_64 <= { {68{multiplicand[63]}} , multiplicand };//如果被乘数是有符号相乘
        else REG0_multiplicand_64 <= { 68'b0,multiplicand };
        if( mul_signed[0] )  REG0_multiplier[66:0] <= {multiplier[63],multiplier[63],multiplier,1'b0};  //如果乘数是有符号相乘  //扩展为65位乘法，最低位存放的是y-1 为0
        else REG0_multiplier[66:0] <= {2'b0,multiplier,1'b0};
    end
    else begin
        REG0_valid <= 1'b0;  
        REG0_multiplicand_32 <= 64'b0;
        REG0_multiplicand_64 <= 132'b0;
        REG0_multiplier <= 67'b0;
    end
end
//由于目前只是改成多周期的，暂不考虑流水，所以ready信号从取到操作数时无效，到运算完成后再恢复有效
always @(posedge clock)begin
    if(reset) mul_ready_t <= 1'b1;
    else if(REG3_valid) mul_ready_t <= 1'b1; 
end

// 求 32 * 32 位的部分积 16个64位的部分积
wire [15:0]c32;
wire [63:0]bufenji32[15:0];
genvar j;
generate
    for(j = 0; j < 16; j++)begin:bufenji_instances
        ysyx_22050854_genPartji32 Partji_gen32 (
            .src(REG0_multiplier[ (j << 1) + 2: ( j << 1 )]),  //y-1 y0 y1
            .x(REG0_multiplicand_32 << (j << 1)),
            .p(bufenji32[j]),
            .c(c32[j])
        );
    end
endgenerate

//switch 16 * 64bits ---> 64 * 16bits
wire [15:0] wallce16bits_input [63:0]; // 64个16位的输出数据
ysyx_22050854_switch32 init_switch (
    .input_data(bufenji32), // 16个64位的输入数据
    .output_data(wallce16bits_input) // 64个16位的输出数据
);

// 求66 * 66 位的部分积  共33个 132位的部分积 以及33位的进位
wire [131:0]bufenji_64[32:0];
wire [32:0]c64;
genvar x;
generate
    for(x = 0; x < 33; x = x + 1)begin: bufenji64_instances
        ysyx_22050854_genPartji64 Partji_gen64 (
            .src(REG0_multiplier[((x << 1) + 2): (x << 1)]),
            .x(REG0_multiplicand_64 << ( x << 1)),
            .p(bufenji_64[x]),
            .c(c64[x])
        );
    end
endgenerate

wire [32:0] wallce33bits_input[131:0];
ysyx_22050854_swtich64 switch64_inst(
    .input_data(bufenji_64),
    .output_data(wallce33bits_input)   
);

///////////////////////////////// 华莱士数运算加法器操作数 ///////////////////////////////////////////////////////
reg REG1_valid;
reg REG1_mul32;
reg [15:0] REG1_WLCinput32 [63:0];
reg [32:0] REG1_WLCinput64 [131:0];
reg [15:0]REG1_c32;
reg [32:0]REG1_c64;
ysyx_22050854_Reg #(1,1'b0) REG1_gen0 (clock, reset, REG0_valid, REG1_valid, 1'b1);
ysyx_22050854_Reg #(1,1'b0) REG1_gen1 (clock, reset, REG0_mul32, REG1_mul32, 1'b1);
ysyx_22050854_Reg #(16,16'b0) REG1_gen2 (clock, reset, c32, REG1_c32, 1'b1);
ysyx_22050854_Reg #(33,33'b0) REG1_gen3 (clock, reset, c64, REG1_c64, 1'b1);
genvar k,l;
always @(posedge clock)begin
    if(reset)begin
/*         for(k = 0; k < 64; k = k + 1)begin
            REG1_WLCinput32[k] <= 16'b0;
        end
        for(l = 0; l < 132; l = l + 1)begin
            REG1_WLCinput64[l] <= 33'b0;
        end */
    end
    else if(REG0_valid)begin
        REG1_WLCinput32 <= wallce16bits_input;
        REG1_WLCinput64 <= wallce33bits_input;
    end
end


//用16个数相加的1位华莱士数进行运算
wire [13:0]cout_group[63:0];
wire [63:0]wallce_cout,wallce_s;
ysyx_22050854_walloc_16bits wallce16bits_0 (
    .src_in(REG1_WLCinput32[0]), 
    .cin(REG1_c32[13:0]), //来自右边华莱士树的进位输入，最右边的华莱士树的 cin 是来自 switch 模块
    .cout_group(cout_group[0]), //输入到左边的华莱士树的进位输出，最左边的华莱士树的忽略即可
    .cout(wallce_cout[0]),
    .s(wallce_s[0])     //输出到加法器的 src1,输出到加法器的 src2
);

genvar i;
generate
    for (i = 1; i < 64; i = i + 1) begin : multi_instances
        ysyx_22050854_walloc_16bits multiplier_inst (
            .src_in(REG1_WLCinput32[i]), 
            .cin(cout_group[i-1]), 
            .cout_group(cout_group[i]), 
            .cout(wallce_cout[i]),
            .s(wallce_s[i])     
        );
    end
endgenerate

//用33个数相加的1位华莱士数进行运算
wire [30:0]cout64_group[131:0];
wire [131:0]wallce64_cout,wallce64_s;
ysyx_22050854_walloc_33bits wallce33bits_0 (
    .src_in(REG1_WLCinput64[0]), 
    .cin(REG1_c64[30:0]), //来自右边华莱士树的进位输入，最右边的华莱士树的 cin 是来自 switch 模块
    .cout_group(cout64_group[0]), //输入到左边的华莱士树的进位输出，最左边的华莱士树的忽略即可
    .cout(wallce64_cout[0]),
    .s(wallce64_s[0])     //输出到加法器的 src1,输出到加法器的 src2
);

genvar y;
generate
    for (y = 1; y < 132; y = y + 1) begin : multi64_instances
        ysyx_22050854_walloc_33bits multiplier64_inst (
            .src_in(REG1_WLCinput64[y]), 
            .cin(cout64_group[y-1]), 
            .cout_group(cout64_group[y]), 
            .cout(wallce64_cout[y]),
            .s(wallce64_s[y])     
        );
    end
endgenerate

wire [63:0]mul32_src1;
assign mul32_src1 = {wallce_cout[62:0],REG1_c32[14]};
wire [63:0]mul32_src2;
assign mul32_src2 = wallce_s;

wire [131:0]mul64_src1;
assign mul64_src1 = {wallce64_cout[130:0],REG1_c64[31]};
wire [131:0]mul64_src2;
assign mul64_src2 = wallce64_s;


////////////////////////////////////////////////////////////////////////////////////////////////////
reg REG2_valid;
reg REG2_mul32;
reg [63:0]REG2_mul32_src1;
reg [63:0]REG2_mul32_src2;
reg [131:0]REG2_mul64_src1;
reg [131:0]REG2_mul64_src2;
reg REG2_C32;
reg REG2_C64;
ysyx_22050854_Reg #(1,1'b0) REG2_gen0 (clock, reset, REG1_valid, REG2_valid, 1'b1);
ysyx_22050854_Reg #(1,1'b0) REG2_gen1 (clock, reset, REG1_mul32, REG2_mul32, 1'b1);
ysyx_22050854_Reg #(1,1'b0) REG2_gen2 (clock, reset, REG1_c32[15], REG2_C32, 1'b1);
ysyx_22050854_Reg #(1,1'b0) REG2_gen3 (clock, reset, REG1_c64[32], REG2_C64, 1'b1);
ysyx_22050854_Reg #(64,64'b0) REG2_gen4 (clock, reset, mul32_src1, REG2_mul32_src1, 1'b1);
ysyx_22050854_Reg #(64,64'b0) REG2_gen5 (clock, reset, mul32_src2, REG2_mul32_src2, 1'b1);
ysyx_22050854_Reg #(132,132'b0) REG2_gen6 (clock, reset, mul64_src1, REG2_mul64_src1, 1'b1);
ysyx_22050854_Reg #(132,132'b0) REG2_gen7 (clock, reset, mul64_src2, REG2_mul64_src2, 1'b1);

/////////////////////////////////////  加法器  /////////////////////////////////////////////
wire [63:0]mul32_result_temp; //存放32 x 32 位的乘积
wire [131:0]mul64_result_temp;
assign mul32_result_temp = REG2_mul32_src1 + REG2_mul32_src2 + {63'b0,REG2_C32}; //64位加法器
assign mul64_result_temp = REG2_mul64_src1 + REG2_mul64_src2 + {131'b0,REG2_C64}; //132位加法器

reg REG3_valid;
reg REG3_mul32;
reg [63:0]REG3_mul32_result;
reg [131:0]REG3_mul64_result;
ysyx_22050854_Reg #(1,1'b0) REG3_gen0 (clock, reset, REG2_valid, REG3_valid, 1'b1);
ysyx_22050854_Reg #(1,1'b0) REG3_gen1 (clock, reset, REG2_mul32, REG3_mul32, 1'b1);
ysyx_22050854_Reg #(64,64'b0) REG3_gen2 (clock, reset, mul32_result_temp, REG3_mul32_result, 1'b1);
ysyx_22050854_Reg #(132,132'b0) REG3_gen3 (clock, reset, mul64_result_temp, REG3_mul64_result, 1'b1);

assign mul_ready = mul_ready_t;
assign out_valid = REG3_valid;  //只持续一周期
assign result_lo = out_valid ? ( REG3_mul32 ? { {32{REG3_mul32_result[31]}},REG3_mul32_result[31:0] }  : REG3_mul64_result[63:0] ): 64'd0; //只持续一周期 用低64位表示输出
assign result_hi = (out_valid & ~REG3_mul32) ? {REG3_mul64_result[131],REG3_mul64_result[126:64]} : 64'b0;  //这个不确定
assign mul_doing = REG0_valid | REG1_valid | REG2_valid;

endmodule
