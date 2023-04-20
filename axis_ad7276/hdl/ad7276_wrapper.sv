
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
		parameter OUTPUT_AS_FLOAT =  1// 0 or 1
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

		`M_AXIS_PORT_NO_USER(axis_ch1, AXIS_BYTES),  
		`M_AXIS_PORT_NO_USER(axis_ch2, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch3, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch4, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch5, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch6, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch7, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch8, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch9, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch10, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch11, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch12, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch13, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch14, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch15, AXIS_BYTES), 
		`M_AXIS_PORT_NO_USER(axis_ch16, AXIS_BYTES)                       
				
		/////////////////////////////////////////////////////////////////	
		
	);
	
//////


reset_gen res (
	.clk_slow(adc_sampling),
	.reset_in(ARESETN),
	.reset_out(resetn)
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
) ch1_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_1),
	`AXIS_MAP_NO_USER(axis, axis_ch1)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch2_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_2),
	`AXIS_MAP_NO_USER(axis, axis_ch2)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch3_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_3),
	`AXIS_MAP_NO_USER(axis, axis_ch3)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch4_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_4),
	`AXIS_MAP_NO_USER(axis, axis_ch4)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch5_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_5),
	`AXIS_MAP_NO_USER(axis, axis_ch5)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch6_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_6),
	`AXIS_MAP_NO_USER(axis, axis_ch6)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch7_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_7),
	`AXIS_MAP_NO_USER(axis, axis_ch7)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch8_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_8),
	`AXIS_MAP_NO_USER(axis, axis_ch8)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch9_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_9),
	`AXIS_MAP_NO_USER(axis, axis_ch9)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch10_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_10),
	`AXIS_MAP_NO_USER(axis, axis_ch10)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch11_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_11),
	`AXIS_MAP_NO_USER(axis, axis_ch11)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch12_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_12),
	`AXIS_MAP_NO_USER(axis, axis_ch12)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch13_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_13),
	`AXIS_MAP_NO_USER(axis, axis_ch13)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch14_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_14),
	`AXIS_MAP_NO_USER(axis, axis_ch14)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch15_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_15),
	`AXIS_MAP_NO_USER(axis, axis_ch15)
);

vector_to_axis #
(
	.VEC_BYTES(AXIS_BYTES),
	.AXIS_BYTES(AXIS_BYTES),
	.MSB_FIRST(1)
) ch16_axis
(
	.clk(adc_sampling),
	.sresetn(resetn),
	.vec(adc_16),
	`AXIS_MAP_NO_USER(axis, axis_ch16)
);

// initial axis_ch = 2;
assign adc_sampling = adc_clk[0];
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////
	
assign cs0 = cs[0];
assign sclk0 = sclk[1];

assign axis_ch5 = sclk[1];

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
    
	
	endmodule
