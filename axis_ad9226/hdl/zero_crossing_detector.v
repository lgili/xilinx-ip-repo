module zero_crossing_detector(clk,
									rst, 
									in_data, 
									in_data_valid, 
									in_counter_pos,
									out_data_valid, 
									out_number_samples,
									out_data,
									int_start,
									int_stop,
									config_reg,
									out_zcd_first_pos,
									out_zcd_last_pos,
									save
									);
									
parameter DATA_WIDTH = 46;			
parameter REG_WIDTH = 32;
parameter BLACK_TIME = 10000; // Time in which zero cross detector ignores changes in polarity of the signal (if goes frm positive to negative)

// ======================
// Variable Section
// ======================

input wire clk;
input wire  rst;
input wire						in_data_valid;
input wire [DATA_WIDTH-1:0]	in_data;
input wire [REG_WIDTH-1:0] 	config_reg;
input wire [REG_WIDTH-1:0] 	 in_counter_pos;

output reg out_data_valid;
output reg [REG_WIDTH-1:0] out_number_samples;
output wire [DATA_WIDTH-1:0] out_data;
output wire [31:0]  out_zcd_first_pos;
output wire [31:0]  out_zcd_last_pos;

output reg int_start; // Used to trigger the integrators for RMS value and Energy
output reg int_stop; 
output reg save;

// ======================
// Code Section
// ======================	

wire signed [DATA_WIDTH-1:0] signed_in_data;

reg flag_neg = 0;
reg [REG_WIDTH-1:0] cnt, acc_cnt;

parameter idle = 0, samples_cnt = 1, cnt_periods = 2, cnt_data_out = 3;								
reg [1:0] state;

reg  [7:0] cnt_waveform_periods;
wire [7:0] save_periods;
wire [7:0] jump_periods;
wire       filter_rst;
reg firsTime;
reg sigZeroCross;
wire signed [11:0] zero_value;

reg [31:0] first;
reg [31:0] last;
reg [31:0] countWaves;


assign signed_in_data = in_data;
assign save_periods = config_reg[19:12];
assign jump_periods = config_reg[27:20];
assign filter_rst = config_reg[31];
assign zero_value = config_reg[11:0];

assign out_data = (out_data_valid == 1) ? {1'b1 , in_data[DATA_WIDTH-2:0]} : in_data;
assign out_zcd_first_pos = (first == 0) ? out_zcd_first_pos : first;
assign out_zcd_last_pos = (last == 0) ? out_zcd_last_pos : last;

always@(posedge clk) begin 
if(rst == 0 || filter_rst || in_counter_pos == 0) begin 		
		first <= 0;
		last <= 0;
		
end
end

always@(posedge clk) begin 
	if(rst == 0 || filter_rst) begin 
		state <= idle;
		countWaves <= 0;		
	end 
	else begin 
		if(state == idle) begin 
			if(signed_in_data >= zero_value) 
				state <= samples_cnt;
			else 
				state <= idle;
		end 
		else if (state == samples_cnt) begin 
			if(flag_neg && cnt >= BLACK_TIME && signed_in_data >= zero_value) 
				state <= cnt_periods;
			else 
				state <= samples_cnt;
		end 
		else if (state == cnt_periods) begin 
			if(cnt_waveform_periods >= (save_periods-1)) 
				state <= cnt_data_out;
			else state <= samples_cnt;
		end
		else if (state == cnt_data_out) begin 
			state <= idle;
		end 
 	end
end					
		
always@(posedge clk) begin 
	if(rst == 0 || filter_rst) begin 
		out_number_samples <= 0;
		cnt_waveform_periods <= 0;
		acc_cnt <= 0;
		int_start <= 1'b0;
		int_stop <= 1'b0;
	end 
	else begin 
		if(state == idle) begin 
			if(signed_in_data >= zero_value) begin
				int_start <= 1'b1;
				if(first == 0 && last == 0) begin
					first <= in_counter_pos;
				end
				else if(last == 0) begin
					last <= in_counter_pos;
				end
				    
			end
			else begin
				    sigZeroCross <= 1'b0;
				    int_start <= 1'b0;
			end 
			 
				
				
			int_stop <= 1'b0;
			cnt <= 0;
			out_data_valid <= 1'b0;			
			cnt_waveform_periods <= 0;
			acc_cnt <= 0;
			flag_neg <= 0;
		end 
		else if (state == samples_cnt) begin
			if(signed_in_data < zero_value && cnt > BLACK_TIME) begin
				flag_neg <= 1'b1;
			end
			cnt <= cnt + 1;
			out_data_valid <= 1'b0;
			int_start <= 1'b0;
			int_stop <= 1'b0;
		end 
		else if (state == cnt_periods) begin 
			if(cnt_waveform_periods >= (save_periods-1)) begin 
				int_stop <= 1'b1;
				
			end
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
			
			/*if(first == 0 && last == 0) begin
			     first <= in_counter_pos;
			end
			else if(last == 0) begin
			     last <= in_counter_pos;
			end*/
		end 
	end
end	



always@(posedge int_start) begin
	countWaves <= countWaves +1;

	if(countWaves < 1)
		save <= 1;
	else if (countWaves < jump_periods)
		save <= 0;
	else 
		countWaves <= 0;


end

endmodule 
										
										