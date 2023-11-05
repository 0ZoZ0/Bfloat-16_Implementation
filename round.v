`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.11.2023 00:24:37
// Design Name: 
// Module Name: round
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


module half_precision_rounding (
    input [15:0] in_data, // Input half-precision floating-point value
    output reg [15:0] out_data // Output half-precision floating-point value after rounding
);

// Constants for IEEE 754 half-precision format
parameter EXPONENT_BITS = 8;
parameter FRACTION_BITS = 7;
parameter SIGN_BIT = 15;
parameter EXPONENT_START = 14;
parameter EXPONENT_END = 7;
parameter FRACTION_START = 6;
parameter FRACTION_END = 0;
parameter ROUND_TO_NEAREST = 10;

// Extract sign, exponent, and fraction parts
wire sign = in_data[SIGN_BIT];
wire [EXPONENT_BITS-1:0] exponent = in_data[EXPONENT_START:EXPONENT_END];
wire [FRACTION_BITS-1:0] fraction = in_data[FRACTION_START:FRACTION_END];

always @(*) begin
    if (exponent == 8'hff) begin
        // NaN or infinity, no rounding required
        out_data = in_data;
    end else if (exponent >= ROUND_TO_NEAREST) begin
        // Rounding required, round to the nearest even
        if (fraction[0] == 1'b1) begin
            // Need to round up
            if (fraction == 7'b1111111) begin
                // Carry to the exponent if fraction is all ones
                out_data = {sign, exponent + 1'b1,7'b0};
            end else begin
                out_data = {sign, exponent, fraction + 1'b1};
            end
        end else begin
            // No rounding required
            out_data = in_data;
        end
    end else begin
        // No rounding required
        out_data = in_data;
    end
end

endmodule