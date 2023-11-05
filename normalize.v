`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2023 17:53:25
// Design Name: 
// Module Name: normalize
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



    
 module normalize (
    input sign, operation,
    input [7:0] e, dif,
    input [10:0] result, alt_result,
    output new_sign, zero_flag,
    output [9:0] new_s,
    output [7:0] new_e
);

wire [9:0] result_div_B, s1, s;
wire [4:0] exp1, k, exp2;
wire sign1, sign2;

// divide_by_B
assign result_div_B = result>>1;
 
assign s1 = (result[10] == 1'b0) ? result[9:0] : result_div_B;
assign exp1 = (result[1] == 1'b0) ? e : e + 1;
assign sign1 = sign;

assign s = ((dif == 8'b00000000) && (result[1] > 1'b0)) ? alt_result[9:0] : result[9:0];

assign zero_flag = (s == 10'b0000000000) ? 1'b1 : 1'b0;

assign k = (zero_flag == 1'b1) ? 5'b10000 : 5'b00000;
reg [9:0] s2;
always @* begin
    if (k > 5'b00000) begin
        s2 = s>>(k+6);
    end else begin
        s2 = s;
    end
end

assign exp2 = e - k;
assign sign2 = ((dif == 8'b00000000) && (result[1] > 1'b0)) ? ~sign : sign;

assign new_s = (operation == 1'b0) ? s1 : s2;
assign new_e = (operation == 1'b0) ? exp1 : exp2;
assign new_sign = (operation == 1'b0) ? sign1 : sign2;


endmodule
