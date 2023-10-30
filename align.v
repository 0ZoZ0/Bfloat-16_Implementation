`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2023 19:45:54
// Design Name: 
// Module Name: align
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


module alignment (
    input wire sign1,
    input wire sign2,
    input wire operation,
    input wire [7:0] e1, 
    input wire [7:0] e2, 
    input wire [6:0] s1, 
    input wire [6:0] s2, 
    output reg sign,
    output reg new_sign2,
    output reg [7:0] e, 
    output reg [9:0] aligned_s1, 
    output reg [9:0] aligned_s2 
);
reg [7:0] dif;
reg actual_sign2;
reg [6:0] s, new_s2;
reg [31:0] shift_length;
reg sticky;
reg i,j;
reg [15:0] a;
reg acc_or;
always @(sign1, operation, e1, e2, s1, s2, s) begin
    if (e1 < e2) begin
        dif=e2-e1;
        e = e2;
        sign = operation ^ sign2;
        new_sign2 = sign1;
        s = s2;
        new_s2 = s1;
    end else begin
        dif=e1 - e2;
        e = e1;
        sign = sign1;
        new_sign2 = operation ^ sign2;
        s = s1;
        new_s2 = s2;
    end
  

    aligned_s1[6:0] = s;
    
end

always @(dif, shift_length, new_s2, sticky) begin
   
    a={9'b0,new_s2};
   
    
    if (dif < 9) begin
        shift_length = dif;
    end else begin
        shift_length = 9;
    end
    
    if (shift_length > 0)
    begin
    a=a>>shift_length;
       
    end
    
    acc_or = 0;
    
   if (a[6:1]>0 || acc_or > 0)
    begin
            acc_or = 1;
    end
    
    sticky = acc_or;
    aligned_s2 = {a[15:1], sticky};
end

endmodule
