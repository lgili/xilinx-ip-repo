/*
Copyright (c) 2014-2022 Luiz Carlos Gili

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// Language: Verilog 2001

`timescale 1 ns/100 ps

module cordic(clock, angle, Amp, Phase_shift, Cos_out, Sin_out);
   
   parameter DATA_WIDTH = 16;   // bit width of input and output data
   
   localparam STG = DATA_WIDTH ; // similar bit width of vectors X and Y
   
   input            clock;
   
   input  signed    [31:0] angle;
   input  signed    [DATA_WIDTH -1:0] Amp;
   input  signed    [DATA_WIDTH -1:0] Phase_shift;
   output signed    [DATA_WIDTH :0] Cos_out;
   output signed    [DATA_WIDTH :0] Sin_out;
   
   //arctan_table
   
   // Note: The atan_table was chosen to be 31 bits wide giving resolution up to atan(2^-30)
   wire signed [31:0] atan_table [0:30];
   
   // upper 2 bits = 2'b00 which represents 0 - PI/2 range
   // upper 2 bits = 2'b01 which represents PI/2 to PI range
   // upper 2 bits = 2'b10 which represents PI to 3*PI/2 range (i.e. -PI/2 to -PI)
   // upper 2 bits = 2'b11 which represents 3*PI/2 to 2*PI range (i.e. 0 to -PI/2)
   // The upper 2 bits therefore tell us which quadrant we are in.
   assign atan_table[00] = 32'b00100000000000000000000000000000; // 45.000 degrees -> atan(2^0)
   assign atan_table[01] = 32'b00010010111001000000010100011101; // 26.565 degrees -> atan(2^-1)
   assign atan_table[02] = 32'b00001001111110110011100001011011; // 14.036 degrees -> atan(2^-2)
   assign atan_table[03] = 32'b00000101000100010001000111010100; // atan(2^-3)
   assign atan_table[04] = 32'b00000010100010110000110101000011;
   assign atan_table[05] = 32'b00000001010001011101011111100001;
   assign atan_table[06] = 32'b00000000101000101111011000011110;
   assign atan_table[07] = 32'b00000000010100010111110001010101;
   assign atan_table[08] = 32'b00000000001010001011111001010011;
   assign atan_table[09] = 32'b00000000000101000101111100101110;
   assign atan_table[10] = 32'b00000000000010100010111110011000;
   assign atan_table[11] = 32'b00000000000001010001011111001100;
   assign atan_table[12] = 32'b00000000000000101000101111100110;
   assign atan_table[13] = 32'b00000000000000010100010111110011;
   assign atan_table[14] = 32'b00000000000000001010001011111001;
   assign atan_table[15] = 32'b00000000000000000101000101111101;
   assign atan_table[16] = 32'b00000000000000000010100010111110;
   assign atan_table[17] = 32'b00000000000000000001010001011111;
   assign atan_table[18] = 32'b00000000000000000000101000101111;
   assign atan_table[19] = 32'b00000000000000000000010100011000;
   assign atan_table[20] = 32'b00000000000000000000001010001100;
   assign atan_table[21] = 32'b00000000000000000000000101000110;
   assign atan_table[22] = 32'b00000000000000000000000010100011;
   assign atan_table[23] = 32'b00000000000000000000000001010001;
   assign atan_table[24] = 32'b00000000000000000000000000101000;
   assign atan_table[25] = 32'b00000000000000000000000000010100;
   assign atan_table[26] = 32'b00000000000000000000000000001010;
   assign atan_table[27] = 32'b00000000000000000000000000000101;
   assign atan_table[28] = 32'b00000000000000000000000000000010;
   assign atan_table[29] = 32'b00000000000000000000000000000001; // atan(2^-29)
   assign atan_table[30] = 32'b00000000000000000000000000000000;
   
   //------------------------------------------------------------------------------
   //                              registers
   //------------------------------------------------------------------------------
   
   //stage outputs
   reg signed [DATA_WIDTH :0] X [0:STG-1];
   reg signed [DATA_WIDTH :0] Y [0:STG-1];
   reg signed    [31:0] Z [0:STG-1]; // 32bit
   
   //------------------------------------------------------------------------------
   //                               stage 0
   //------------------------------------------------------------------------------
   wire                 [1:0] quadrant;
   assign   quadrant = angle[31:30];
   
   always @(posedge clock)
   begin // make sure the rotation angle is in the -pi/2 to pi/2 range.  If not then pre-rotate
      case (quadrant)
         2'b00,
         2'b11:   // no pre-rotation needed for these quadrants
         begin    // X[n], Y[n] is 1 bit larger than Amp, Phase_shift, but Verilog handles the assignments properly
            X[0] <= Amp;
            Y[0] <= Phase_shift;
            Z[0] <= angle;
         end
         
         2'b01:
         begin
            X[0] <= -Phase_shift;
            Y[0] <= Amp;
            Z[0] <= {2'b00,angle[29:0]}; // subtract pi/2 from angle for this quadrant
         end
         
         2'b10:
         begin
            X[0] <= Phase_shift;
            Y[0] <= -Amp;
            Z[0] <= {2'b11,angle[29:0]}; // add pi/2 to angle for this quadrant
         end
         
      endcase
   end
   
   //------------------------------------------------------------------------------
   //                           generate stages 1 to STG-1
   //------------------------------------------------------------------------------
   genvar i;

   generate
   for (i=0; i < (STG-1); i=i+1)
   begin: XYZ
      wire                   Z_sign;
      wire signed  [DATA_WIDTH :0] X_shr, Y_shr; 
   
      assign X_shr = X[i] >>> i; // signed shift right
      assign Y_shr = Y[i] >>> i;
   
      //the sign of the current rotation angle
      assign Z_sign = Z[i][31]; // Z_sign = 1 if Z[i] < 0
   
      always @(posedge clock)
      begin
         // add/subtract shifted data
         X[i+1] <= Z_sign ? X[i] + Y_shr         : X[i] - Y_shr;
         Y[i+1] <= Z_sign ? Y[i] - X_shr         : Y[i] + X_shr;
         Z[i+1] <= Z_sign ? Z[i] + atan_table[i] : Z[i] - atan_table[i];
      end
   end
   endgenerate
   
   
   //------------------------------------------------------------------------------
   //                                 output
   //------------------------------------------------------------------------------
   assign Cos_out = X[STG-1];
   assign Sin_out = Y[STG-1];


   endmodule
