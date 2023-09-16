module ysyx_22050854_genBufenji_64 (
    input [131:0]x,
    input sel_positive,
    input sel_double_positive,
    input sel_negative,
    input sel_double_negative,
    output [131:0]bufenji,
    output c
);

reg [131:0]p;
always @(*)begin
    p[0] = ~( ~(sel_negative & ~x[0]) & ~(sel_double_negative & 1'b1) & ~(sel_positive & x[0] ) & ~(sel_double_positive & 1'b0) );
    for (int i = 1; i < 132; i = i + 1)begin
        p[i] = ~( ~(sel_negative & ~x[i]) & ~(sel_double_negative & ~x[i-1]) & ~(sel_positive & x[i] ) & ~(sel_double_positive & x[i-1]) );
    end
end

assign c = (sel_negative | sel_double_negative);
assign bufenji = p;

endmodule