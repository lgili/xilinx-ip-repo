module zero_crossing_detector_tb();

reg clk;
reg rst;
reg in_data_valid;
reg  [15:0] in_data;

wire out_data_valid;
wire [31:0] out_number_samples;
reg up;
reg down;
reg  [15:0] sawtooth;
reg [31:0] config_reg;
reg [31:0] counter;

wire cal_out_data_valid;
wire [15:0] cal_out_data;
wire [45:0] out_data;

passband_filter dut(.rst(rst),
							.clk(clk),
							.in_data_valid(in_data_valid),
							.in_data(in_data),
							.out_data_valid(),
							.out_data(out_data)
							
							);
							
zero_crossing_detector	zcd_dut	(.clk(clk),
.rst(rst),
.in_data_valid(in_data_valid),
.in_data(in_data), 
.in_counter_pos(counter),
.out_data_valid(out_data_valid),
.out_number_samples(out_number_samples),
.config_reg(config_reg),
.out_zcd_pos()
);

										
											
											
reg [7:0] cnt;									
	initial begin 
		clk = 0;
		rst = 0;
		cnt = 0;
		config_reg = 0;
		up = 1;
		down = 0;
		sawtooth = 0;
		
		config_reg[11:0] = 12'd2048;
		config_reg[19:12] = 8'd1;
		config_reg[31] = 1'b0;
		#20 rst = 1;
	end
	
	always 
		#10 clk = !clk;
		

	always@(posedge clk) begin 
		if(!rst) begin
		    //counter <= counter + 1;
		    //if(counter == 100000)
		    //      counter <=0;  
			if(sawtooth == 5000) begin 
				down <= 1;
				up <= 0;
				sawtooth <= sawtooth -1;
			end 
			else if (sawtooth == 0) begin 
				up <= 1;
				down <= 0;
				sawtooth <= sawtooth + 1;
			end 
			else begin 
				if(up) 
					sawtooth <= sawtooth + 1;
				else if (down) 
					sawtooth <= sawtooth - 1;
			end 
		end
	end
										
	always@(posedge clk) begin 
		if(cnt == 5) begin 
			cnt <= 0;
			in_data_valid <= 1'b1;
			in_data <= sawtooth;
		end 
		else begin 
			cnt <= cnt + 1;
			in_data_valid <= 1'b0;
		end
	end
endmodule 