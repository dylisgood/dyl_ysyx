module ysyx_22050854_walloc_33bits(
    input [32:0] src_in, 
    input [30:0]  cin, //来自右边华莱士树的进位输入，最右边的华莱士树的 cin 是来自 switch 模块
    output [30:0] cout_group, //输入到左边的华莱士树的进位输出，最左边的华莱士树的忽略即可
    output      cout,s     //输出到加法器的 src1,输出到加法器的 src2
);
wire [30:0] c;
///////////////first////////////////
wire [10:0] first_s;
ysyx_22050854_csa csa0 (.in (src_in[02:00]), .cout (c[0]), .s (first_s[0]) );
ysyx_22050854_csa csa1 (.in (src_in[05:03]), .cout (c[1]), .s (first_s[1]) );
ysyx_22050854_csa csa2 (.in (src_in[08:06]), .cout (c[2]), .s (first_s[2]) );
ysyx_22050854_csa csa3 (.in (src_in[11:09]), .cout (c[3]), .s (first_s[3]) );
ysyx_22050854_csa csa4 (.in (src_in[14:12]), .cout (c[4]), .s (first_s[4]) );
ysyx_22050854_csa csa5 (.in (src_in[17:15]), .cout (c[5]), .s (first_s[5]) );
ysyx_22050854_csa csa6 (.in (src_in[20:18]), .cout (c[6]), .s (first_s[6]) );
ysyx_22050854_csa csa7 (.in (src_in[23:21]), .cout (c[7]), .s (first_s[7]) );
ysyx_22050854_csa csa8 (.in (src_in[26:24]), .cout (c[8]), .s (first_s[8]) );
ysyx_22050854_csa csa9 (.in (src_in[29:27]), .cout (c[9]), .s (first_s[9]) );
ysyx_22050854_csa csa10 (.in (src_in[32:30]), .cout (c[10]), .s (first_s[10]) );

///////////////second//////////////
wire [7:0] secnod_s;
ysyx_22050854_csa cas11 (.in ({first_s[10:8]}             ), .cout (c[11]), .s (secnod_s[0]));
ysyx_22050854_csa cas12 (.in ({first_s[7:5]}              ), .cout (c[12]), .s (secnod_s[1]));
ysyx_22050854_csa cas13 (.in ({first_s[4:2]}             ), .cout (c[13]), .s (secnod_s[2]));
ysyx_22050854_csa csa14 (.in ({first_s[1:0],cin[9]}   ), .cout (c[14]), .s (secnod_s[3]));
ysyx_22050854_csa csa15 (.in ({cin[8:6]}       ), .cout (c[15]), .s (secnod_s[4]));
ysyx_22050854_csa csa16 (.in ({cin[5:3]}       ), .cout (c[16]), .s (secnod_s[5]));
ysyx_22050854_csa csa17 (.in ({cin[2:0]}       ), .cout (c[17]), .s (secnod_s[6]));
ysyx_22050854_csa csa18 (.in ({cin[12:10]}  ), .cout (c[18]), .s (secnod_s[7]));

//////////////thrid////////////////
wire [4:0] thrid_s;
ysyx_22050854_csa csa19 (.in (secnod_s[6:4]          ), .cout (c[19]), .s (thrid_s[0]));
ysyx_22050854_csa csa20 (.in (secnod_s[3:1]          ), .cout (c[20]), .s (thrid_s[1]));
ysyx_22050854_csa csa21 (.in ({secnod_s[0],cin[20:19]}  ), .cout (c[21]), .s (thrid_s[2]));
ysyx_22050854_csa csa22 (.in (cin[18:16] ), .cout (c[22]), .s (thrid_s[3]));
ysyx_22050854_csa csa23 (.in (cin[15:13] ), .cout (c[23]), .s (thrid_s[4]));

//////////////fourth////////////////
wire [3:0] fourth_s;
ysyx_22050854_csa csa24 (.in ( thrid_s[4:2] ),  .cout (c[24]), .s (fourth_s[0]));
ysyx_22050854_csa csa25 (.in ({thrid_s[1:0],cin[21]}),  .cout (c[25]), .s (fourth_s[1]));
ysyx_22050854_csa csa26 (.in (cin[24:22] ), .cout (c[26]), .s (fourth_s[2]));
ysyx_22050854_csa csa27 (.in (cin[27:25] ), .cout (c[27]), .s (fourth_s[3]));

//////////////fifth/////////////////
wire [2:0]fifth_s;
ysyx_22050854_csa csa28 (.in ({fourth_s[3:1]}),  .cout (c[28]), .s (fifth_s[2]));
ysyx_22050854_csa csa29 (.in ({fourth_s[0],cin[29:28]}),  .cout (c[29]), .s (fifth_s[1]));
ysyx_22050854_csa csa30 (.in ({cin[30],secnod_s[7],1'b0}),  .cout (c[30]), .s (fifth_s[0]));

///////////////sixth///////////////
ysyx_22050854_csa csa31 (.in ({fifth_s}   ),  .cout (cout),  .s  (s));

///////////////output///////////////
assign cout_group = c;
endmodule