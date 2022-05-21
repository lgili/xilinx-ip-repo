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

module comb
/*********************************************************************************************/
#(parameter DATA_IN_WIDTH = 8, DATA_OUT_WIDTH = 9, DIFFERENCIAL_DELAY = 1)
/*********************************************************************************************/
(
    input   clk,
    input   reset_n,
    input   in_dv,
    input   signed [DATA_IN_WIDTH-1:0] data_in,
    output  reg signed [DATA_OUT_WIDTH-1:0] data_out
);
/*********************************************************************************************/
reg signed [DATA_IN_WIDTH-1:0] data_reg[DIFFERENCIAL_DELAY];
integer i;
/*********************************************************************************************/
always_ff @(posedge clk)
begin
    if (!reset_n) begin
        for (i=0;i<DIFFERENCIAL_DELAY;i++)
            data_reg[i] <= '0;
        data_out <= '0;
    end
    else if (in_dv) begin
        data_reg[0] <= data_in;
        for (i=1;i<DIFFERENCIAL_DELAY;i++)
            data_reg[i] <= data_reg[i-1];
        data_out <= data_in - data_reg[DIFFERENCIAL_DELAY-1];
    end
end
/*********************************************************************************************/
endmodule