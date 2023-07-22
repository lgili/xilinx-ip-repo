module trigger_acq#(
parameter DATA_WIDTH = 16,			 
parameter MEMORY_ADDR_LEN = 32
) (
                input                           rstn,
				input                           clk,
                input                           in_data_valid,
				input [DATA_WIDTH-1:0]		    in_data,
				input [MEMORY_ADDR_LEN-1:0]     in_dma_master_address,
				input [DATA_WIDTH-1:0]		    trigger_level,    // HPS Register
				output reg [DATA_WIDTH-1:0]  	trigger_response, // HPS Register 
				output reg [MEMORY_ADDR_LEN-1:0] out_data_offset  // HPS Register 
);

// ======================
// Parameters
// ======================
localparam TWOS_COMPLEMENT = 1; // True if 1 - if not using 2`s complement then 0


// ======================
// Variable Declaration
// ======================

wire [DATA_WIDTH-1:0] trigger_level_value;

reg [15:0] cnt;
reg trigger_cnt_rst;
reg unsigned_data_valid;
reg trigger_acq_en = 1'b0;
reg [DATA_WIDTH-1:0] unsigned_in_data;
reg [31:0] data_offset;
reg tg_test;
// ======================
// Code Starts Here
// ======================	

// Convert Two's Complement to Unsigned 
// always@(posedge clk) begin 
// 	if(rst) begin 
// 		unsigned_data_valid <= 1'b1;
// 		unsigned_in_data <= 0;
// 	end 
// 	else begin 
// 		if(in_data_valid) begin 
// 			unsigned_data_valid <= 1'b1;
// 			if(in_data >= 16'h8000) begin
// 				unsigned_in_data <= ~in_data + 16'b1;
// 			end
// 			else begin 
// 				unsigned_in_data <= in_data + 16'h8000;
// 			end
// 		end
// 		else begin
// 			unsigned_data_valid <= 1'b0;
// 		end
// 	end	
// end

assign trigger_level_value = (trigger_level == 0) ? 5 : trigger_level;  

// Trigger Identification 

always@(posedge clk) begin
	if(!rstn) begin 
		trigger_acq_en <= 1'b1;
		trigger_response <= 16'd0;
		trigger_cnt_rst <= 1'b0;
		data_offset <= 0;
		tg_test <= 0;
	end 
	else begin 
		trigger_response <= 16'd1;
		if(in_data_valid) begin	// Counter to set offset number
			if(in_data >= trigger_level_value && trigger_acq_en) begin // Trigger Comparison
				data_offset <= in_dma_master_address;
				trigger_acq_en <= 1'b0;
				tg_test <= 1'b1;
			end
			else if(in_data < trigger_level_value) begin 
				tg_test <= 1'b0;
				trigger_acq_en <= 1'b1;
			end
		end
	end
end

// This counter prevents data being triggered falsely
// Check for 3 new packets if the data still is up. Otherwise throws 0 at the output

always@(posedge clk) begin 
	if(!rstn) begin 
		cnt <= 16'd0;
		out_data_offset <= 0;
	end
	else begin 
		if(tg_test) begin 
			if(in_data) begin 
				if(cnt == 12) begin 
					cnt <= 12;
					if(in_data >= trigger_level_value) begin 
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