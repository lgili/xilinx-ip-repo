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


module downsampler
/*********************************************************************************************/
#(parameter DATA_WIDTH = 12, DECIMATION_RATIO = 4)
/*********************************************************************************************/
(
    input   clk,
    input   reset_n,
    input   signed [DATA_WIDTH-1:0] data_in,
    output  reg signed [DATA_WIDTH-1:0] data_out,
    output  reg dv
);
/*********************************************************************************************/
reg [$clog2(DECIMATION_RATIO)-1:0] counter;
/*********************************************************************************************/
always @(posedge clk)
begin
    if (!reset_n) begin
        counter <= 0;
        data_out <= 0;
        dv <= 1'b0;
    end
    else begin
        counter <= (counter < DECIMATION_RATIO-1) ? counter + 1 : 0;
        dv <= (counter == DECIMATION_RATIO-1);
        data_out <= (counter == DECIMATION_RATIO-1) ? data_in : data_out;
    end
end
/*********************************************************************************************/
endmodule