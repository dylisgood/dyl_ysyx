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
/*     ysyx_22050854_MuxKeyWithDefault #(2,1,64) src1_gen(alu_src1,ALUsrc1,64'd0,{
        1'd0,src1,
        1'd1,{{32'b0},pc}
    }); */
    assign alu_src2 = ALUsrc2 == 2'b00 ? src2 :
                      ALUsrc2 == 2'b01 ? imm :
                      ALUsrc2 == 2'b10 ? 64'd4 :
                                         64'd0;

/*     ysyx_22050854_MuxKeyWithDefault #(3,2,64) src2_gen(alu_src2,ALUsrc2,64'd0,{
        2'b00,src2,
        2'b01,imm,
        2'b10,64'd4
    });
 */
endmodule
