module moving_average_fir
(
	input wire clk, 
	input wire rst, 
	input wire [31:0] mavg_factor,
	input wire in_data_valid, 
	(* mark_debug = "true", keep = "true" *)
	input wire [IN_DATA_WIDTH-1:0] in_data, 
	output reg out_data_valid, 
	(* mark_debug = "true", keep = "true" *)
	output reg [OUT_DATA_WIDTH-1:0]out_data
);

// =====================
// Parameter Section
// =====================			

parameter IN_DATA_WIDTH = 12;
parameter OUT_DATA_WIDTH = 16;


reg [IN_DATA_WIDTH-1:0] din_cnt = 0;
reg signed [OUT_DATA_WIDTH-1:0] accumulator = 0;

wire signed_data_valid;
wire signed [IN_DATA_WIDTH-1:0] signed_in_data;
reg signed [OUT_DATA_WIDTH-1:0] signed_out_data;

// =====================
// Code Section
// =====================
		
assign signed_data_valid = in_data_valid;
assign signed_in_data = in_data;

always@* begin 
	out_data <= signed_out_data;
end


always@(posedge clk) begin 
	if(!rst) begin 
		out_data_valid <= 1'b0;
		signed_out_data <= 0;
	end
	else begin 
		if(mavg_factor == 0) begin  
			out_data_valid <= signed_data_valid;
			signed_out_data <= signed_in_data;
		end 
		else begin 
			if(signed_data_valid) begin 
				if(din_cnt == mavg_factor) begin 
					din_cnt <= 0;
					signed_out_data <= accumulator;
					accumulator <= signed_in_data;
					out_data_valid <= 1'b1;
				end
				else begin 
					din_cnt <= din_cnt + 1;
					accumulator <= accumulator+signed_in_data;
					out_data_valid <= 1'b0;
					signed_out_data <= out_data;
				end
			end
			else begin 
				out_data_valid <= 1'b0;
				signed_out_data <= out_data;
			end
		end
	end
end		
	


endmodule 