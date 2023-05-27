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
	parameter SAMPLE_RATE = 12,
	parameter OUTPUT_AS_FLOAT = 1 // 0 or 1
)
(
    input  wire                         CLK100MHz,
	input  wire  						ARESETN,
	/*
     * ADC port
     */	
	input  wire  		                in_adc1,
	input  wire  		                in_adc2,  
	input  wire        [ADC_LENGTH-1:0] offset, 
	input  wire       	[31:0] 			gain,    
	output wire  		[(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1:0] adc1,
	output wire  		[(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1:0] adc2,
	output wire                         cs,  
	output wire                         sclk,      
	output wire                         eoc_adc,
	output wire 					    clk_sampling,

	input wire   [ADC_LENGTH-1:0]       id
	
	
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
wire adc_clk_inv;

wire [ADC_LENGTH-1:0] adc1_raw;
wire [ADC_LENGTH-1:0] adc2_raw;

// 4 is the minimal value to work as 1M samples for the ad7276
localparam ADC_CLK_DIV = 4;

clock_divider#(
	.DIV_WIDTH(ADC_CLK_DIV)    		// Number of divider
) adc_clock (
	.clk_in(Clk),				// clock in
	.div_ctrl(ADC_CLK_DIV/2),	// divider control
	.rstn(ResetL),				// reset (active low)
	.clk_out(adc_clk),			// clock out
	.clk_out_b(adc_clk_inv)		// complementary clock out
);

wire clock_adc;

assign clock_adc = (id == 1 || id == 3 || id == 5 || id == 7 || id == 9 || id == 11 || id == 13 || id == 15) ? adc_clk : adc_clk_inv;

ad7276_if #(
	.ADC_CLK_DIV(ADC_CLK_DIV-3)
)
adc (
        //clock and reset signals
        .fpga_clk_i(Clk),
        .adc_clk_i(clock_adc),
        .reset_n_i(ResetL),
            
        //IP control and data interface
        .en_0_i(1'b1),
        .en_1_i(1'b1),        
        .data_rdy_o(eoc_adc),
        .data_0_o(adc1_raw),
        .data_1_o(adc2_raw),
            
        //ADC control and data interface
        .data_0_i(in_adc1),
        .data_1_i(in_adc2),
        .sclk_o(sclk),
        .cs_o(cs_n)    
    );   
    


// assign clk_sampling = !(sample_count <= SAMPLE_RATE/2);
clock_divider#(
	.DIV_WIDTH(SAMPLE_RATE)    	// Number of divider
) sample_clock (
	.clk_in(adc_clk),			// clock in
	.div_ctrl(SAMPLE_RATE/2),	// divider control
	.rstn(ResetL),				// reset (active low)
	.clk_out(clk_sampling),		// clock out
	.clk_out_b()				// complementary clock out
);

/////////////////////////////////////////////////
// 
// to_float
//
/////////////////////////////////////////////////
// wire [31:0] adc1_q16_16;
// wire [31:0] adc2_q16_16;
// wire [31:0] offset_q16_16;
// wire [31:0] adc1_without_offset_q16_16;
// wire [31:0] adc2_without_offset_q16_16;
// wire [31:0] adc1_with_gain_q16_16;
// wire [31:0] adc2_with_gain_q16_16;
// reg  [31:0] adc1_float;
// reg  [31:0] adc2_float;
// wire signed [31:0] ad1s;


// assign adc1_q16_16 = (adc1_raw << 16);
// assign adc2_q16_16 = (adc2_raw << 16);
// assign offset_q16_16 = (offset << 16);

// fxp_addsub # (
//     .WIIA(16),
//     .WIFA(16),
//     .WIIB(16),
//     .WIFB(16),
//     .WOI(16),
//     .WOF(16),
//     .ROUND(1)
// )sub_1(
//     .ina(adc1_q16_16),
//     .inb(offset_q16_16),
//     .sub(1), // 0=add, 1=sub
//     .out(adc1_without_offset_q16_16),
//     .overflow()
// );
// fxp_addsub # (
//     .WIIA(16),
//     .WIFA(16),
//     .WIIB(16),
//     .WIFB(16),
//     .WOI(16),
//     .WOF(16),
//     .ROUND(1)
// )sub_2(
//     .ina(adc2_q16_16),
//     .inb(offset_q16_16),
//     .sub(1), // 0=add, 1=sub
//     .out(adc2_without_offset_q16_16),
//     .overflow()
// );

// fxp_mul # (
//     .WIIA(16),
//     .WIFA(16),
//     .WIIB(16),
//     .WIFB(16),
//     .WOI(16),
//     .WOF(16),
//     .ROUND(1)
// )mult_1(
//     .ina(adc1_without_offset_q16_16),
//     .inb(gain),
//     .out(adc1_with_gain_q16_16),
//     .overflow()
// );

// fxp_mul # (
//     .WIIA(16),
//     .WIFA(16),
//     .WIIB(16),
//     .WIFB(16),
//     .WOI(16),
//     .WOF(16),
//     .ROUND(1)
// )mult_2(
//     .ina(adc2_without_offset_q16_16),
//     .inb(gain),
//     .out(adc2_with_gain_q16_16),
//     .overflow()
// );

// fxp2float #(
//     .WII(16),
//     .WIF(16)
// ) fxp2float_0 (
//     .in(adc1_with_gain_q16_16),
//     .out(adc1_float)
// );

// fxp2float #(
//     .WII(16),
//     .WIF(16)
// ) fxp2float_1 (
//     .in(adc2_with_gain_q16_16),
//     .out(adc2_float)
// );



// assign adc1 = (OUTPUT_AS_FLOAT == 1) ? adc1_float : adc1_raw;
// assign adc2 = (OUTPUT_AS_FLOAT == 1) ? adc2_float : adc2_raw;

assign adc1 = adc1_raw;
assign adc2 = adc2_raw;

endmodule