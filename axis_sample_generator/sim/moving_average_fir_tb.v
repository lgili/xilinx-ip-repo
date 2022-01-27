`timescale 1 ns / 1 ps

module moving_average_fir_tb();

parameter PACKET_WIDTH = 16;
parameter OUT_PACKET_WIDTH = 32;

reg clk;
reg rst;
reg [PACKET_WIDTH-1:0] mavg_factor;
reg in_data_valid;
reg [PACKET_WIDTH-1:0] in_data;
wire out_data_valid;
wire [OUT_PACKET_WIDTH-1:0] out_data;

moving_average_fir #(.IN_DATA_WIDTH(PACKET_WIDTH),
							.OUT_DATA_WIDTH(OUT_PACKET_WIDTH))
							
							mavg_fir
							
							(.clk(clk), 
							.rst(rst), 
							.mavg_factor(mavg_factor),
							.in_data_valid(in_data_valid), 
							.in_data(in_data),
							.out_data_valid(out_data_valid), 
							.out_data(out_data));	
	
	
	reg [7:0] cnt;
	reg [15:0] constant;
	initial begin 
		rst = 1;
		clk = 0;
		mavg_factor = 5;
		cnt = 0;
		in_data = 0;
		in_data_valid = 0;
		constant=0;
		#20 rst = 0;	
	end 
	
	always@(posedge clk) begin 
		if(cnt == 20) begin 
			cnt <= 0;
			constant <= constant + 1;
			in_data_valid <= 1'b1;
			in_data <=  constant;
		end 
		else begin 
			in_data_valid <= 1'b0;
			cnt <= cnt + 1;
		end
	end 
	
	always 
		#10 clk = !clk ;
		
endmodule
 