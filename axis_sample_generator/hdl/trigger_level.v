module trigger_level (rst,
						 clk,
						 in_data_valid,
						 in_data,
						 in_dma_master_address,
						 trigger_level,
						 trigger_response,
						 out_data_offset,
						 trigger
						 );

// ======================
// Parameters
// ======================							 
						 
parameter DATA_WIDTH = 16;			 
parameter MEMORY_ADDR_LEN = 32;
parameter TWOS_COMPLEMENT = 0; // True if 1 - if not using 2`s complement then 0

// ======================
// Input and Output Ports
// ======================							 
						 
input rst;
input clk;
input in_data_valid;
input [DATA_WIDTH-1:0] in_data;
input [DATA_WIDTH-1:0] trigger_level; // HPS Register
input [MEMORY_ADDR_LEN-1:0] in_dma_master_address;

output wire trigger;
output reg [31:0] out_data_offset; // HPS Register 
output reg [15:0] trigger_response; // HPS Register 

// ======================
// Variable Declaration
// ======================

wire [DATA_WIDTH-1:0] trigger_level_value;

reg [15:0] cnt;
reg trigger_cnt_rst;
reg unsigned_data_valid;
reg trigger_acq_en = 1'b0;
wire [DATA_WIDTH-1:0] unsigned_in_data;
reg [DATA_WIDTH-1:0] unsigned_in_data_conv;
reg [31:0] data_offset;
reg tg_test;
// ======================
// Code Starts Here
// ======================	

// Convert Two's Complement to Unsigned 
always@(posedge clk) begin 
	if(rst) begin 
		unsigned_data_valid <= 1'b1;
		unsigned_in_data_conv <= 0;
	end 
	else begin 
		if(in_data_valid) begin 
			unsigned_data_valid <= 1'b1;
			if(in_data >= 16'h8000) begin
				unsigned_in_data_conv <= ~in_data + 16'b1;
			end
			else begin 
				unsigned_in_data_conv <= in_data + 16'h8000;
			end
		end
		else begin
			unsigned_data_valid <= 1'b0;
		end
	end	
end

assign unsigned_in_data = (TWOS_COMPLEMENT == 1) ? unsigned_in_data_conv : in_data;
assign trigger_level_value = (trigger_level == 0) ? 5 : trigger_level;  
assign trigger = (cnt == 5) ? 1 : 0;

// Trigger Identification 

always@(posedge clk) begin
	if(rst) begin 
		trigger_acq_en <= 1'b1;
		trigger_response <= 16'd0;
		trigger_cnt_rst <= 1'b0;
		data_offset <= 0;
		tg_test <= 0;
	end 
	else begin 
		trigger_response <= 16'd1;
		if(unsigned_data_valid) begin	// Counter to set offset number
			if(unsigned_in_data >= trigger_level_value && trigger_acq_en) begin // Trigger Comparison
				data_offset <= in_dma_master_address;
				trigger_acq_en <= 1'b0;
				tg_test <= 1'b1;	
						
			end
			else if(unsigned_in_data < trigger_level_value) begin 
				tg_test <= 1'b0;
				trigger_acq_en <= 1'b1;
				
			end
		end
	end
end

// This counter prevents data being triggered falsely
// Check for 3 new packets if the data still is up. Otherwise throws 0 at the output

always@(posedge clk) begin 
	if(rst) begin 
		cnt <= 16'd0;
		out_data_offset <= 0;
	end
	else begin 
		if(tg_test) begin 
			if(unsigned_in_data) begin 
				if(cnt == 6) begin 
					cnt <= 6;
					if(unsigned_in_data >= trigger_level_value) begin 
						out_data_offset <= data_offset;						
					end
				end
				else begin 
					cnt <= cnt + 1;					
				end
			end
		end
		else begin 
			cnt <= 0;
			
		end
	end
end


endmodule 