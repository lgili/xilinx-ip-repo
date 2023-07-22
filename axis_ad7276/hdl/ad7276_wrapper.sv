
/*
Copyright (c) 2014-2022 Luiz Carlos Gili

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// Language: Verilog 2001

`timescale 1ns / 1ps
// `define HARD_FLOAT
// // `define FLOAT_REAL
// `include "../../svreal/svreal.sv"
`include "axis.vh"
`include "utility.vh"

//`define POST_SYNTHESIS_SIMULATION 1
	module ad7276_wrapper #
	(
		// Users to add parameters here
        parameter ADC_LENGTH = 12,
	    parameter ADC_QTD = 8,     
		parameter SAMPLE_RATE = 2,
		parameter AXIS_BYTES = 4,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter OUTPUT_AS_FLOAT =  0// 0 or 1
	)
	(
		// Users to add ports here
	    input  wire [2*ADC_QTD-1:0]   inData,  
		// output wire [ADC_QTD*2*FIR_OUT_LENGTH-1:0] adc_data,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_1,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_2,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_3,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_4,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_5,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_6,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_7,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_8,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_9,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_10,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_11,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_12,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_13,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_14,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_15,
		output wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1 : 0] adc_16,

				
		
		output wire [ADC_QTD-1 : 0] cs,
		output wire [ADC_QTD-1 : 0] sclk,

		output wire cs0,
		output wire sclk0,
		
		output wire  [ADC_QTD-1:0]    eoc_adc,
		output wire  [ADC_QTD-1:0]	  adc_clk,	
		output wire             	  adc_sampling,	
		output wire 				  resetn,

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire                           CLK100MHz,
        input wire                           ARESETN,

		//input wire enable,
		//input wire [31:0] num_of_words,

		`S_AXI_PORT(s_axi, AXIS_BYTES, C_S_AXI_ADDR_WIDTH),
		`M_AXIS_PORT_TDEST(axis_o, AXIS_BYTES),
		`M_AXIS_PORT_NO_USER(axis_ad1, AXIS_BYTES),
		`M_AXIS_PORT_NO_USER(axis_ad2, AXIS_BYTES),
		`M_AXIS_PORT_NO_USER(axis_ad3, AXIS_BYTES),


		// Ports of Axi Master Bus Interface M_AXIS
		// input wire  m_axis_aclk,
		// input wire  m_axis_aresetn,
		// output wire  m_axis_tvalid,
		// output wire [31 : 0] m_axis_tdata,
		// output wire [(AXIS_BYTES)-1 : 0] m_axis_tstrb,
		// output wire  m_axis_tlast,
		// input wire  m_axis_tready, 
		// output wire 	[(AXIS_BYTES)-1 : 0] m_axis_tkeep, 
		// output wire 	m_axis_tuser
		`M_AXIS_PORT_NO_USER(axis_adc, AXIS_BYTES)
		                      
				
		/////////////////////////////////////////////////////////////////	
		
	);
	
//////
wire EnableSampleGeneration;
wire [(AXIS_BYTES*8)-1:0] PacketSize;
wire [(AXIS_BYTES*8)-1:0] PacketRate;
wire [(AXIS_BYTES*8)-1:0] NumberOfPacketsToSend;
wire [(AXIS_BYTES*8)-1:0] TriggerPosMemory;
wire [(AXIS_BYTES*8)-1:0] TriggerLevelValue;
wire [(AXIS_BYTES*8)-1:0] TriggerChannel;
reset_gen res (
	.clk_slow(adc_sampling),
	.reset_in(ARESETN),
	.reset_out(resetn)
);

ad7276_m_axis # ( 
	.C_M_AXIS_TDATA_WIDTH(32),
	.C_M_START_COUNT(32),
	.NUM_CHANNELS(16),
	.DATA_WIDTH_ADC(16)
) ad7276_m_axis_inst (

	.EnableSampleGeneration 	( EnableSampleGeneration ), 
	.PacketSize 				( PacketSize ), 
	.PacketRate					( PacketRate ), 
	.NumberOfPacketsToSend		( NumberOfPacketsToSend ),
	.TriggerChannel				( TriggerChannel ),
	.TriggerLevelValue			( TriggerLevelValue ),
	.TriggerPosMemory			( TriggerPosMemory ),
	.InData						({4'hF,adc_16,4'hE,adc_15,4'hD,adc_14,4'hC,adc_13,4'hB,adc_12,4'hA,adc_11,4'h9,adc_10,4'h8,adc_9,4'h7,adc_8,4'h6,adc_7,4'h5,adc_6,4'h4,adc_5,4'h3,adc_4,4'h2,adc_3,4'h1,adc_2,4'h0,adc_1}),
	
	.m_axis_aclk			(CLK100MHz),
	.m_axis_aresetn			(ARESETN),
	`AXIS_MAP_NO_USER(m_axis, axis_adc)

);
///////////////////////////////////////////////////////////////////////////
//
// axis master TODO: find a way to put inside generate 
//
///////////////////////////////////////////////////////////////////////////

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch1_axis_out
(
	.clk(CLK100MHz),
	.sresetn(resetn),
	.vec({adc_2,adc_1}),
	`AXIS_MAP_NO_USER(axis, axis_ad1)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch2_axis_out
(
	.clk(CLK100MHz),
	.sresetn(resetn),
	.vec({adc_4,adc_3}),
	`AXIS_MAP_NO_USER(axis, axis_ad2)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch3_axis_out
(
	.clk(CLK100MHz),
	.sresetn(resetn),
	.vec({adc_6,adc_5}),
	`AXIS_MAP_NO_USER(axis, axis_ad3)
);

///////////////////////////////////////////////////////////////////////////
`AXIS_INST_TDEST(axis_ch1,AXIS_BYTES);
`AXIS_INST_TDEST(axis_ch2,AXIS_BYTES);
`AXIS_INST_TDEST(axis_ch3,AXIS_BYTES);
`AXIS_INST_TDEST(axis_ch4,AXIS_BYTES);
`AXIS_INST_TDEST(axis_ch5,AXIS_BYTES);
`AXIS_INST_TDEST(axis_ch6,AXIS_BYTES);
`AXIS_INST_TDEST(axis_ch7,AXIS_BYTES);
`AXIS_INST_TDEST(axis_ch8,AXIS_BYTES);


vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(1)
) ch1_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_2,adc_1}),
	`AXIS_MAP_TDEST(axis, axis_ch1)
);

vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(2)
) ch2_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_4,adc_3}),
	`AXIS_MAP_TDEST(axis, axis_ch2)
);

vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(3)
) ch3_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_6,adc_5}),
	`AXIS_MAP_TDEST(axis, axis_ch3)
);

vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(4)
) ch4_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_8,adc_7}),
	`AXIS_MAP_TDEST(axis, axis_ch4)
);

vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(5)
) ch5_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_10,adc_9}),
	`AXIS_MAP_TDEST(axis, axis_ch5)
);

vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(6)
) ch6_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_12,adc_11}),
	`AXIS_MAP_TDEST(axis, axis_ch6)
);

vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(7)
) ch7_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_14,adc_13}),
	`AXIS_MAP_TDEST(axis, axis_ch7)
);

vector_to_axis_tdest #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1),
	.TDEST(8)
) ch8_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec({adc_16,adc_15}),
	`AXIS_MAP_TDEST(axis, axis_ch8)
);



// axis_joiner_tdest
// #(
// 	.AXIS_BYTES(AXIS_BYTES),
// 	.NUM_STREAMS(8)
// ) output_joiner (
// 	.clk(CLK100MHz),
// 	.sresetn(ARESETN),
// 	.enable(EnableSampleGeneration),
// 	.words_to_send(PacketSize),
// 	`AXIS_MAP_8_TDEST(axis_i, axis_ch1, axis_ch2, axis_ch3, axis_ch4, axis_ch5, axis_ch6, axis_ch7, axis_ch8),

// 	`AXIS_MAP_TDEST(axis_o, axis_o)
// );

// initial axis_ch = 2;
assign adc_sampling = adc_clk[0];
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////
	
assign cs0 = cs[0];
assign sclk0 = sclk[1];

// assign axis_ch5 = sclk[1];

wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1:0] adc1s[ADC_QTD];
wire [(OUTPUT_AS_FLOAT*(32-ADC_LENGTH))+ADC_LENGTH-1:0] adc2s[ADC_QTD];
    	
	generate
		genvar i;
		for (i=0; i<ADC_QTD; i=i+1) begin

			wire eoc_intern;			
			adc_7276 #
			(
				.ADC_LENGTH(ADC_LENGTH),
				.SAMPLE_RATE(SAMPLE_RATE),
				.OUTPUT_AS_FLOAT(OUTPUT_AS_FLOAT)
			) adc_inst
			(
				.CLK100MHz(CLK100MHz),
				.ARESETN(ARESETN),  
				.id(i),		     
				.in_adc1(inData[i*2]), //[1:0],[]   
				.in_adc2(inData[(i*2)+1]),
				.offset(2047),
				.gain(655), // is 0.1 q16_16 site of converter https://www.rfwireless-world.com/calculators/floating-vs-fixed-point-converter.html
				.adc1(adc1s[i]),
				.adc2(adc2s[i]),								
				.cs(cs[i]),
				.sclk(sclk[i]),      
				.eoc_adc(eoc_adc[i]), 
				.clk_sampling(adc_clk[i])		
			);

			
		end		

		if(ADC_QTD == 1) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
		end
		else if(ADC_QTD == 2) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
			assign adc_3 = adc1s[1];
			assign adc_4 = adc2s[1];
		end
		else if(ADC_QTD == 3) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
			assign adc_3 = adc1s[1];
			assign adc_4 = adc2s[1];
			assign adc_5 = adc1s[2];
			assign adc_6 = adc2s[2];
		end
		else if(ADC_QTD == 4) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
			assign adc_3 = adc1s[1];
			assign adc_4 = adc2s[1];
			assign adc_5 = adc1s[2];
			assign adc_6 = adc2s[2];
			assign adc_7 = adc1s[3];
			assign adc_8 = adc2s[3];
		end
		else if(ADC_QTD == 5) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
			assign adc_3 = adc1s[1];
			assign adc_4 = adc2s[1];
			assign adc_5 = adc1s[2];
			assign adc_6 = adc2s[2];
			assign adc_7 = adc1s[3];
			assign adc_8 = adc2s[3];
			assign adc_9 = adc1s[4];
			assign adc_10 = adc2s[4];
		end
		else if(ADC_QTD == 6) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
			assign adc_3 = adc1s[1];
			assign adc_4 = adc2s[1];
			assign adc_5 = adc1s[2];
			assign adc_6 = adc2s[2];
			assign adc_7 = adc1s[3];
			assign adc_8 = adc2s[3];
			assign adc_9 = adc1s[4];
			assign adc_10 = adc2s[4];
			assign adc_11 = adc1s[5];
			assign adc_12 = adc2s[5];
		end
		else if(ADC_QTD == 7) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
			assign adc_3 = adc1s[1];
			assign adc_4 = adc2s[1];
			assign adc_5 = adc1s[2];
			assign adc_6 = adc2s[2];
			assign adc_7 = adc1s[3];
			assign adc_8 = adc2s[3];
			assign adc_9 = adc1s[4];
			assign adc_10 = adc2s[4];
			assign adc_11 = adc1s[5];
			assign adc_12 = adc2s[5];
			assign adc_13 = adc1s[6];
			assign adc_14 = adc2s[6];
		end
		else if(ADC_QTD == 8) begin
			assign adc_1 = adc1s[0];
			assign adc_2 = adc2s[0];
			assign adc_3 = adc1s[1];
			assign adc_4 = adc2s[1];
			assign adc_5 = adc1s[2];
			assign adc_6 = adc2s[2];
			assign adc_7 = adc1s[3];
			assign adc_8 = adc2s[3];
			assign adc_9 = adc1s[4];
			assign adc_10 = adc2s[4];
			assign adc_11 = adc1s[5];
			assign adc_12 = adc2s[5];
			assign adc_13 = adc1s[6];
			assign adc_14 = adc2s[6];
			assign adc_15 = adc1s[7];
			assign adc_16 = adc2s[7];
		end
	endgenerate
    

// wire enable;

// assign enable = (EnableSampleGeneration == 1) ? 1'b1: enable;
ad9226_v1_s_axi # ( 
	.AXI_BYTES(AXIS_BYTES),
	.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) 	ad9226_v1_s_axi_inst (
		
	.EnableSampleGeneration 	( EnableSampleGeneration ), 
	.PacketSize 			    ( PacketSize ), 
	.PacketRate 			    ( PacketRate ), 
	.NumberOfPacketsToSend		( NumberOfPacketsToSend ),
	.TriggerLevelValue			( TriggerLevelValue ),
	.TriggerChannel				( TriggerChannel ),
	.TriggerPosMemory			( TriggerPosMemory ),

	
	.DataAdc2Adc1({adc_2,adc_1}),
	.DataAdc4Adc3({adc_4,adc_3}),
	.DataAdc6Adc5({adc_6,adc_5}),
	.DataAdc8Adc7({adc_8,adc_7}),
	.DataAdc10Adc9({adc_10,adc_9}),
	.DataAdc12Adc11({adc_12,adc_11}),
	.DataAdc14Adc13({adc_14,adc_13}),	
	.DataAdc16Adc15({adc_16,adc_15}),	
	
		
	.s_axi_aclk			    (CLK100MHz),
	.s_axi_aresetn			(ARESETN),
	
	`AXI_MAP(s_axi, s_axi)
);		
	
	endmodule
