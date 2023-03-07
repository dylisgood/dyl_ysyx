`timescale 1ns/1ps
module ysyx_22050854_src_gen(
    input ALUsrc1,
    input [1:0]ALUsrc2,
    input [4:0]rs1,
    input [4:0]rs2,
    input [31:0]pc,
    input [63:0]imm,
    output reg [63:0]src1,
    output reg [63:0]src2,
    output reg [63:0]alu_src1,
    output reg [63:0]alu_src2
);
    ysyx_22050854_RegisterFile reg_rddata(
        .clk(),
        .wdata(),
        .waddr(),
        .wen(1'b0),        
        .raddra(rs1),
        .raddrb(rs2),
        .rdata1(src1),
        .rdata2(src2)      
    );
    
    ysyx_22050854_MuxKeyWithDefault #(2,1,64) src1_gen(alu_src1,ALUsrc1,64'd0,{
        1'd0,src1,
        1'd1,{{32'b0},pc}
    });

    ysyx_22050854_MuxKeyWithDefault #(3,2,64) src2_gen(alu_src2,ALUsrc2,64'd0,{
        2'b00,src2,
        2'b01,imm,
        2'b10,64'd4
    });

endmodule
