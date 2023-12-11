module ysyx_22050854_imm_gen(
    input [31:0]instr,
    input [2:0]ExtOP,
    output reg[63:0]imm
);
    wire [63:0]immI,immU,immS,immB,immJ,immCoushu;
    assign immI = {{52{instr[31]}},instr[31:20]};
    assign immU = {{32{instr[31]}},instr[31:12],12'b0};
    assign immS = {{52{instr[31]}},instr[31:25],instr[11:7]};
    assign immB = {{52{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
    assign immJ = {{44{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};
    assign immCoushu = { 57'b0,instr[6:0] };

    always @(*)begin
        case(ExtOP)
        3'b000: imm = immI;
        3'b001: imm = immU;
        3'b010: imm = immS;
        3'b011: imm = immB;
        3'b100: imm = immJ;
        3'b101: imm = immCoushu;
        default: imm = 64'b0;
        endcase
    end

/*     ysyx_22050854_MuxKeyWithDefault #(6,3,64) imm_gen (imm,ExtOP,64'b0,{
        3'b000,immI,
        3'b001,immU,
        3'b010,immS,
        3'b011,immB,
        3'b100,immJ,
        3'b101,immCoushu
    }); */

endmodule


