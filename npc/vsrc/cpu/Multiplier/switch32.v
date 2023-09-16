module ysyx_22050854_switch32 (
    input [63:0] input_data [15:0], // 16个64位的输入数据
    output [15:0] output_data [63:0] // 64个16位的输出数据
);

    reg [15:0] temp_data [63:0]; // 临时存储16位的数据

    integer i, j;

    always @* begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 64; j = j + 1) begin
                temp_data[j][i] = input_data[i][j];
            end
        end
    end

    assign output_data = temp_data;

endmodule
