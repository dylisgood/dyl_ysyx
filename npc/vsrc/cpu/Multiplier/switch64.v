module ysyx_22050854_swtich64(
    input [131:0] input_data [32:0],
    output [32:0] output_data [131:0]
);
    reg [32:0] temp_data [131:0]; 

    integer i,j;

    always @(*)begin 
        for(i = 0; i < 33; i = i + 1)begin
            for(j = 0; j < 132; j = j + 1)begin
                temp_data[j][i] = input_data[i][j];
            end
        end
    end

    assign output_data = temp_data;

endmodule
