module ysyx_22050854_genPartji64(
    input [2:0]src,
    input [131:0]x,
    output [131:0]p,
    output c
);

wire sel_negative,sel_double_negative,sel_positive,sel_double_positive;

//Booth信号生成模块
ysyx_22050854_genBooth booth_gen1 (
    .src(src),
    .sel_negative(sel_negative),
    .sel_double_negative(sel_double_negative),
    .sel_positive(sel_positive),
    .sel_double_positive(sel_double_positive)
);

// 求 64 * 64 位的部分积
ysyx_22050854_genBufenji_64 Bufenji64_gen0 (
    .x(x),
    .sel_negative(sel_negative),
    .sel_double_negative(sel_double_negative),
    .sel_positive(sel_positive),
    .sel_double_positive(sel_double_positive),    
    .bufenji(p),
    .c(c)
);
endmodule