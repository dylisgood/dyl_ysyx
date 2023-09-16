module ysyx_22050854_genBooth (
    input [2:0]src,
    output sel_negative,sel_double_negative,sel_positive,sel_double_positive
);

wire y_add,y,y_sub;
assign {y_add,y,y_sub} = src;

assign sel_negative =  y_add & (y & ~y_sub | ~y & y_sub);
assign sel_positive = ~y_add & (y & ~y_sub | ~y & y_sub);
assign sel_double_negative =  y_add & ~y & ~y_sub;
assign sel_double_positive = ~y_add &  y &  y_sub;


endmodule