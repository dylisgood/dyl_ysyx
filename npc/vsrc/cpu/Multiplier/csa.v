//一位全加器
module ysyx_22050854_csa(
  input [2:0] in,
  output cout,s

);
wire a,b,cin;
assign a=in[2];
assign b=in[1];
assign cin=in[0];
assign s = a ^ b ^ cin;
assign cout = a & b | b & cin | a & cin;

endmodule