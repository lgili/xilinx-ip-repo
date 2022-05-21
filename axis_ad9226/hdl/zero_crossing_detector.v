module zero_crossing_detector(
	input wire clk,
	input wire clk_60hz,
	input wire rst, 
	(* mark_debug = "true", keep = "true" *)
	input wire [DATA_WIDTH-1:0]	 in_data, 
	input wire in_data_valid, 
	input wire [REG_WIDTH-3:0] in_counter_pos,
	input wire [REG_WIDTH-1:0] PacketSizeToStop,
	output reg out_data_valid, 
	output reg [REG_WIDTH-1:0] out_number_samples,
	output wire [DATA_WIDTH-1:0] out_data,
	(* mark_debug = "true", keep = "true" *)
	output reg int_start,
	output reg int_stop,
	(* mark_debug = "true", keep = "true" *)
	input wire [REG_WIDTH-1:0] config_reg,
	
	output wire [31:0] out_zcd_first_pos,
	output wire [31:0] out_zcd_last_pos,
	output wire save, 
	output wire debug
	
);
									
parameter DATA_WIDTH = 46;			
parameter REG_WIDTH = 32;
parameter BLACK_TIME = 100000; // Time in which zero cross detector ignores changes in polarity of the signal (if goes frm positive to negative)



// ======================
// Code Section
// ======================	

wire signed [DATA_WIDTH-1:0] signed_in_data;


reg flag_neg = 0;
reg [REG_WIDTH-1:0] cnt, acc_cnt;

parameter idle = 0, samples_cnt = 1, cnt_periods = 2, cnt_data_out = 3;								
reg [1:0] state;

reg  [7:0] cnt_waveform_periods;

wire       filter_rst;
reg firsTime;
reg sigZeroCross;
wire signed [11:0] zero_value;

reg [31:0] first;
reg [31:0] last;


(* mark_debug = "true", keep = "true" *)
reg [31:0] countWaves;
(* mark_debug = "true", keep = "true" *)
wire [7:0] save_periods;
(* mark_debug = "true", keep = "true" *)
wire [7:0] jump_periods;


wire tc_or_zcd;


assign signed_in_data = in_data;
assign save_periods = (config_reg[19:12] == 0) ? 2 : config_reg[19:12];
assign jump_periods = (config_reg[27:20] == 0) ? 30 : config_reg[27:20];
assign tc_or_zcd    = config_reg[28];
assign filter_rst = config_reg[31];
assign zero_value = config_reg[11:0];

assign out_data = (out_data_valid == 1) ? {1'b1 , in_data[DATA_WIDTH-2:0]} : in_data;
//assign out_zcd_first_pos = (first == 0) ? out_zcd_first_pos : first;
//assign out_zcd_last_pos = (last == 0) ? out_zcd_last_pos : last;

always@(posedge clk) begin 
if(rst == 0 || filter_rst || in_counter_pos == 0) begin 		
		first <= 0;
		last <= 0;		
end
end

always@(posedge clk) begin 
	if(rst == 0 || filter_rst) begin 
		state <= idle;
				
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




/*
wire tc, tc_b,onTrigger;
wire tc_60hz;

reg [REG_WIDTH-1:0] count_60Hz;
wire zcd_clk;

reg clk_at_trigger_freq;
assign tc_60hz = (count_60Hz == ((1_000_0 >> 1) -1));

always@(posedge clk_60hz, negedge rst) begin
 	if (!rst) count_60Hz <= 0;
    else if (tc_60hz) count_60Hz <=0;		// Reset counter when terminal count reached    
	else count_60Hz <= count_60Hz +1;	
end

always@(posedge clk_60hz, negedge rst) begin
 	if (!rst) clk_at_trigger_freq <= 0;
    else if (tc_60hz) clk_at_trigger_freq <= !clk_at_trigger_freq;		
end
*/

//assign tc = (countWaves < save_periods) ? 0: 1;

/*always@(posedge clk_at_trigger_freq, negedge rst) begin
 	if (!rst) countWaves <= 0;
    else if (tc) countWaves <=0;		// Reset counter when terminal count reached    
	else countWaves <= countWaves +1;	
end

always@(posedge clk_at_trigger_freq, negedge rst) begin
 	if (!rst) saved <= 0;
    else if (tc) saved <= !saved;		
end*/

//assign tc_b = (countWaves < (save_periods+jump_periods)) ? 0: 1;
//assign zcd_clk = int_start;

reg saved;
reg canSave;
always@(posedge clk) begin
 	if (!rst) begin
		countWaves <= 0;
		saved <= 0;
		canSave <= 1;
	 end	
    else begin 
		if(int_start == 1)
			countWaves <= countWaves +1;

		if(canSave == 1) begin
			if(countWaves < jump_periods)
				saved <= 0;
			else if (countWaves < (save_periods + jump_periods))
				saved <= 1;
			else begin
				saved <= 0;
				countWaves <= 0;
				if(in_counter_pos > PacketSizeToStop)
					canSave <= 0;
			end
		end	
		else if (in_counter_pos < PacketSizeToStop) begin
			canSave <= 1;
		end
	end    
		
end

assign save = saved;
//assign onTrigger = (tc_or_zcd) ? int_start : tc_60hz;
//assign debug = (tc_or_zcd) ? int_start : tc_60hz;







endmodule 
										
										