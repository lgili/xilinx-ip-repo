module trigger_acq_tb();

reg rst;
reg clk;

reg in_data_valid;

reg [15:0] in_data;
reg [15:0] trigger_level; 		// Register updated from HPS
wire [31:0] out_data_offset; 	// Register readed by the HPS
reg  [31:0] in_dma_master_address;
wire [15:0] trigger_response ;

	trigger_level #(.DATA_WIDTH(16),
	               .TWOS_COMPLEMENT(0))		
					trigger_dut
					(.rst(rst),
				    .clk(clk),
				    .in_data_valid(in_data_valid),
				    .in_data(in_data),
				    .trigger_level(trigger_level),
					 .in_dma_master_address(in_dma_master_address),
				    .out_data_offset(out_data_offset),
					 .trigger_response(trigger_response));
					 
	initial begin 
		clk = 0;
		rst = 1;
		in_dma_master_address = 100;
		in_data_valid = 0;

		in_data = 0;
	   trigger_level = 10000; 		// Register updated from HPS
		
		#10 rst = 0;
	end 
	
	reg [7:0] data_valid_counter = 0;
	
	always@(posedge clk) begin 
		if (data_valid_counter == 5) begin
			data_valid_counter <= 0;
			in_data_valid <= 1'b1;
		end 
		else begin 
			data_valid_counter <= data_valid_counter + 1;
			in_data_valid <= 1'b0;
		end
		
		if(in_data == 2045) begin 
			in_data <= 0;
		end
		else in_data <= in_data + 1;

	end
	
	always@(posedge clk) begin 
		if(rst) begin 
			in_dma_master_address <= 0;
		end 
		else begin 
			if(in_dma_master_address == 32'hffffffff)
				in_dma_master_address <= 0;
			else in_dma_master_address <= in_dma_master_address + 1;
		end
	end
	
	always
		#5 clk = !clk; 
					 	 
endmodule