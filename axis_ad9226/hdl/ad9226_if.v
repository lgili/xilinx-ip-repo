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



module ad9226_if #
(		
		parameter ADC_DATA_WIDTH = 12,
		parameter QTD_ADC = 4,
		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width AXIS_DATA_WIDTH.
		parameter integer AXIS_DATA_WIDTH	= 32	
	)
	(
		// Users to add ports here
		input wire clk_100m,
		input wire reset_n,
		/*
		* ADC input
		*/
		input wire adc_clk,		
		input wire [ADC_DATA_WIDTH-1 : 0] adc_1,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_2,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_3,	
		input wire [ADC_DATA_WIDTH-1 : 0] adc_4,	

		/*
		* ADC output
		*/
		output wire [ADC_DATA_WIDTH-1 : 0] data_1,
		output wire [ADC_DATA_WIDTH-1 : 0] data_2,
		output wire [ADC_DATA_WIDTH-1 : 0] data_3,	
		output wire [ADC_DATA_WIDTH-1 : 0] data_4,

		
		/*
		* Interrupt 
		*/		
		output reg irq,		
		input wire ext_trigger,
		output wire trigger,
		output wire tlast_assert,
		output wire saved,

		/*
		* Configurations 
		*/	
		input 	wire 	[31:0]				PacketSize, 
		input 	wire 	[31:0]	 			Decimator,	
		input   wire    [31:0]     			MavgFactor,
		input   wire    [31:0]     			ConfigPassBand,
		input   wire    [31:0]     			ConfigAdc,			
		input 	wire 	     	            Restart,
		input 	wire 	[31:0]	            TriggerLevel,
			
		// User ports ends
		// Do not modify the ports beyond this line

		
		output wire debug

		
	);
	
/////////////////////////////////////////////////
// 
// Clk and ResetL
//
/////////////////////////////////////////////////
wire 		Clk; 
wire 		ResetL; 
wire        Clk_Adc;

assign Clk = clk_100m; 
assign ResetL = reset_n; 
assign Clk_Adc = adc_clk;



/////////////////////////////////////////////////
// 
// SIMPLE TRIGGER
//
/////////////////////////////////////////////////
wire moreORless;
wire [15:0] valueToTrigger;
wire useTrigger;

assign moreORless = TriggerLevel[31];
assign valueToTrigger = TriggerLevel[15:0];
assign useTrigger = TriggerLevel[30];

always@(Clk) begin 
	if(!useTrigger) begin 
		trigger_comb <= 0;
	end	
	else begin
		if(moreORless == 1) begin // more than
			if(data_1 >= valueToTrigger)
				trigger_comb <= 1;
			else 
				trigger_comb <= 0;	

		end
		else begin  // less than
			if(data_1 <= valueToTrigger)
				trigger_comb <= 1;
			else 
				trigger_comb <= 0;
		end
	end

end



/////////////////////////////////////////////////
// 
// TLAST
//
/////////////////////////////////////////////////
`define FSM_TRIGGER_STATE_IDLE      0
`define FSM_TRIGGER_STATE_WAITING   1
`define FSM_TRIGGER_STATE_ACTIVE    2
`define FSM_TRIGGER_STATE_END       3

reg     [2:0]       fsm_trigger_currentState;
reg     [2:0]       fsm_trigger_nexttState;
reg     [31:0]      triggerCount;
reg     [31:0]      tlastCount;
reg trigger_comb;

assign trigger = ( (fsm_trigger_currentState == `FSM_TRIGGER_STATE_END) ) ? 0 : 1;
assign tlast_assert = ( (fsm_trigger_currentState == `FSM_TRIGGER_STATE_ACTIVE) ) ? 1 : 0;

always @(posedge Clk) 
	if ( !ResetL ) begin 
		fsm_trigger_currentState <= `FSM_TRIGGER_STATE_IDLE; 
		fsm_trigger_nexttState <= `FSM_TRIGGER_STATE_IDLE; 
		tlastCount <= 0;
		triggerCount <= 0;
	end 
	else begin 
	
		case ( fsm_trigger_currentState )
		`FSM_TRIGGER_STATE_IDLE: begin
		    //   if(trigger_comb == 1'b1 || ext_trigger == 1'b0 )
			  if(ext_trigger == 1'b0 )
		          fsm_trigger_currentState <=  `FSM_TRIGGER_STATE_WAITING;
		      else
		          fsm_trigger_currentState <=  `FSM_TRIGGER_STATE_IDLE ;             
		end
		`FSM_TRIGGER_STATE_WAITING: begin
		      // count tlast (qtd of packages send after trigged)
				
				if (tlastCount >= (PacketSize >> 3)) begin  
					fsm_trigger_currentState <=    `FSM_TRIGGER_STATE_ACTIVE;  
				end
				else begin		
					tlastCount <= tlastCount + 1;           
					fsm_trigger_currentState <=    `FSM_TRIGGER_STATE_WAITING;
				end 
		          
		end
		`FSM_TRIGGER_STATE_ACTIVE: begin
		      
		      if(triggerCount >= 32'h1) begin
		          fsm_trigger_currentState <=    `FSM_TRIGGER_STATE_END;
		      end
		      else begin
		          triggerCount <= triggerCount + 1;  
		          fsm_trigger_currentState <=    `FSM_TRIGGER_STATE_ACTIVE;
		      end
		end      
		`FSM_TRIGGER_STATE_END: begin
		      
		      tlastCount <= 0;
		      triggerCount <= 0;
		     if(Restart == 1'b1) begin		      
		         fsm_trigger_currentState <= `FSM_TRIGGER_STATE_IDLE;
				 	         
		     end 
		      else begin
		         fsm_trigger_currentState <= `FSM_TRIGGER_STATE_END;		         
		     end        		
		end     
		
	    default: begin 
			fsm_trigger_currentState <= `FSM_TRIGGER_STATE_IDLE;
			fsm_trigger_nexttState <= `FSM_TRIGGER_STATE_IDLE; 
		end 
		endcase 
	end 



/////////////////////////////////////////////////
// 
// ADC Interface
//
/////////////////////////////////////////////////
wire  [QTD_ADC * ADC_DATA_WIDTH-1:0] adc_result;
wire  [QTD_ADC-1:0] adc_result_ready;
wire  [QTD_ADC-1:0] eoc;


wire [QTD_ADC-1:0] adc_result_valid;
wire [QTD_ADC * 12-1:0] adc_result_decimator;


// ADC instance
ad_9226#(
	.ADC_DATA_WIDTH(ADC_DATA_WIDTH)   
)
ADC [QTD_ADC-1:0]
(
	.clk(Clk),
	.rst_n(ResetL),
	.clk_sample(Clk_Adc),	        
	.eoc(eoc),
	.data_in({adc_1,adc_3,adc_2,adc_1}),	
	.data_out(adc_result),	
	.configAdc({ConfigAdc, ConfigAdc, ConfigAdc, ConfigAdc})           
);

/////////////////////////////////////////////////
// 
// Data Decimation
//
/////////////////////////////////////////////////

/*data_decimation#(
    .DATA_IN_WIDTH(ADC_DATA_WIDTH),
    .DATA_OUT_WIDTH(ADC_DATA_WIDTH),
    .DATA_REG_WIDTH(AXIS_DATA_WIDTH)
) decimator [QTD_ADC-1:0] 
(
	.clk(Clk),
	.rst_n(ResetL),	
	.in_data_valid(eoc),
	.in_data(adc_result),	
	.out_data_valid(adc_result_1_valid),
	.out_data(adc_result_decimator),
	.decimate_reg({Decimator, Decimator, Decimator, Decimator})  
);*/   


cic_d#(
	.DATA_IN_WIDTH(12),
	.DATA_OUT_WIDTH(12),
	.DECIMATION_RATIO(32),
	.ORDER(4),
	.DIFFERENCIAL_DELAY(1)
) decimator_filter [QTD_ADC-1:0]
(
	.clk(Clk),
    .reset_n(ResetL),
    .data_in(adc_result),
    .data_out(adc_result_decimator),
    .out_dv(adc_result_valid)
);

/////////////////////////////////////////////////
// 
// Moving Average 
//
/////////////////////////////////////////////////

wire [QTD_ADC*16-1:0] out_data_fir;
wire [QTD_ADC-1:0] out_data_valid_fir;

moving_average_fir#
(
	.IN_DATA_WIDTH(12),
	.OUT_DATA_WIDTH(16)
)	mavg_fir [QTD_ADC-1:0]
(
	.clk(Clk), 
	.rst(ResetL), 
	.mavg_factor({32'd15,32'd15,32'd15,32'd15}),
	.in_data_valid(adc_result_valid), 
	.in_data(adc_result_decimator),
	.out_data_valid(out_data_valid_fir), 
	.out_data(out_data_fir)
);

/////////////////////////////////////////////////
// 
// Pass band Filter 
//
/////////////////////////////////////////////////
wire [QTD_ADC*16-1:0] out_data_filter; 
wire [QTD_ADC-1:0] out_filter_valid;




/////////////////////////////////////////////////
// 
// M_AXIS_TDATA
//
/////////////////////////////////////////////////


wire signed [11:0] ddr_data_1;
wire signed [11:0] ddr_data_2;
wire signed [11:0] ddr_data_3;
wire signed [11:0] ddr_data_4;


assign ddr_data_1 = out_data_fir[15:4] ;
assign ddr_data_2 = out_data_fir[31:20] ;
assign ddr_data_3 = adc_result[11:0];
assign ddr_data_4 = out_data_fir[47:36] ;


function integer to_unsigned;
	input integer in_data;
	input integer offset;
	input integer dataSize;
	begin 
	to_unsigned = (in_data[dataSize-1]) ? ((~(in_data + offset) + 1)*(-1) ) : in_data + offset;

	end 
endfunction

assign data_1 = to_unsigned(ddr_data_1, 2048, 12);
assign data_2 = to_unsigned(ddr_data_2, 2048, 12);
assign data_3 = to_unsigned(ddr_data_3, 2048, 12);
assign data_4 = to_unsigned(ddr_data_4, 2048, 12);



endmodule
