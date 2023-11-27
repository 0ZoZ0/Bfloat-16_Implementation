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


module multiply( input [15:0] A,
                 input [15:0] B,
                 output [15:0] p,
                 output reg overflow,underflow,invalid,inexact,
                 output reg sNaN,qNaN,subnormal,normal,inf,zero
                  );
                  
                  wire sNaNA,qNaNA,subnormalA,normalA,infA,zeroA;
                  wire sNaNB,qNaNB,subnormalB,normalB,infB,zeroB;
                  wire [15:0] rawSignificand;
                  wire signed [8:0] aExp, bExp;
                  reg signed [8:0] pExp, t1Exp, t2Exp;
                  wire [7:0] aSig, bSig;
                  reg [7:0] pSig, tSig;
                  fp_classifier A_class (A,aExp,aSig,aSig,sNaNA,qNaNA,subnormalA,normalA,infA,zeroA);
                  fp_classifier B_class (B,bExp,bSig,sNaNB,qNaNB,subnormalB,normalB,infB,zeroB);
                  
                  assign rawSignificand = aSig * bSig;
                  
                  reg pSign;
                  reg [15:0] pTemp;
                  always @ (*)
                    begin
                    pSign=A[15]^B[15];
                    pTemp={1'b0,{8{1'b1}},1'b0,{6{1'b0}}}; //snan
                    {sNaN,qNaN,subnormal,normal,inf,zero}=6'b000000;
                    {overflow,underflow,invalid,inexact}=4'b00;
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
                        if(zeroA|zeroB==1'b1)
                        begin
                            pTemp= {pSign,{8{1'b1}},1'b1,6'h02A};  //qNAN value
                            qNaN=1;
                            invalid=1;
                        end
                        else 
                         begin
                            pTemp= {pSign,{8{1'b1}},{7{1'b0}}};  //qNAN value
                            inf=1;
                        end
                        
                    end
                    else if ((zeroA|zeroB ==1'b1)||(subnormalA & subnormalB==1'b1))
                    begin 
                    pTemp= {pSign,{15{1'b0}}};
                    zero=1;
                    end
                    else    // At least one of the operands is Normal.
                    begin // The other may be Subnormal or Normal.
                    t1Exp = aExp + bExp;

                       if (rawSignificand[15] == 1'b1)
                        begin
                          tSig = rawSignificand[15:8];
                          t2Exp = t1Exp + 1;
                        end
                       else
                         begin
                           tSig = rawSignificand[14:7];
                           t2Exp = t1Exp;
                         end

                    if (t2Exp < -133) // Too small to even be represented as
                       begin          // a Subnormal; round down to Zero.
                        pTemp = {pSign, {15{1'b0}}};
                        zero = 1;
                        underflow=1;
                    end
        else if (t2Exp < -126) // Subnormal
          begin
            pSig = tSig >> (-126 - t2Exp);
            // Remember that we can only store 10 bits
            pTemp = {pSign, {8{1'b0}}, pSig[6:0]};
            subnormal = 1;
            inexact=1;
          end 
        else if (t2Exp > 127) // Infinity
          begin
            pTemp = {pSign, {8{1'b1}}, {7{1'b0}}};
            inf = 1;
            overflow=1;
          end
        else // Normal
          begin
            pExp = t2Exp + 127;
            pSig = tSig;
            // Remember that for Normals we always assume the most
            // significant bit is 1 so we only store the least
            // significant 10 bits in the significand.
            pTemp = {pSign, pExp[7:0], pSig[6:0]};
            normal = 1;
          end
      end //

                    
                    
                    
       end
                  
endmodule
