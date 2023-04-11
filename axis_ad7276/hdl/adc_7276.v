`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2022 10:12:48 AM
// Design Name: 
// Module Name: adc_7276
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adc_7276#
(
	// Users to add parameters here
	parameter ADC_LENGTH = 12,
	parameter SAMPLE_RATE = 3	
)
(
    input  wire                         CLK100MHz,
	input  wire  						ARESETN,
	/*
     * ADC port
     */	
	input  wire  		                in_adc0,
	input  wire  		                in_adc1,              
	output wire  [ADC_LENGTH-1:0]  		adc0,
	output wire  [ADC_LENGTH-1:0]  		adc1,
	output wire                         cs,  
	output wire                         sclk,      
	output wire                         eoc_adc,
	output wire 					    clk_sampling
	
	
    );
    
/////////////////////////////////////////////////
// 
// Clk and ResetL
//
/////////////////////////////////////////////////
wire 		Clk; 
wire 		ResetL; 

assign Clk = CLK100MHz; 
assign ResetL = ARESETN;  


/////////////////////////////////////////////////
// 
// ADC
//
/////////////////////////////////////////////////
wire cs_n;
wire adc_ready;

assign cs = cs_n;

wire in_data_ready,in_data_ready1,in_data_ready2;


wire [11:0] adc_result_decimator0,adc_result_decimator1;
wire adc_result_0_valid,adc_result_1_valid;

reg [4:0 ]time_scale;
reg [31:0] time_sampling;
reg [15:0] dis_count;
wire adc_clk;

localparam ADC_CLK_DIV = 5;
always @(posedge Clk, negedge ResetL) begin
	if(~ResetL)
		dis_count <= 0;
	else begin
		dis_count <= dis_count + 1;
		if(dis_count >= ADC_CLK_DIV)
			dis_count <= 0;
	end
end

assign adc_clk = !(dis_count <= ADC_CLK_DIV/2);

ad7276_if adc (
        //clock and reset signals
        .fpga_clk_i(Clk),
        .adc_clk_i(adc_clk),
        .reset_n_i(ResetL),
            
        //IP control and data interface
        .en_0_i(1'b1),
        .en_1_i(1'b1),        
        .data_rdy_o(eoc_adc),
        .data_0_o(adc0),
        .data_1_o(adc1),
            
        //ADC control and data interface
        .data_0_i(in_adc0),
        .data_1_i(in_adc1),
        .sclk_o(sclk),
        .cs_o(cs_n)    
    );   
    
reg [15:0] sample_count;
always @(posedge eoc_adc, negedge ARESETN) begin
	if(~ARESETN)
		sample_count <= 0;
	else begin
		sample_count <= sample_count + 1;
		if(sample_count >= SAMPLE_RATE)
			sample_count <= 0;
	end
end

assign clk_sampling = !(sample_count <= SAMPLE_RATE/2);
/////////////////////////////////////////////////
// 
// DECIMATOR
//
/////////////////////////////////////////////////

// data_decimation #(
//     .DATA_IN_WIDTH(12),
//     .DATA_OUT_WIDTH(12),
//     .DATA_REG_WIDTH(32)
// ) decimator0
// (
// 	.clk(Clk),
// 	.rst_n(ResetL),
// 	.in_data_ready(in_data_ready1),
// 	.in_data_valid(eoc_adc),
// 	.in_data(adc0),
// 	.out_data_ready(1'b1),
// 	.out_data_valid(adc_result_0_valid),
// 	.out_data(adc_result_decimator0),
// 	.decimate_reg(Decimator)  
// );

// data_decimation#(
//     .DATA_IN_WIDTH(12),
//     .DATA_OUT_WIDTH(12),
//     .DATA_REG_WIDTH(DATA_REG_WIDTH)
// ) decimator1 
// (
// 	.clk(Clk),
// 	.rst_n(ResetL),
// 	.in_data_ready(in_data_ready2),
// 	.in_data_valid(eoc_adc),
// 	.in_data(adc1),
// 	.out_data_ready(1'b1),
// 	.out_data_valid(adc_result_1_valid),
// 	.out_data(adc_result_decimator1),
// 	.decimate_reg(Decimator)  
// );   


/////////////////////////////////////////////////
// 
// FIR FILTER
//
/////////////////////////////////////////////////

// wire [15:0] out_data_fir0;
// wire [15:0] out_data_fir1;
// wire out_data_valid_fir0;
// wire out_data_valid_fir1;

// moving_average_fir #
// (
// 	.IN_DATA_WIDTH(12),
// 	.OUT_DATA_WIDTH(FIR_OUT_LENGTH)
// )	mavg_fir0
// (
// 	.clk(Clk), 
// 	.rst(ResetL), 
// 	.mavg_factor(MavgFactor),
// 	.in_data_valid(adc_result_0_valid), 
// 	.in_data(adc_result_decimator0),
// 	.out_data_valid(out_data_valid_fir0), 
// 	.out_data(out_data_fir0)
// );

// moving_average_fir #
// (
// 	.IN_DATA_WIDTH(12),
// 	.OUT_DATA_WIDTH(FIR_OUT_LENGTH)
// )	mavg_fir1
// (
// 	.clk(Clk), 
// 	.rst(ResetL), 
// 	.mavg_factor(MavgFactor),
// 	.in_data_valid(adc_result_1_valid), 
// 	.in_data(adc_result_decimator1),
// 	.out_data_valid(out_data_valid_fir1), 
// 	.out_data(out_data_fir1)
// );

// assign adcData = {out_data_fir1 , out_data_fir0};
endmodule