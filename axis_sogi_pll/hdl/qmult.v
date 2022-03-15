
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

`timescale 1ns / 1ps

// now the multiply consider half bit are integer and half is fractionaries like q16.16
module qmult #(
//Parameterized values 
// FP_WIDTH = 24 ==> float in C
	parameter DATA_WIDTH = 32,
	parameter FP_WIDTH   = 24
)
(
	input	signed		[DATA_WIDTH-1:0]	a,
	input	signed		[DATA_WIDTH-1:0]	b,
	output	signed		[DATA_WIDTH-1:0]	result

);
	 
	reg signed [2*DATA_WIDTH-1:0] temp;

	assign temp = (a  * b);
	assign result = temp >> FP_WIDTH;



	// always @(posedge i_clk)
	// if (ce)
	// 	result <= in_one * in_two;

endmodule
