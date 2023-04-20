
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

module qmath#
(
    parameter DATA_WIDTH = 8,
    parameter FRACTIONAL_WIDTH = 4
)
(
    input wire Clk,
    input wire Resetn,

    input signed  [DATA_WIDTH-1:0] sum_a,
    input signed  [DATA_WIDTH-1:0] sum_b,
    output wire signed [DATA_WIDTH-1:0] result_sum,
    output wire signed [DATA_WIDTH-1:0] result_mul

);

localparam real GAIN = 2.001;
wire ovr;
reg signed [2*DATA_WIDTH-1:0] mp ;

// adder
qmult #
(   .Q(FRACTIONAL_WIDTH),
    .N(DATA_WIDTH)
) mult
(
    .i_multiplicand(sum_b), 
    .i_multiplier(sum_a), 
    .o_result(result_mul),
    .ovr(ovr)
);

// mull
// qadd #
// (   .Q(FRACTIONAL_WIDTH),
//     .N(DATA_WIDTH)
// ) adder
// (
//     .a(sum_a), 
//     .b(sum_b), 
//     .c(result_sum)
// );

assign mp =  GAIN;
assign result_sum = sum_b + sum_a;




endmodule