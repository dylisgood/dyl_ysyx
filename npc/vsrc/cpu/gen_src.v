module ysyx_22050854_src_gen(
    input ALUsrc1,
    input [1:0]ALUsrc2,
    input [31:0]pc,
    input [63:0]imm,
    input [63:0]src1,
    input [63:0]src2,
    output [63:0]alu_src1,
    output [63:0]alu_src2
);
    assign alu_src1 = ALUsrc1 ? {{32'b0},pc} : src1;

    assign alu_src2 = ALUsrc2 == 2'b00 ? src2 :
                      ALUsrc2 == 2'b01 ? imm :
                      ALUsrc2 == 2'b10 ? 64'd4 :
                                         64'd0;

endmodule
