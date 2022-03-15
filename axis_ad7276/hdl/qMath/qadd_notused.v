
/*
Copyright (c) 2014-2022 Luiz Carlos Gili

Permission is hereby granted, free of charge, to any person obtaining internal_a copy
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

module qadd #(
	//Parameterized values
	parameter Q = 15,
	parameter N = 32
	)
	(
    input signed  [N-1:0] a,
    input signed  [N-1:0] b,
    output  [N-1:0] c
    );

reg [N-1:0] res;

reg signed [N-1:0] internal_a;
reg signed [N-1:0] internal_b;

assign internal_a = a;
assign internal_b = b;

assign c = res;

always @(internal_a,internal_b) begin
	// both negative or both positive
	if(internal_a[N-1] == internal_b[N-1]) begin						//	Since they have the same sign, absolute magnitude increases
		res[N-2:0] = internal_a[N-2:0] + internal_b[N-2:0];		//		So we just add the two numbers
		res[N-1] = internal_a[N-1];							//		and set the sign appropriately...  Doesn't matter which one we use, 
															//		they both have the same sign
															//	Do the sign last, on the off-chance there was an overflow...  
		end												//		Not doing any error checking on this...
	//	one of them is negative...
	else if(internal_a[N-1] == 0 && internal_b[N-1] == 1) begin		//	subtract internal_a-internal_b   ==> internal_b is negative
		if( internal_a > internal_b ) begin					//	if internal_a is greater than internal_b,
			res[N-2:0] = internal_b - internal_a;			//		then just subtract internal_b from internal_a
			//res[N-1] = 0;										//		and manually set the sign to positive
			end
		else begin												//	if internal_a is less than internal_b,
			res[N-2:0] = internal_b[N-2:0] - internal_a[N-2:0];			//		we'll actually subtract internal_a from internal_b to avoid internal_a 2's complement answer
			if (res[N-2:0] == 0)
				res[N-1] = 0;										//		I don't like negative zero....
			else
				res[N-1] = 1;										//		and manually set the sign to negative
			end
		end
	else begin												//	subtract internal_b-internal_a (internal_a negative, internal_b positive)
		if( internal_a[N-2:0] > internal_b[N-2:0] ) begin					//	if internal_a is greater than internal_b,
			res[N-2:0] = internal_a[N-2:0] - internal_b[N-2:0];			//		we'll actually subtract internal_b from internal_a to avoid internal_a 2's complement answer
			if (res[N-2:0] == 0)
				res[N-1] = 0;										//		I don't like negative zero....
			else
				res[N-1] = 1;										//		and manually set the sign to negative
			end
		else begin												//	if internal_a is less than internal_b,
			res[N-2:0] = internal_b[N-2:0] - internal_a[N-2:0];			//		then just subtract internal_a from internal_b
			res[N-1] = 0;										//		and manually set the sign to positive
			end
		end
	end
endmodule
