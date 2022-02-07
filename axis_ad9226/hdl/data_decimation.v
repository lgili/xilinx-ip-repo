module data_decimation(clk,
							  rst_n,
							  in_data_ready,
							  in_data_valid,
							  in_data,
							  out_data_ready,
							  out_data_valid,
							  out_data,
							  decimate_reg
							  );

parameter DATA_IN_WIDTH = 12;	
parameter DATA_OUT_WIDTH = 16;
parameter DATA_REG_WIDTH = 32;
							  
input 								clk;
input 								rst_n;
input 	  [DATA_REG_WIDTH-1:0]  	decimate_reg;
input 	  [DATA_IN_WIDTH-1:0]	    in_data;				// Input  ST.data
input  wire					 			in_data_valid;		//			 ST.valid
output reg					 		in_data_ready;		// 		 ST.ready
output reg [DATA_OUT_WIDTH-1:0] 	out_data;			//       Output ST.data
output reg							out_data_valid;	    // 		 ST.valid
input  wire								out_data_ready;	    // 		 ST.ready

reg [DATA_REG_WIDTH-1:0] cnt;
reg data_valid_mask = 0;

always@(posedge clk) begin 
	if(rst_n == 0) begin 
		out_data <= 0;
		cnt <= 0;
	end
	else begin 
		if(out_data_ready) begin 
			if(in_data_valid) begin
				if(cnt == decimate_reg) begin 
					cnt <= 0;
					out_data <= in_data;
				end
				else begin 
					cnt <= cnt + 1;
				end
			end
		end
		else begin
			cnt <= 0;
			out_data <= 0;
		end
	end
end



always@(posedge clk) begin 
	if(rst_n == 0 || !out_data_ready) begin 
		out_data_valid <= 1'b0;
	end
	else begin 
		in_data_ready <= 1'b1;
		if( in_data_valid && cnt == decimate_reg) begin 
			out_data_valid <= 1'b1;
			data_valid_mask <= 1'b1;
		end
		else if (data_valid_mask) begin 
			out_data_valid <= 1'b0;
			data_valid_mask <= 1'b0;
		end
	end	
end

endmodule 
