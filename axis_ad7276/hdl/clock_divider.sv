// Copyright 2023 lgili
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`timescale 1ns/1ps
// reset generator
// output reg rst2_n;
// reg [1:0] sync_reset_n;
// always @ (posedge clk_rx) begin
//   sync_reset_n[1:0] <= {sync_reset_n[0], rst_n};
//   rst2_n            <= &sync_reset_n ; //AND BIT reduction
// end
module clock_divider#(
						parameter DIV_WIDTH = 2    							// Number of divider
					) (
						input wire 					clk_in,					// clock in
						input wire [DIV_WIDTH-1:0]	div_ctrl,				// divider control
						input wire 					rstn,					// reset (active low)
						output reg					clk_out,			    // clock out
						output reg 					clk_out_b				// complementary clock out
					);
	
	wire [DIV_WIDTH-1:0] clk_div;
	wire [DIV_WIDTH-1:0] clk_div_b;
	wire [DIV_WIDTH-1:0] d_in;
	
	/*
		Equation of clk divider:
		clk_out = clk_in / (2 * 2^div_crtl)
	*/
	
	always_comb begin
		clk_out = !rstn ? 0 : clk_div[div_ctrl];
		clk_out_b = !rstn ? 1 : clk_div_b[div_ctrl];
	end
	
	genvar i;
	generate
		for(i=0; i< DIV_WIDTH; i++) begin : CLK_DIV
			not INV(d_in[i], clk_div[i]);
			if(i==0) begin				
				dff D(
						.D(d_in[i]),
						.clk(clk_in),
						.rstn(rstn),
						.Q(clk_div[i]),
						.Qb(clk_div_b[i])
					);
			end
			else begin
				dff D(
						.D(d_in[i]),
						.clk(clk_div[i-1]),
						.rstn(rstn),
						.Q(clk_div[i]),
						.Qb(clk_div_b[i])
					);
			end
		end		
	endgenerate
endmodule	