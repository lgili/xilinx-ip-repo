module energy_integrator(clk, 
							rst, 
							in_data_valid, 
							in_data_a,
							in_data_b,
							out_data_valid, 
							out_data,
							out_data_N,
							int_start,
							int_stop
							);
								
// =====================
// Parameter Section
// =====================			
		
parameter IN_DATA_WIDTH = 16;
parameter REG_DATA_WIDTH = 32;
parameter OUT_DATA_WIDTH = 64;	

// =====================
// Inout Section
// =====================

input clk;
input rst;
input in_data_valid;
input signed [IN_DATA_WIDTH-1:0] in_data_a; 
input signed [IN_DATA_WIDTH-1:0] in_data_b; 


output reg [OUT_DATA_WIDTH-1:0] out_data;
output reg [REG_DATA_WIDTH-1:0] out_data_N;
output reg out_data_valid;

// Integration Start & Stop Signals
input int_start;
input int_stop;

reg flag_cnt;
reg [REG_DATA_WIDTH-1:0] N;
reg signed [OUT_DATA_WIDTH-1:0] energy_ac;


// =====================
// Code Section
// =====================

always@(posedge clk) begin 
	if(rst) begin 
		flag_cnt <= 1'b0;
	end 
	else begin 
		if(int_start) begin 
			flag_cnt <= 1'b1;
		end
		else if(int_stop) begin 
			flag_cnt <= 1'b0;
		end
		else begin 
			flag_cnt <= flag_cnt;
		end
	end
end

always@(posedge clk) begin 
	if(rst) begin 
		energy_ac <= 0;
		out_data <= 0;
		out_data_N <= 0;
		out_data_valid <= 0;
		N <= 1;
	end
	else begin 
		if(in_data_valid && flag_cnt && !int_stop) begin 
			energy_ac <= energy_ac + in_data_a*in_data_b; // store the quadratic value
			N <= N + 1;
			out_data_valid <= 1'b0;
		end
		else if(int_stop) begin 
			out_data <= energy_ac;
			out_data_N <= N;
			N <= 1;
			energy_ac <= 0;
			out_data_valid <= 1'b1;
		end
	end
end

endmodule 