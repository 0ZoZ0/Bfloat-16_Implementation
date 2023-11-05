`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2023 17:12:03
// Design Name: 
// Module Name: mult
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


module seq_multiplier(product,multiplicand,multiplier,start,clk,reset);
  parameter d_width=5;
  output [2*d_width-1:0] product;
  input [d_width-1:0] multiplicand,multiplier;
  input start,clk,reset;
  parameter BC_size=3;
  parameter S_idle=3'b000,S_add=3'b010,S_shift=3'b100;
  reg [2:0] state,n_state;
  reg C;
  reg [d_width-1:0] A,B,Q;
  reg [BC_size-1:0] P;
  reg Load,dec_P,Add,Shift;
  
  assign product={A,Q};
  wire Zero=(P==0);
  wire ready=(state==S_idle);
  always @(posedge clk,negedge reset)
    if (!reset) state<=S_idle;
      else state<=n_state;
  always @(state,start,Q[0],Zero)
    begin
      n_state=S_idle;
      Load=0;
      dec_P=0;
      Add=0;
      Shift=0;
      case(state)
        S_idle:if (start) begin n_state=S_add; Load=1; end
        S_add: begin n_state=S_shift; dec_P=1; if(Q[0]) Add=1; end
        S_shift: begin Shift=1; if (Zero) n_state=S_idle;else n_state=S_add;end
        default:n_state=S_idle;
      endcase
    end
  
  
  always@(posedge clk)
    begin
      if (Load) begin
        P<=d_width;
        A<=0;
        C<=0;
        B<=multiplicand;
        Q<=multiplier;
      end
      if (Add) {C,A}<=A+B;
      if(Shift) {C,A,Q}<={C,A,Q}>>1;
      if(dec_P) P<=P-1;
    end
endmodule
