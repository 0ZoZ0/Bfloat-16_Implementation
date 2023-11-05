`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2023 18:57:02
// Design Name: 
// Module Name: add
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


module add(
input sign,sign2,
input [9:0] aligned_s1,aligned_s2,
input [7:0] exp1,exp2,
output [10:0] result,alt_result

);

wire [10:0] long_s,long_s2,inv_s1,inv_s2;
wire [10:0] carry1,carry2;

assign inv_s1=~aligned_s1;
assign inv_s2=~aligned_s2;

assign result= aligned_s1+aligned_s2;
endmodule
