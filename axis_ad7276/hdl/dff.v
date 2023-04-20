`timescale 1ns/1ps
module dff(
			input wire D,		// input D
			input wire clk,		// input clk
			input wire rstn,	// reset (active low)
			output reg Q,		// output
			output wire Qb		// complementary output
		);

	assign Qb = ~Q;	
		
	always @(posedge clk, negedge rstn) begin
		if(!rstn) begin
			Q = 0;
		end
		else begin
			Q = D;
		end		
	end
endmodule