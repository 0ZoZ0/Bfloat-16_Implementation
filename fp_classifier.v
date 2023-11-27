`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.11.2023 10:55:06
// Design Name: 
// Module Name: fp_classifier
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


module fp_classifier( input [15:0] num,
                      output reg signed [8:0] fexp,
                      output reg signed [7:0] fsig,
                      output sNaN,qNaN,subnormal,normal,inf,zero

    );

wire [7:0] exp;
wire [6:0] mant;    
assign exp=num[14:7];

assign sign=num[15];

assign mant=num[6:0];


assign sNaN= (exp==8'hff) && (num[6]==0);
assign qNaN= (exp==8'hff) && (num[6]==1);

assign inf = (mant==0) && (exp==8'hff);
assign zero = (mant==0) && (exp==0);
assign subnormal= (exp==0) && (mant !=0);
assign normal= (exp!=0) && (exp !=8'hff);

reg [7:0] mask = ~0;
reg [3:0] shamt; 
integer i;
    
    always @(*)
      begin
        // Use actual exponent/significand values for sNaNs, qNaNs,
        // infinities, and zeroes.
        fexp = num[14:7];
        fsig = num[6:0];
        
        shamt = 0;

        if (normal)
          {fexp, fsig} = {num[14:7] - 127, 1'b1, num[6:0]};
        else if (subnormal)
          begin
            // Shift the most significant bit into the position
            // of the Normal's implied 1. Keep track of how many
            // places were needed to shift the most significant
            // set bit so we can adjust the exponent when we're
            // done.
            for (i = 8; i > 0; i = i >> 1)
              begin
                if ((fsig & (mask << (11 - i))) == 0)
                  begin
                    fsig = fsig << i;
                    shamt = shamt | i;
                  end
              end
              
            fexp = -126 - shamt; // "-14" is the smallest Normal exponent
                             // as a signed value.
          end
      end
    
endmodule





