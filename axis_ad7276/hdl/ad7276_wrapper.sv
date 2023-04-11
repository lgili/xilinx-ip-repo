
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

//`define POST_SYNTHESIS_SIMULATION 1
	module ad7276_wrapper #
	(
		// Users to add parameters here
        parameter ADC_LENGTH = 12,
	    parameter ADC_QTD = 8,     
		parameter SAMPLE_RATE = 10		
	)
	(
		// Users to add ports here
	    input  wire [2*ADC_QTD-1:0]   inData,  
		// output wire [ADC_QTD*2*FIR_OUT_LENGTH-1:0] adc_data,
		output wire [ADC_LENGTH-1 : 0] adc_1,
		output wire [ADC_LENGTH-1 : 0] adc_2,
		output wire [ADC_LENGTH-1 : 0] adc_3,
		output wire [ADC_LENGTH-1 : 0] adc_4,
		output wire [ADC_LENGTH-1 : 0] adc_5,
		output wire [ADC_LENGTH-1 : 0] adc_6,
		output wire [ADC_LENGTH-1 : 0] adc_7,
		output wire [ADC_LENGTH-1 : 0] adc_8,
		output wire [ADC_LENGTH-1 : 0] adc_9,
		output wire [ADC_LENGTH-1 : 0] adc_10,
		output wire [ADC_LENGTH-1 : 0] adc_11,
		output wire [ADC_LENGTH-1 : 0] adc_12,
		output wire [ADC_LENGTH-1 : 0] adc_13,
		output wire [ADC_LENGTH-1 : 0] adc_14,
		output wire [ADC_LENGTH-1 : 0] adc_15,
		output wire [ADC_LENGTH-1 : 0] adc_16,
		
		output wire [ADC_QTD-1 : 0] cs,
		output wire [ADC_QTD-1 : 0] sclk,

		output wire cs0,
		output wire sclk0,
		
		output wire  [ADC_QTD-1:0]    eoc_adc,
		output wire  [ADC_QTD-1:0]	  adc_clk,		

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire                           CLK100MHz,
        input wire                           ARESETN                        
				
		/////////////////////////////////////////////////////////////////	
		
	);
	
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////
	
assign cs0 = cs[0];
assign sclk0 = sclk[1];

wire [ADC_LENGTH:0] adc0s[ADC_QTD];
wire [ADC_LENGTH:0] adc1s[ADC_QTD];
    	
	generate
		genvar i;
		for (i=0; i<ADC_QTD; i=i+1) begin

			wire eoc_intern;			
			adc_7276 #
			(
				.ADC_LENGTH(ADC_LENGTH),
				.SAMPLE_RATE(SAMPLE_RATE)
			) adc_inst
			(
				.CLK100MHz(CLK100MHz),
				.ARESETN(ARESETN),  		     
				.in_adc0(inData[i*2]), //[1:0],[]   
				.in_adc1(inData[(i*2)+1]),
				.adc0(adc0s[i]),
				.adc1(adc1s[i]),				
				.cs(cs[i]),
				.sclk(sclk[i]),      
				.eoc_adc(eoc_adc[i]), 
				.clk_sampling(adc_clk[i])		
			);
		end		

		if(ADC_QTD == 1) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
		end
		else if(ADC_QTD == 2) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
			assign adc_3 = adc0s[1];
			assign adc_4 = adc1s[1];
		end
		else if(ADC_QTD == 3) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
			assign adc_3 = adc0s[1];
			assign adc_4 = adc1s[1];
			assign adc_5 = adc0s[2];
			assign adc_6 = adc1s[2];
		end
		else if(ADC_QTD == 4) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
			assign adc_3 = adc0s[1];
			assign adc_4 = adc1s[1];
			assign adc_5 = adc0s[2];
			assign adc_6 = adc1s[2];
			assign adc_7 = adc0s[3];
			assign adc_8 = adc1s[3];
		end
		else if(ADC_QTD == 5) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
			assign adc_3 = adc0s[1];
			assign adc_4 = adc1s[1];
			assign adc_5 = adc0s[2];
			assign adc_6 = adc1s[2];
			assign adc_7 = adc0s[3];
			assign adc_8 = adc1s[3];
			assign adc_9 = adc0s[4];
			assign adc_10 = adc1s[4];
		end
		else if(ADC_QTD == 6) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
			assign adc_3 = adc0s[1];
			assign adc_4 = adc1s[1];
			assign adc_5 = adc0s[2];
			assign adc_6 = adc1s[2];
			assign adc_7 = adc0s[3];
			assign adc_8 = adc1s[3];
			assign adc_9 = adc0s[4];
			assign adc_10 = adc1s[4];
			assign adc_11 = adc0s[5];
			assign adc_12 = adc1s[5];
		end
		else if(ADC_QTD == 7) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
			assign adc_3 = adc0s[1];
			assign adc_4 = adc1s[1];
			assign adc_5 = adc0s[2];
			assign adc_6 = adc1s[2];
			assign adc_7 = adc0s[3];
			assign adc_8 = adc1s[3];
			assign adc_9 = adc0s[4];
			assign adc_10 = adc1s[4];
			assign adc_11 = adc0s[5];
			assign adc_12 = adc1s[5];
			assign adc_13 = adc0s[6];
			assign adc_14 = adc1s[6];
		end
		else if(ADC_QTD == 8) begin
			assign adc_1 = adc0s[0];
			assign adc_2 = adc1s[0];
			assign adc_3 = adc0s[1];
			assign adc_4 = adc1s[1];
			assign adc_5 = adc0s[2];
			assign adc_6 = adc1s[2];
			assign adc_7 = adc0s[3];
			assign adc_8 = adc1s[3];
			assign adc_9 = adc0s[4];
			assign adc_10 = adc1s[4];
			assign adc_11 = adc0s[5];
			assign adc_12 = adc1s[5];
			assign adc_13 = adc0s[6];
			assign adc_14 = adc1s[6];
			assign adc_15 = adc0s[7];
			assign adc_16 = adc1s[7];
		end
	endgenerate
    

	endmodule
