/*
    模块名称：除法器
    功能：支持64 / 64 的有符号 / 无符号 除法 获得商和余数
         支持32 / 32 的有符号 / 无符号 除法 获得商和余数
*/

module ysyx_22050854_divider_1 (
    input clock,
    input reset,
    input [63:0]dividend,  //被除数
    input [63:0]divisor,   //除数
    input div_valid,       //为高表示输入的数据有效，如果没有新的除法输入，在除法被接受的下一个周期要置低
    input divw,            //为高表示输入是32位除法
    input div_signed,      //为高表示是有符号除法
    output div_doing,
    output div_ready,      //为高表示除法器空闲，可以输入数据
    output out_valid,      //为高表示除法器输出结果有效
    output [63:0]quotient, //商
    output [63:0]remainder //余数
);

//第一步 根据被除数和除数确定商和余数的符号 并计算被除数和除数的绝对值
// 规定余数的符号和被除数的符号保持一致
reg sign_quotient;   //0-正数 1-负数
reg sign_remainder;
reg [63:0]ABS_dividend_32;
reg [32:0]ABS_divisor_32;
reg [127:0]ABS_dividend_64;
reg [64:0]ABS_divisor_64;
reg div32_go;
reg div64_go;
reg div_ready_t;

wire [31:0]dividend_32;
assign dividend_32 = {27'b0,div32_index};
import "DPI-C" function void get_dividend_value(int dividend_32);
always@(*) get_dividend_value(dividend_32);

wire [31:0]divisor_32;
assign divisor_32 = {31'b0,div32_over};
import "DPI-C" function void get_divisor_value(int divisor_32);
always@(*) get_divisor_value(divisor_32);

always @(posedge clock)begin
    if(reset)begin
        sign_quotient <= 1'b0;
        sign_remainder <= 1'b0;
        ABS_dividend_32 <= 64'b0;
        ABS_divisor_32  <=33'b0;
        ABS_dividend_64 <= 128'b0;
        ABS_divisor_64 <= 65'b0;
        div32_go <= 1'b0;
        div64_go <= 1'b0;
        div_ready_t <= 1'b1;
    end
    else if( div_ready_t & div_valid & divw & div_signed )begin // 有符号的32位除法
        div32_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= dividend[31] ^ divisor[31];
        sign_remainder <= dividend[31];
        if( dividend[31] ) ABS_dividend_32[31:0] <= ~dividend[31:0] + 1; 
        else ABS_dividend_32[31:0] <= dividend[31:0];
        if( divisor[31] ) ABS_divisor_32[31:0] <= ~divisor[31:0] + 1;
        else ABS_divisor_32[31:0] <= divisor[31:0];
    end
    else if( div_ready_t & div_valid & divw & !div_signed )begin // 无符号的32位除法
        div32_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= 1'b0;  //对于无符号数运算 最后一步默认就是运算结果就可
        sign_remainder <= 1'b0; 
        ABS_dividend_32[31:0] <= dividend[31:0];
        ABS_divisor_32[31:0] <= divisor[31:0];       
    end
    else if( div_ready_t & div_valid & ~divw & div_signed )begin // 有符号的64位除法
        div64_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= dividend[63] ^ divisor[63];
        sign_remainder <= dividend[63];
        if( dividend[63] ) ABS_dividend_64[63:0] <= ~dividend + 1; 
        else ABS_dividend_64[63:0] <= dividend;
        if( divisor[63] ) ABS_divisor_64[63:0] <= ~divisor + 1;
        else ABS_divisor_64[63:0] <= divisor;
    end
    else if( div_ready_t & div_valid & ~divw & ~div_signed )begin // 无符号的64位除法
        div64_go <= 1'b1;
        div_ready_t <= 1'b0;
        sign_quotient <= 1'b0;
        sign_remainder <= 1'b0;
        ABS_dividend_64[63:0] <= dividend;
        ABS_divisor_64[63:0] <= divisor;
    end
    else if( div32_over | div64_over )begin
        sign_quotient <= 1'b0;
        sign_remainder <= 1'b0;
        ABS_dividend_32 <= 64'b0;
        ABS_divisor_32  <= 33'b0;
        ABS_dividend_64 <= 128'b0;
        ABS_divisor_64 <= 65'b0;
        div_ready_t <= 1'b1;
    end
end

//计数器
reg [7:0]div_count;
always @(posedge clock)begin
    if(reset)
        div_count <= 8'b0;
    else if( div32_go & (div_count >= 8'd32) ) //得需要33个周期，因为获得余数还需要一个周期
        div_count <= 8'b0;
    else if( div64_go & (div_count >= 8'd64) )
        div_count <= 8'b0;
    else if( div32_go | div64_go )
        div_count <= div_count + 8'b1;
    else
        div_count <= 8'b0;
end

//第二步 迭代运算得到商和余数的绝对值
reg [31:0]div32_result_quotient;
reg [31:0]div32_result_remainder;
reg [63:0]div64_result_quotient;
reg [63:0]div64_result_remainder;
reg [4:0]div32_index;
reg [5:0]div64_index;
always @(posedge clock)begin
    if(reset)begin
        div32_result_quotient <= 32'b0;
        div32_result_remainder <= 32'b0;
        div64_result_quotient <= 64'b0;
        div64_result_remainder <= 64'b0;
        div32_index <= 5'd31;
        div64_index <= 6'd63;
    end
    else if( div32_go & (div_count < 8'd32 ))begin     //32x32 获得商
        if ( ( ABS_dividend_32[63:31] < ABS_divisor_32 ) )begin
            div32_result_quotient[div32_index] <= 1'b0;
            if(div_count != 8'd31) ABS_dividend_32 <= ABS_dividend_32 << 1;
        end
        else begin
            div32_result_quotient[div32_index] <= 1'b1;
            if( div_count != 8'd31 ) 
                ABS_dividend_32 <= { ABS_dividend_32 - {ABS_divisor_32,31'b0} } << 1; //够减，调整剩余被乘数,然后再左移一位
            else 
                ABS_dividend_32 <= { ABS_dividend_32 - {ABS_divisor_32,31'b0} };
        end
        div32_index <= div32_index - 5'd1;
    end
    else if( div32_go & (div_count == 8'd32) )begin     //32x32 获得余数
        div32_result_remainder <= ABS_dividend_32[62:31];
    end
    else if( div64_go & (div_count < 8'd64 ))begin      //64x64 获得商
        if ( ( ABS_dividend_64[127:63] < ABS_divisor_64 ) )begin
            div64_result_quotient[div64_index] <= 1'b0;
            if(div_count != 8'd63) ABS_dividend_64 <= ABS_dividend_64 << 1;
        end
        else begin
            div64_result_quotient[div64_index] <= 1'b1;
            if( div_count != 8'd63 ) 
                ABS_dividend_64 <= { ABS_dividend_64 - {ABS_divisor_64,63'b0} } << 1; //够减，调整剩余被乘数,然后再左移一位
            else 
                ABS_dividend_64 <= { ABS_dividend_64 - {ABS_divisor_64,63'b0} };
        end
        div64_index <= div64_index - 6'd1;
    end
    else if( div64_go & (div_count == 8'd64) )begin     //64x64 获得余数
        div64_result_remainder <= ABS_dividend_64[126:63];
    end  
    else if( div32_over | div64_over )begin
        div32_result_quotient <= 32'b0;
        div32_result_remainder <= 32'b0;
        div64_result_quotient <= 64'b0;
        div64_result_remainder <= 64'b0;
        div32_index <= 5'd31;
        div64_index <= 6'd63;
    end
end

reg div32_over;
reg div64_over;
always @(posedge clock)begin
    if(reset)begin
        div32_over <= 1'b0;
        div64_over <= 1'b0;
    end
    else if(div32_go & (div_count >= 8'd32)) begin//得需要33个周期，因为获得余数还需要一个周期
        div32_over <= 1'b1;
        div32_go <= 1'b0;
    end
    else if(div64_go & (div_count >= 8'd64))begin //得需要65个周期，因为获得余数还需要一个周期
        div64_over <= 1'b1;
        div64_go <= 1'b0;
    end
    else begin
        div32_over <= 1'b0;
        div64_over <= 1'b0;
    end
end

//第3步，调整最终的商和余数
wire [31:0]quotient_32;
wire [31:0]remainder_32;
assign quotient_32 = div32_over ? ( sign_quotient ? (~div32_result_quotient + 32'b1) : div32_result_quotient ) : 32'b0;
assign remainder_32 = div32_over ? ( sign_remainder ? (~div32_result_remainder + 32'b1) : div32_result_remainder ) : 32'b0;
assign quotient = div64_over ? ( sign_quotient ? (~div64_result_quotient + 64'b1) : div64_result_quotient ) : {{32{quotient_32[31]}},quotient_32};
assign remainder = div64_over ? ( sign_remainder ? (~div64_result_remainder + 64'b1) : div64_result_remainder ) :{{32{quotient_32[31]}},remainder_32};
assign div_doing = div32_go | div64_go;
assign out_valid = div32_over | div64_over;
assign div_ready = div_ready_t;

endmodule

