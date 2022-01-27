module trigger_level_signed(rst,
						 clk,
						 in_data_valid,
						 in_data,
						 in_dma_master_address,
						 trigger_level,
						 trigger_response,
						 out_data_offset
						 );
						 
// ======================
// Parameters
// ======================							 
						 
parameter DATA_WIDTH = 16;			 
parameter MEMORY_ADDR_LEN = 32;

// ======================
// Input and Output Ports
// ======================							 
						 
input rst;
input clk;

input in_data_valid;
input signed [DATA_WIDTH-1:0] in_data;

input signed [DATA_WIDTH-1:0] trigger_level;					
input [MEMORY_ADDR_LEN-1:0]	in_dma_master_address;

output reg [31:0] out_data_offset; 
output reg [15:0] trigger_response; 

reg signed [15:0] trigger_level_value;
reg trigger_acq_en;
// ======================
// Variable Declaration
// ======================

always@(posedge clk) begin 
	if(rst) begin 
		trigger_level_value <= 0;
	end 
	else begin 
		if(trigger_level > -16'd10)
			trigger_level_value <= trigger_level;
		else 
			trigger_level_value <= trigger_level + 16'd11;
	end
end

// Trigger Identification 

always@(posedge clk) begin
	if(rst) begin 
		trigger_acq_en <= 1'b1;
		trigger_response <= 16'd0;
		out_data_offset <= 0;
	end 
	else begin 
		trigger_response <= 16'd1;
		if(in_data_valid) begin	// Counter to set offset number
			if(in_data >= trigger_level_value && trigger_acq_en) begin // Trigger Comparison
				out_data_offset <= in_dma_master_address;
				trigger_acq_en <= 1'b0;
			end
			else if(in_data < (trigger_level_value - 10)) begin 
				trigger_acq_en <= 1'b1;
			end
		end
	end
end

endmodule