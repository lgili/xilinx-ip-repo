module zero_crossing_detector(clk,
									rst, 
									in_data, 
									in_data_valid, 
									out_data_valid, 
									out_number_samples,
									int_start,
									int_stop,
									config_reg
									);
									
parameter DATA_WIDTH = 46;			
parameter REG_WIDTH = 32;
parameter BLACK_TIME = 100; // Time in which zero cross detector ignores changes in polarity of the signal (if goes frm positive to negative)

// ======================
// Variable Section
// ======================

input clk;
input rst;
input 						in_data_valid;
input [DATA_WIDTH-1:0]	in_data;
input [REG_WIDTH-1:0] 	config_reg;

output reg out_data_valid;
output reg [REG_WIDTH-1:0] out_number_samples;

output reg int_start; // Used to trigger the integrators for RMS value and Energy
output reg int_stop; 

// ======================
// Code Section
// ======================	

wire signed [DATA_WIDTH-1:0] signed_in_data;

reg flag_neg = 0;
reg [REG_WIDTH-1:0] cnt, acc_cnt;

parameter idle = 0, samples_cnt = 1, cnt_periods = 2, cnt_data_out = 3;								
reg [1:0] state;

reg  [7:0] cnt_waveform_periods;
wire [7:0] average_periods;
wire       filter_rst;

assign signed_in_data = in_data;
assign average_periods = config_reg[7:0];
assign filter_rst = config_reg[31];

always@(posedge clk) begin 
	if(rst || filter_rst) begin 
		state <= idle;
	end 
	else begin 
		if(state == idle) begin 
			if(signed_in_data >= 0) 
				state <= samples_cnt;
			else 
				state <= idle;
		end 
		else if (state == samples_cnt) begin 
			if(flag_neg && cnt >= BLACK_TIME && signed_in_data >= 0) 
				state <= cnt_periods;
			else 
				state <= samples_cnt;
		end 
		else if (state == cnt_periods) begin 
			if(cnt_waveform_periods >= (average_periods-1)) 
				state <= cnt_data_out;
			else state <= samples_cnt;
		end
		else if (state == cnt_data_out) begin 
			state <= idle;
		end 
 	end
end					
		
always@(posedge clk) begin 
	if(rst || filter_rst) begin 
		out_number_samples <= 0;
		cnt_waveform_periods <= 0;
		acc_cnt <= 0;
		int_start <= 1'b0;
		int_stop <= 1'b0;
	end 
	else begin 
		if(state == idle) begin 
			if(signed_in_data >= 0)
				int_start <= 1'b1;
			else 
				int_start <= 1'b0;
			int_stop <= 1'b0;
			cnt <= 0;
			out_data_valid <= 1'b0;			
			cnt_waveform_periods <= 0;
			acc_cnt <= 0;
			flag_neg <= 0;
		end 
		else if (state == samples_cnt) begin
			if(signed_in_data < 0 && cnt > BLACK_TIME)
				flag_neg <= 1'b1;
			cnt <= cnt + 1;
			out_data_valid <= 1'b0;
			int_start <= 1'b0;
			int_stop <= 1'b0;
		end 
		else if (state == cnt_periods) begin 
			if(cnt_waveform_periods >= (average_periods-1)) 
				int_stop <= 1'b1;
			else int_stop <= 1'b0;
			cnt_waveform_periods <= cnt_waveform_periods + 1;
			acc_cnt <= acc_cnt + cnt + 1;
			cnt <= 0; 
			flag_neg <= 0;
			out_data_valid <= 1'b0;	
			int_start <= 1'b0;
		end
		else if (state == cnt_data_out) begin 
			cnt <= 0;
			cnt_waveform_periods <= 0;
			out_data_valid <= 1'b1;
			out_number_samples <= acc_cnt;
			acc_cnt <= 0;
			flag_neg <= 0;
			int_start <= 1'b0;
			int_stop <= 1'b0;
		end 
	end
end	
									
endmodule 
										
										