`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.11.2023 11:39:12
// Design Name: 
// Module Name: mul_round
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.11.2023 11:36:57
// Design Name: 
// Module Name: multiply
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


module mul_round (input [15:0] A,
                 input [15:0] B,
                 output [15:0] p,
                 output reg overflow,underflow,invalid,inexact,
                 output reg sNaN,qNaN,subnormal,normal,inf,zero
                  );
                  parameter BIAS = ((1 << (8 - 1)) - 1); // IEEE 754, section 3.3
                  parameter EMAX = BIAS; // IEEE 754, section 3.3
                  parameter EMIN = (1 - EMAX); // IEEE 754, section 3.3
                  wire sNaNA,qNaNA,subnormalA,normalA,infA,zeroA;
                  wire sNaNB,qNaNB,subnormalB,normalB,infB,zeroB;
                  wire [15:0] rawSignificand,sig_in;
                  wire signed [8:0] aExp, bExp,expOut;
                  reg signed [8:0] pExp, t1Exp, t2Exp,expIn;
                  wire [7:0] aSig, bSig;
                  reg [7:0] pSig, tSig;
                  fp_classifier A_class (A,aExp,aSig,aSig,sNaNA,qNaNA,subnormalA,normalA,infA,zeroA);
                  fp_classifier B_class (B,bExp,bSig,sNaNB,qNaNB,subnormalB,normalB,infB,zeroB);
                  
                  
                  wire [7:0] sigOut;
                  assign rawSignificand = aSig * bSig;

                  reg [15:0] sigIn;

                  
                  reg pSign,si;
                  reg [15:0] pTemp;
                  always @(*)
                  begin
    // IEEE 754-2019, section 6.3 requires that "[w]hen neither the
    // inputs nor result are NaN, the sign of a product ... is the
    // exclusive OR of the operands' signs".
                      pSign = A[15] ^ B[15];
                      pTemp = {pSign, {8{1'b1}}, 1'b0, {6{1'b1}}};  // Initialize p to be an sNaN.


                  if ((sNaNA|sNaNB)==1'b1)
                  begin
                        pTemp= sNaNA==1'b1 ? A:B;
                        sNaN=1;
                        invalid=1;
                  end
                  else if ((qNaNA|qNaNB)==1'b1)
                  begin
                        pTemp= qNaNA ==1'b1 ? A:B;
                        qNaN=1;
                  end
                  else if ((infA|infB)==1'b1)
                   begin
                   if (zeroA|zeroB==1'b1)
                   begin
                        pTemp= {pSign,{8{1'b1}},1'b1,6'h02A};  //qNAN value
                        qNaN=1;
                        invalid=1;
                   end
        else
          begin

             pTemp= {pSign,{8{1'b1}},{7{1'b0}}};  //qNAN value
            inf = 1;
            overflow = 1;
          end
      end
    else if ((zeroA|zeroB ==1'b1))
      begin
        pTemp = {pSign, {15{1'b0}}};
        zero = 1;
      end
    else
      begin
        sigIn = rawSignificand << ~rawSignificand[2*7+1];
        expIn = aExp + bExp + rawSignificand[2*7+1];

        // Here control logically passes out of the always block and into
        // the rounding module. This happens because the rounding module
        // can't be instantiated inside of the always block.

        if (expOut < EMIN) //The significand was rounded to zero or is Subnormal
          begin
            // For subnormal numbers there is no leading 1 bit to strip off so
            // we take the NSIG most significant bits. This also works in the
            // case that we rounded to zero.
            pTemp = {pSign, {8{1'b0}}, sigOut[7:1]};
            subnormal = |sigOut[7:1];
            zero      = ~subnormal;
            underflow = 1;
          end
        else if (expOut > EMAX) // Infinity
          begin
            si = 1;
            pTemp = {pSign, {7{1'b1}}, ~si, {6{si}}};
            inf = ~si;
            normal   =  si;
            overflow = 1;
          end
        else // Normal
          begin
            pExp = expOut + BIAS;
            // Remember that for Normals we always assume the most
            // significant bit is 1 so we only store the least
            // significant NSIG bits in the significand.
            pTemp = {pSign, pExp[7:0], sigOut[6:0]};
            normal = 1;
          end
      
        
      end //
  end
  
  // Round the significand.
  round #(15, 8, 7) U0(pSign, expIn, sigIn, ra, expOut, sigOut,
                                   inexact);

  // Logically control returns to the always block which constructs the final
  // product value based the rounded exponent value expOut.

  assign p = pTemp;

endmodule
