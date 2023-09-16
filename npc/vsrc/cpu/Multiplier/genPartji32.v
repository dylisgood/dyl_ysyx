module ysyx_22050854_genPartji32(
    input [2:0]src,
    input [63:0]x,
    output [63:0]p,
    output c
);

wire sel_negative,sel_double_negative,sel_positive,sel_double_positive;

//Booth信号生成模块
ysyx_22050854_genBooth booth_gen0 (
    .src(src),
    .sel_negative(sel_negative),
    .sel_double_negative(sel_double_negative),
    .sel_positive(sel_positive),
    .sel_double_positive(sel_double_positive)
);

// 求 32 * 32 位的部分积
ysyx_22050854_genBufenji_32 Bufenji32_gen0 (
    .x(x),
    .sel_negative(sel_negative),
    .sel_double_negative(sel_double_negative),
    .sel_positive(sel_positive),
    .sel_double_positive(sel_double_positive),
    .bufenji(p),
    .c(c)
);

endmodule