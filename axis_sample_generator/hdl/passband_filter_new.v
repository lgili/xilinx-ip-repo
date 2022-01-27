module passband_filter_new(rst,
							clk,
							in_data_valid,
							in_data,
							out_data_valid,
							out_data,
							in_coeff_a1,
							in_coeff_a2,
							in_coeff_b0,
							in_coeff_b2,
							config_reg
							);
							
// ======================
// Input and Output Ports
// ======================	

input rst;
input clk;
input in_data_valid;
input wire signed [15:0] in_data;

input [31:0] in_coeff_a1;
input [31:0] in_coeff_a2;
input [31:0] in_coeff_b0;
input [31:0] in_coeff_b2;
input [31:0] config_reg;

output reg out_data_valid;
output reg [45:0] out_data;

// ======================
// Variable Declaration
// ======================

reg signed [31:0] b0; //32'd1789;  
reg signed [31:0] b2; //-32'd1789;
reg signed [31:0] a1; //-32'd1073738109; //sum at the equationing 
reg signed [31:0] a2; //32'd536867332; 

reg signed [15:0] x_n = 0;
reg signed [15:0] x_n1 = 0;
reg signed [15:0] x_n2 = 0;

reg signed [45:0] y_n = 0;
reg signed [45:0] y_n1 = 0;
reg signed [45:0] y_n2 = 0;		
						
reg signed [77:0] ya1 = 0,	 			//Q5.73
						ya2 = 0, 
						y_a1_q73 = 0,
						y_a2_q73 = 0;

reg signed [47:0] ya1_q44 = 0, ya2_q44 = 0;				
reg signed [47:0] xb0 = 0, xb2 = 0;

wire load_coeff;
wire filter_rst;

// ======================
// Code Starts Here
// ======================	

assign filter_rst = config_reg[31];
assign load_coeff = config_reg[30];


always@(posedge clk) begin 
	if(rst) begin 
		b0 <= 32'd0;
		b2 <= 32'd0;
		a1 <= 32'd0;
		a2 <= 32'd0;
	end 
	else begin 
		if(load_coeff) begin 
			b0 <= in_coeff_b0;
			b2 <= in_coeff_b2;
			a1 <= in_coeff_a1;
			a2 <= in_coeff_a2;
		end 
	end
end

// ======================
// Filter Section
// ======================	

//always@(posedge clk) begin 
//	x_n <= in_data;
//	out_data <= y_n;
//end 

always@(posedge clk) begin 
	if(rst || filter_rst) begin
		out_data_valid <= 1'b0;		
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
// by Q3.29 coefficients b0, b1 and b2.
// The result is Q4.44
always@* begin 
	xb0 <= x_n * b0;
	xb2 <= x_n2 * b2;
end

// The output y[n] is in Q2.47
always@* begin 
	//	
	ya1 <= (y_n1 * a1); // Old - Q2.47 * Q3.32 = Q5.79. 
	ya2 <= (y_n2 * a2); // New - Q2.44 * Q3.29 = Q5.73
	
	// Converter Q5.79 para Q2.47
	// Convert Q5.73 to Q4.44
	y_a1_q73 <= ya1 << 1;
	ya1_q44 <= y_a1_q73[77:77-47];
	
	y_a2_q73 <= ya2 << 1;
	ya2_q44 <= y_a2_q73[77:77-47];
	
	// This data is in Q4.44 format
	y_n <= xb0 + xb2 - ya1_q44 - ya2_q44; 
end

endmodule
