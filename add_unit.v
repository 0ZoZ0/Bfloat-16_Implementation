module fp_adder(A, B, s,  sNaN,qNaN,inf,zero,normal,subnormal, inexact,invalid,overflow,underflow);
  parameter BIAS = ((1 << (8 - 1)) - 1); // IEEE 754, section 3.3
  parameter EMAX = BIAS; // IEEE 754, section 3.3
  parameter EMIN = (1 - EMAX); // IEEE 754, section 3.3
  parameter CLOG2_NSIG = $clog2(8);
  input [15:0] A, B;   // Operands
 

  output [15:0] s;     // Sum/Difference
  output reg sNaN,qNaN,inf,zero,normal,subnormal; // Type of return value: sNaN, qNaN, Infinity,
   // Zero, Normal, or Subnormal.
  output reg inexact,invalid,overflow,underflow;


  wire sNaNA,qNaNA,subnormalA,normalA,infA,zeroA;
  wire sNaNB,qNaNB,subnormalB,normalB,infB,zeroB;
  wire [15:0] rawSignificand;
  wire signed [8:0] aExp, bExp;
  reg signed [8:0] pExp, t1Exp, t2Exp;
  wire [7:0] aSig, bSig;
  reg [7:0] pSig, tSig;
  fp_classifier A_class (A,aExp,aSig,aSig,sNaNA,qNaNA,subnormalA,normalA,infA,zeroA);
  fp_classifier B_class (B,bExp,bSig,sNaNB,qNaNB,subnormalB,normalB,infB,zeroB);
  wire aSign = A[15];
  wire bSign = B[15]  ;

  reg signed [8:0] shiftAmt;
  // augendSig: Significand of the operand with the larger exponent
  // addendSig: Significand of the operand with the smaller exponent
  // Note: The exponent of the augend may note be strictly larger than
  //       the exponent of the addend. The two exponents may be equal
  //       but the exponent of the augend will never be smaller than
  //       the exponent of the addend.
  // sumSig:    Significand of the augend/addend significands.
  //            ***** This value may be negative!
  // absSig:    Absolute value of sumSig.
  // bigSig:    If adding augendSig and addendSig caused a carry out
  //            bigSig is right shifted so that the MSB of the significand
  //            sum will never be farther to the left than bit NSIG.
  //            ***** See bigExp below.
  // normSig:   If one of the numbers being added is negative, and the
  //            other is positive then it's likely the MSB of the sum
  //            isn't in bit NSIG. This means that we need to left shift
  //            the sum until the MSB is in bit NSIG. We then use the
  //            shift amount to adjust the corresponding exponent value.
  //            ***** See normExp below.
  // adjExp:  max(aExp, bExp)
  // bigExp:  Renormalized exponent if adding the augend/addend
  //          significands caused the MSB to be left of bit NSIG.
  //          ***** See bigSig above.
  // normExp: Renormalized exponent if the augend/addend has opposite
  //          signs.
  //          ***** See normSig above.
  // biasExp: Sum significand after adding the BIAS value into normExp.
  reg signed [9:0] adjExp, bigExp, normExp, biasExp;

  // Sign of significand sum before taking the absolute value of sumSig.
  reg sumSign;
  // Adjusted sumSign after taking absolute value of sumSig.
  wire absSign;

  // na is the shift count to renormalize after adding two numbers with
  // opposite signs.
  reg [CLOG2_NSIG-1:0] na;
  reg [9:-10] mask = ~0;

  reg Cout1, Cout2;
  reg subtract, e0, si;

  reg [15:0] alwaysS; // Sum/Difference generated inside the
                             // always block.
  wire [7:0] sigOut;

  integer i;
  reg signed [9:-10] augendSig, addendSig, sumSig, absSig, bigSig,
             normSig;

  always @(*)
  begin
    {sNaN,qNaN,inf,zero,normal,subnormal} = 0;
    {inexact,invalid,overflow,underflow} = 0;
    subtract = aSign ^ bSign;

    if (sNaNA | sNaNB)
      begin
        {alwaysS,sNaN,qNaN,inf,zero,normal,subnormal } = sNaNA ? 
        {A, sNaNA,qNaNA,subnormalA,normalA,infA,zeroA} 
        : {B, sNaNB,qNaNB,subnormalB,normalB,infB,zeroB};
      end
    else if (qNaNA | qNaNB)
      begin
        {alwaysS, sNaN,qNaN,inf,zero,normal,subnormal} = qNaNA ? 
                                    {A, sNaNA,qNaNA,subnormalA,normalA,infA,zeroA} 
                                        : {B, sNaNB,qNaNB,subnormalB,normalB,infB,zeroB};
      end
    else if (zeroA | zeroB)
      begin
        {alwaysS, sNaN,qNaN,inf,zero,normal,subnormal} = zeroB ?
                             {A, sNaNA,qNaNA,subnormalA,normalA,infA,zeroA} 
                             : {B, sNaNB,qNaNB,subnormalB,normalB,infB,zeroB};
      end
    else if (infA & infB)
      begin
        e0 =  1;
        si = 
              subtract;
        invalid =  subtract;
        inf  = ~si;
        qNaN      =  subtract;
        normal     = ~e0;
        alwaysS = {aSign, {{7{1'b1}}, e0},{7{si}}};
      end
    else if (infA | infB)
      begin
        {alwaysS, sNaN,qNaN,inf,zero,normal,subnormal} = infA ?
                                {A, sNaNA,qNaNA,subnormalA,normalA,infA,zeroA} 
                             : {B, sNaNB,qNaNB,subnormalB,normalB,infB,zeroB};
      end
    else // a and b are both (sub-)normal numbers
      begin
        augendSig = 0;
        addendSig = 0;
        na = 0;

        if (aExp < bExp)
          begin
            sumSign = bSign;
            shiftAmt = bExp - aExp;
            augendSig[7:0] = bSig;
            addendSig[7:0] = aSig;
            adjExp = bExp;
          end
        else
          begin
            sumSign = aSign;
            shiftAmt = aExp - bExp;
            augendSig[7:0] = aSig;
            addendSig[7:0] = bSig;
            adjExp = aExp;
          end

        addendSig = addendSig >> ((shiftAmt > 10) ? 10 : shiftAmt);

        // Check to see if we actually calculated a difference, and, if so,
        // renormalize the significand, and adjust the exponent accordingly.
        normSig = bigSig;

        for (i = (1 << (CLOG2_NSIG - 1)); i > 0; i = i >> 1)
          begin
            if ((normSig & (mask << (2*7+4 - i))) == 0)
              begin
                normSig = normSig << i;
                na = na | i;
              end
          end

        normExp = bigExp - na;

        // Control should return to the rounding logic from here.

        if (&na)
          begin
            zero = 1;
            alwaysS = {1'b0, {15{1'b0}}};
          end
        else if (expOut < EMIN)
          begin
            subnormal = 1;
            alwaysS = {absSign, {8{1'b0}}, sigOut[7:1]};
          end
        else if (expOut > EMAX)
          begin
            si = 1;
            alwaysS = {absSign, {7{1'b1}}, ~si, {7{si}}};
            inf = ~si;
            normal   =  si;
            overflow = 1;
          end
        else
          begin
            normal = 1;
            biasExp = expOut + BIAS;

            alwaysS = {absSign, biasExp[7:0], sigOut[6:0]};
          end

        inexact=1;
      end
  end

  // Compute sum/difference of significands



  // Adjusted sign if absSum = -sigSum:
  assign absSign = sumSign ^ sumSig[9];

  // Compute abs(sumSig):
  // If sumSig is negative then sumSig[NSIG+2] (the sign bit) will be 1.
  // If sumSig is negative then "sumSig^{2*NSIG+6{sumSig[NSIG+2]}}" is the
  // 1's complement of sumSig. Otherwise this value is just sumSig.
  // By using the sign bit of sumSig as the carry in value when sumSig is
  // negative we compute the 2's complement of sumSig, i.e., we find sumSig's
  // absolute value. If sumSig is positive, or zero, the output from this
  // adder is sumSig.


  // See if the addition caused a carry-out. If so, adjust the significand
  // and the exponent.
  always @(*)
  begin
  {sumSig, Cout1}=augendSig+addendSig^{2*7+6{subtract}}+
                subtract;
  {Cout2,absSig}={2*7+6{1'b0}}+sumSig^{2*7+6{sumSig[9]}}+
                 sumSig[9];
  bigSig = absSig >> absSig[8];
  bigExp = adjExp + absSig[8];
  end

  // Control returns to the "always" block above so we can renormalize if
  // what we're really calculating is a difference.

  // Round the significand.
  round #(2*7+4, 8 ,7) U2((absSign), normExp,
                                   normSig[7:-10], 
                                   expOut, sigOut, inexact);
  assign s = alwaysS;

endmodule