module varible_integrator(clk, 
							rst,
							in_data,
							in_data_valid,
							out_data_rms,
							out_data_average,
							out_data_N,
							out_data_valid,
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
input signed [IN_DATA_WIDTH-1:0] in_data; 

output reg [OUT_DATA_WIDTH-1:0] out_data_rms;
output reg [OUT_DATA_WIDTH-1:0] out_data_average;
output reg [REG_DATA_WIDTH-1:0] out_data_N;
output reg out_data_valid;

// Integration Start & Stop Signals
input int_start;
input int_stop;


reg signed [OUT_DATA_WIDTH-1:0] rms_acc;
reg signed [OUT_DATA_WIDTH-1:0] average_acc;
reg [REG_DATA_WIDTH-1:0] N;
reg flag_cnt;

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
		rms_acc <= 0;
		average_acc <= 0;
		out_data_valid <= 0;
		out_data_rms <= 0;
		out_data_average <= 0;
		out_data_N <= 0;
		N <= 1;
	end 
	else begin 
		if(in_data_valid && flag_cnt && !int_stop) begin 
			rms_acc <= rms_acc + in_data*in_data; // store the quadratic value
			average_acc <= average_acc + in_data;
			N <= N + 1;
			out_data_valid <= 1'b0;
		end
		else if(int_stop) begin 
			out_data_rms <= rms_acc;
			out_data_average <= average_acc;
			out_data_N <= N;
			N <= 1;
			rms_acc <= 0;
			average_acc <= 0;
			out_data_valid <= 1'b1;
		end
	end
end

endmodule 