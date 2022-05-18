module passband_filter(rst,
							clk,
							in_data_valid,
							in_data,
							out_data_valid,
							out_data_filter
							);
input wire rst;
input wire clk;
input wire in_data_valid;
input wire signed [15:0] in_data;

output reg out_data_valid;

output wire [15:0] out_data_filter;

reg [45:0] out_data;

reg signed [32:0] b0 = 33'd28633; //33'd28633; 
reg signed [32:0] b1 = 33'd0; //33'd0;
reg signed [32:0] b2 = -33'd28633; //-33'd28633;
reg signed [34:0] a1 = -35'd8589876241;//-35'd8589876241; //sum at the equationing
reg signed [34:0] a2 = 35'd4294910030; //35'd4294910030;

reg signed [15:0] x_n = 0;
reg signed [15:0] x_n1 = 0;
reg signed [15:0] x_n2 = 0;

reg signed [48:0] y_n = 0;
reg signed [48:0] y_n1 = 0;
reg signed [48:0] y_n2 = 0;

assign out_data_filter = out_data[45:30];
					
						
reg signed [83:0] ya1 = 0,
						ya2 = 0,
						y_a1_q84 = 0,
						y_a2_q84 = 0;

reg signed [48:0] ya1_q47 = 0, ya2_q47 = 0;
						
reg signed [48:0] xb0 = 0, xb1 = 0, xb2 = 0;

always@(posedge clk) begin 
	if(rst == 0) begin
		out_data_valid <= 1'b0;	
		x_n <= 0;	
		x_n1 <= 0;
		x_n2 <= 0;
		y_n1 <= 0;
		y_n2 <= 0;
	end 
	else begin 
		if(in_data_valid) begin 
			out_data_valid <= 1'b1;
			x_n <= in_data;
			out_data <= y_n;
			
			x_n1 <= x_n;
			x_n2 <= x_n1;
			y_n1 <= y_n;
			y_n2 <= y_n1;
		end 
		else begin 
			out_data_valid <= 1'b0;
		end
	end 
end

// Multiplication of the input variables x[n], x[n-1] and x[n-2] in the format of Q1.15 
// by Q1.32 coefficients b0, b1 and b2.
//    Q2.32 coefficients a0 a1
// The result is Q3.47
always@* begin 
	xb0 <= x_n * b0;
	xb1 <= x_n1 * b1;
	xb2 <= x_n2 * b2;
end

// The output y[n] is in Q2.47
always@* begin 
	//	
	ya1 <= (y_n1 * a1); // Q2.47 * Q3.32 = Q5.79. 
	ya2 <= (y_n2 * a2);
	
	// Converter Q5.79 para Q2.47
	y_a1_q84 <= ya1 << 3;
	ya1_q47 <= y_a1_q84[83:83-48];
	
	y_a2_q84 <= ya2 << 3;
	ya2_q47 <= y_a2_q84[83:83-48];
	
	// This data is in Q2.47 format
	y_n <= xb0 + xb1 + xb2 - ya1_q47 - ya2_q47; 
	
end

endmodule
