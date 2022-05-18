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

module data_decimation(
	input wire clk,
	input wire rst_n,
	output reg in_data_ready,
	input wire in_data_valid,
	(* mark_debug = "true", keep = "true" *)
	input wire [DATA_IN_WIDTH-1:0] in_data,
	input wire out_data_ready,
	output reg out_data_valid,
	(* mark_debug = "true", keep = "true" *)
	output reg [DATA_OUT_WIDTH-1:0] out_data,
	input wire [DATA_REG_WIDTH-1:0] decimate_reg
);

parameter DATA_IN_WIDTH = 12;	
parameter DATA_OUT_WIDTH = 12;
parameter DATA_REG_WIDTH = 32;
							  
   

reg [DATA_REG_WIDTH-1:0] cnt;
reg data_valid_mask = 0;

always@(posedge clk) begin 
	if(rst_n == 0) begin 
		out_data <= 0;
		cnt <= 0;
	end
	else begin 
		if(out_data_ready) begin 
			if(in_data_valid) begin
				if(cnt == decimate_reg) begin 
					cnt <= 0;
					out_data <= in_data;
				end
				else begin 
					cnt <= cnt + 1;
				end
			end
		end
		else begin
			cnt <= 0;
			out_data <= 0;
		end
	end
end



always@(posedge clk) begin 
	if(rst_n == 0 || !out_data_ready) begin 
		out_data_valid <= 1'b0;
	end
	else begin 
		in_data_ready <= 1'b1;
		if( in_data_valid && cnt == decimate_reg) begin 
			out_data_valid <= 1'b1;
			data_valid_mask <= 1'b1;
		end
		else if (data_valid_mask) begin 
			out_data_valid <= 1'b0;
			data_valid_mask <= 1'b0;
		end
	end	
end

endmodule 
