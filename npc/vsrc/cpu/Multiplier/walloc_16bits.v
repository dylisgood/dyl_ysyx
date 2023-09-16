module ysyx_22050854_walloc_16bits(
    input [15:0] src_in, 
    input [13:0]  cin, //来自右边华莱士树的进位输入，最右边的华莱士树的 cin 是来自 switch 模块
    output [13:0] cout_group, //输入到左边的华莱士树的进位输出，最左边的华莱士树的忽略即可
    output      cout,s     //输出到加法器的 src1,输出到加法器的 src2
);
wire [13:0] c;
///////////////first////////////////
wire [4:0] first_s;
ysyx_22050854_csa csa0 (.in (src_in[15:13]), .cout (c[4]), .s (first_s[4]) );
ysyx_22050854_csa csa1 (.in (src_in[12:10]), .cout (c[3]), .s (first_s[3]) );
ysyx_22050854_csa csa2 (.in (src_in[09:07]), .cout (c[2]), .s (first_s[2]) );
ysyx_22050854_csa csa3 (.in (src_in[06:04]), .cout (c[1]), .s (first_s[1]) );
ysyx_22050854_csa csa4 (.in (src_in[03:01]), .cout (c[0]), .s (first_s[0]) );

///////////////second//////////////
wire [3:0] secnod_s;
ysyx_22050854_csa csa5 (.in ({first_s[4:2]}             ), .cout (c[8]), .s (secnod_s[3]));
ysyx_22050854_csa csa6 (.in ({first_s[1:0],src_in[0]}   ), .cout (c[7]), .s (secnod_s[2]));
ysyx_22050854_csa csa7 (.in ({cin[4:2]}       ), .cout (c[6]), .s (secnod_s[1]));
ysyx_22050854_csa csa8 (.in ({cin[1:0],1'b0}  ), .cout (c[5]), .s (secnod_s[0]));

//////////////thrid////////////////
wire [1:0] thrid_s;
ysyx_22050854_csa csa9 (.in (secnod_s[3:1]          ), .cout (c[10]), .s (thrid_s[1]));
ysyx_22050854_csa csaA (.in ({secnod_s[0],cin[6:5]} ), .cout (c[09]), .s (thrid_s[0]));

//////////////fourth////////////////
wire [1:0] fourth_s;

ysyx_22050854_csa csaB (.in ({thrid_s[1:0],cin[10]} ),  .cout (c[12]), .s (fourth_s[1]));
ysyx_22050854_csa csaC (.in ({cin[9:7]             }),  .cout (c[11]), .s (fourth_s[0]));

//////////////fifth/////////////////
wire fifth_s;

ysyx_22050854_csa csaD (.in ({fourth_s[1:0],cin[11]}),  .cout (c[13]), .s (fifth_s));

///////////////sixth///////////////
ysyx_22050854_csa csaE (.in ({fifth_s,cin[13:12]}   ),  .cout (cout),  .s  (s));

///////////////output///////////////
assign cout_group = c;
endmodule