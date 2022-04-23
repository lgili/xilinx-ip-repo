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

// Addresses used : 
// base address + 0x00 : EnableSampleGeneration 	


`timescale 1 ns / 1 ps

module axi_clock_divider #
	(
		// Width of S_AXI data bus
		parameter integer AXI_DATA_WIDTH	= 32		
	)
	(
	    input wire clk,
	    input wire rstn,
	    input [AXI_DATA_WIDTH-1:0] clockDiv,
	    output reg clk_div
    );
	
localparam mainClock = 100_000_000;

wire [AXI_DATA_WIDTH-1:0] divider;
assign divider = (clockDiv == 0) ? 2 : (clockDiv >> 1) -1;
	

reg [AXI_DATA_WIDTH-1:0] count;
wire tc;

assign tc = (count == divider);	// Place a comparator on the counter output

always @ (posedge(clk), negedge(rstn))
begin
    if (!rstn) count <= 0;
    else if (tc) count <= 0;		// Reset counter when terminal count reached
    else count <= count + 1;
end

always @ (posedge(clk), negedge(rstn))
begin
    if (!rstn) clk_div <= 0;
    else if (tc) clk_div = !clk_div;	// T-FF with tc as input signal
end
endmodule


