module passband_filter_tb();
					
reg rst;
reg clk;
reg in_data_valid;
reg [15:0] in_data_a, in_data_b;
wire out_data_valid;
wire [45:0] out_data;

integer sin_data;
integer cos_data;
integer statusI, statusId, n;

reg [31:0] config_reg;

	passband_filter_new dut(.rst(rst),
							.clk(clk),
							.in_data_valid(in_data_valid),
							.in_data(in_data_a),
							.out_data_valid(out_data_valid),
							.out_data(out_data),
							.in_coeff_a1(-32'd1073738109),
							.in_coeff_a2(32'd536867332),
							.in_coeff_b0(32'd1789),
							.in_coeff_b2(-32'd1789),
							.config_reg(config_reg)
							);



wire [31:0] out_number_samples;
wire out_number_samples_valid;
wire int_start;
wire int_stop;

wire [63:0] out_data_rms_value, out_data_energy_value, out_data_average_value;
wire [31:0] out_data_N_rms_value, out_data_N_energy_value;
wire out_data_valid_rms_value;
wire out_data_valid_energy_value;

reg [31:0] cc_cnt;

reg int_start_cc;
reg int_stop_cc;

reg power_sel;

zero_crossing_detector			#(.DATA_WIDTH(46))
											zcd_dut
											(.clk(clk),
											.rst(rst),
											.in_data_valid(out_data_valid),
											.in_data(out_data), 
											.out_data_valid(out_number_samples_valid),
											.out_number_samples(out_number_samples),
											.int_start(int_start),
											.int_stop(int_stop),
											.config_reg(config_reg)
											);

										// generate int_start and int_stop for cc measurement
						
											
				
varible_integrator rms_value
					  (.clk(clk), 
						.rst(rst),
						.in_data(in_data_a),
						.in_data_valid(in_data_valid),
						.out_data_rms(out_data_rms_value),
						.out_data_average(out_data_average_value),
						.out_data_N(out_data_N_rms_value),
						.out_data_valid(out_data_valid_rms_value),
						.int_start(int_start_cc),
						.int_stop(int_stop_cc)
						);
								
energy_integrator	energy_value
						(.clk(clk), 
						.rst(rst), 
						.in_data_valid(in_data_valid), 
						.in_data_a(in_data_a),
						.in_data_b(in_data_b),
						.out_data_valid(out_data_valid_energy_value), 
						.out_data(out_data_energy_value),
						.out_data_N(out_data_N_energy_value),
						.int_start(int_start),
						.int_stop(int_stop)
						);			
											
initial begin 
	clk = 0;
	rst = 1;
	power_sel = 1;
	in_data_valid = 0;
	in_data_a = 0;
	in_data_b = 0;
	config_reg = 0;
	config_reg[7:0] = 1;
	config_reg[31] = 1;
	#10 
		rst = 0;
	
	#20 config_reg[30] = 1;
	#20 config_reg[30] = 0;
		config_reg[31] = 0;
	
	sin_data = $fopen("/home/lgili/Documents/FPGA/marciomoura-tcc-fpga/DE10_NANO_SoC_GHRD/design_files/sin_60hz_wnoise.txt","r");
	cos_data = $fopen("/home/lgili/Documents/FPGA/marciomoura-tcc-fpga/DE10_NANO_SoC_GHRD/design_files/cos_60hz.txt","r");

	
end 

always
	#5 clk = !clk;

initial begin
	repeat (10) @(posedge clk);
	while(1) begin 
		@(posedge clk);
		in_data_valid = 1;
		statusI = $fscanf(sin_data,"%d \n",in_data_a[15:0]); 
		statusId= $fscanf(cos_data,"%d \n",in_data_b[15:0]); 
		@ (posedge clk);
		in_data_valid = 0;
		
		if($feof(sin_data))
		begin 
			sin_data = $fopen("/home/lgili/Documents/FPGA/marciomoura-tcc-fpga/DE10_NANO_SoC_GHRD/design_files/sin_60hz_wnoise.txt","r");
			cos_data = $fopen("/home/lgili/Documents/FPGA/marciomoura-tcc-fpga/DE10_NANO_SoC_GHRD/design_files/cos_60hz.txt","r");
		end 
	end
	repeat(10) @(posedge clk);
	$fclose(sin_data);
end 	






always@(posedge clk) begin 
	if(rst) begin 
		cc_cnt <= 0;
		int_start_cc <= 1'b0;
		int_stop_cc <= 1'b0;
	end 
	else begin 
		if(power_sel) begin 
			if(cc_cnt == 32'd24000) begin 
				int_stop_cc <= 1'b1;
				int_start_cc <= 1'b0;
				cc_cnt <= 0;
			end
			else if(cc_cnt == 32'd1) begin 
				int_stop_cc <= 1'b0;
				cc_cnt <= cc_cnt + 32'd1;
				int_start_cc <= 1'b1;
			end
			else begin 
				cc_cnt <= cc_cnt + 32'd1;
				int_start_cc <= 1'b0;
				int_stop_cc <= 1'b0;
			end
		end
		else begin 
			int_start_cc <= 1'b0;
			int_stop_cc <= 1'b0;
			cc_cnt <= 0;
		end
	end
end					
	
	
	
	
	
	
	
endmodule