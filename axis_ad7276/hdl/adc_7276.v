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
	parameter FIR_OUT_LENGTH = 16,
	parameter DATA_REG_WIDTH = 32     
	// User parameters ends
	// Do not modify the parameters beyond this line

	
)
(
    input  wire                         Clk_100m,
	input  wire  						Clk_adc,
	input  wire  						Resetn,
	
	/*
     * ADC port
     */	
	input  wire  [1:0]                inData,              
	output wire  [2*FIR_OUT_LENGTH-1:0]   adcData,
	output wire                       cs,  
	output wire                       sclk,      
	output wire                       sampleDone,
	
	
	/*
     * Configurations 
     */	
	input 	wire						         EnableSampleGeneration, 
	input 	wire 	[DATA_REG_WIDTH-1:0]	 PacketSize, 
	input 	wire 	[7:0]					     EnablePacket, 
	input 	wire 	[DATA_REG_WIDTH-1:0]	 ConfigPassband,
	input 	wire 	[DATA_REG_WIDTH-1:0]	 DMABaseAddr,
	input 	wire 	[DATA_REG_WIDTH-1:0]	 TriggerLevel,
	input 	wire 	[DATA_REG_WIDTH-1:0]	 ConfigSampler,
	input 	wire 	[DATA_REG_WIDTH-1:0]	 DataFromArm,
	input 	wire 	[DATA_REG_WIDTH-1:0]	 Decimator,	
	input   wire    [DATA_REG_WIDTH-1:0]   MavgFactor,

	output   wire    [31:0]              TriggerOffset,  
	output   wire    [31:0]              TriggerEnable
    );
    
/////////////////////////////////////////////////
// 
// Clk and ResetL
//
/////////////////////////////////////////////////
wire 		Clk; 
wire 		ResetL; 

assign Clk = Clk_100m; 
assign ResetL = Resetn;  


/////////////////////////////////////////////////
// 
// ADC
//
/////////////////////////////////////////////////
wire [11:0] adc0;
wire [11:0] adc1;
wire cs_n;
wire adc_ready;

assign cs = cs_n;
//assign adcData = (dataIsBeingTransferred == 1'b1) ?  {adc1,adc0} : adcData;

wire in_data_ready,in_data_ready1,in_data_ready2;

assign in_data_ready = (in_data_ready1 && in_data_ready2) ? 1'b1 : 1'b0;

wire eoc_adc;
wire [11:0] adc_result_decimator0,adc_result_decimator1;
wire adc_result_0_valid,adc_result_1_valid;

ad7276_if adc (
        //clock and reset signals
        .fpga_clk_i(Clk),
        .adc_clk_i(Clk_adc),
        .reset_n_i(ResetL),
            
        //IP control and data interface
        .en_0_i(in_data_ready),
        .en_1_i(1'b1),        
        .data_rdy_o(eoc_adc),
        .data_0_o(adc0),
        .data_1_o(adc1),
            
        //ADC control and data interface
        .data_0_i(inData[0]),
        .data_1_i(inData[1]),
        .sclk_o(sclk),
        .cs_o(cs_n)    
    );   
    



/////////////////////////////////////////////////
// 
// DECIMATOR
//
/////////////////////////////////////////////////

data_decimation #(
    .DATA_IN_WIDTH(12),
    .DATA_OUT_WIDTH(12),
    .DATA_REG_WIDTH(32)
) decimator0
(
	.clk(Clk),
	.rst_n(ResetL),
	.in_data_ready(in_data_ready1),
	.in_data_valid(eoc_adc),
	.in_data(adc0),
	.out_data_ready(1'b1),
	.out_data_valid(adc_result_0_valid),
	.out_data(adc_result_decimator0),
	.decimate_reg(Decimator)  
);

data_decimation#(
    .DATA_IN_WIDTH(12),
    .DATA_OUT_WIDTH(12),
    .DATA_REG_WIDTH(DATA_REG_WIDTH)
) decimator1 
(
	.clk(Clk),
	.rst_n(ResetL),
	.in_data_ready(in_data_ready2),
	.in_data_valid(eoc_adc),
	.in_data(adc1),
	.out_data_ready(1'b1),
	.out_data_valid(adc_result_1_valid),
	.out_data(adc_result_decimator1),
	.decimate_reg(Decimator)  
);   


/////////////////////////////////////////////////
// 
// FIR FILTER
//
/////////////////////////////////////////////////

wire [15:0] out_data_fir0;
wire [15:0] out_data_fir1;
wire out_data_valid_fir0;
wire out_data_valid_fir1;

moving_average_fir #
(
	.IN_DATA_WIDTH(12),
	.OUT_DATA_WIDTH(FIR_OUT_LENGTH)
)	mavg_fir0
(
	.clk(Clk), 
	.rst(ResetL), 
	.mavg_factor(MavgFactor),
	.in_data_valid(adc_result_0_valid), 
	.in_data(adc_result_decimator0),
	.out_data_valid(out_data_valid_fir0), 
	.out_data(out_data_fir0)
);

moving_average_fir #
(
	.IN_DATA_WIDTH(12),
	.OUT_DATA_WIDTH(FIR_OUT_LENGTH)
)	mavg_fir1
(
	.clk(Clk), 
	.rst(ResetL), 
	.mavg_factor(MavgFactor),
	.in_data_valid(adc_result_1_valid), 
	.in_data(adc_result_decimator1),
	.out_data_valid(out_data_valid_fir1), 
	.out_data(out_data_fir1)
);

assign adcData = {out_data_fir1 , out_data_fir0};
endmodule