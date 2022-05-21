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



module ad9226_v1_m_axis #
(
		// Users to add parameters here
		parameter ADC_DATA_WIDTH = 12,		

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width AXIS_DATA_WIDTH.
		parameter integer AXIS_DATA_WIDTH	= 32,
		// Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		/*
		* ADC input
		*/
		input wire adc_clk,
		input wire [ADC_DATA_WIDTH-1 : 0] data_1,
		input wire [ADC_DATA_WIDTH-1 : 0] data_2,
		input wire [ADC_DATA_WIDTH-1 : 0] data_3,
		input wire [ADC_DATA_WIDTH-1 : 0] data_4,
		input wire trigger,
		input wire tlast_assert,

		/*
		* Configurations 
		*/	
		input 	wire						EnableSampleGeneration, 
		input 	wire 	[31:0]				PacketSize, 
		input 	wire 	[7:0]				PacketRate, 
		input 	wire 	[31:0]				PacketPattern,
		input 	wire 	[31:0]				NumberOfPacketsToSend,
		input 	wire 	[31:0]	            Restart,
		
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  						M_AXIS_ACLK,
		input wire  						M_AXIS_ARESETN,
		output wire  						M_AXIS_TVALID,
		output wire 	[AXIS_DATA_WIDTH-1 : 0] 		M_AXIS_TDATA,
		output wire 	[(AXIS_DATA_WIDTH/8)-1 : 0] 	M_AXIS_TSTRB,
		output wire  						M_AXIS_TLAST,
		input wire  						M_AXIS_TREADY,
		output wire 	[(AXIS_DATA_WIDTH/8)-1 : 0] 	M_AXIS_TKEEP,
		output wire 						M_AXIS_TUSER,

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

assign Clk = M_AXIS_ACLK; 
assign ResetL = M_AXIS_ARESETN; 
assign Clk_Adc = adc_clk;

/////////////////////////////////////////////////
// 
// detect edges of EnableSampleGeneration
//
/////////////////////////////////////////////////

reg 	enableSampleGenerationR; 

wire 	enableSampleGenerationPosEdge; 
wire 	enableSampleGenerationNegEdge; 

always @(posedge Clk) 
	if ( ! ResetL  ) begin 
		enableSampleGenerationR <= 0; 
	end 
	else begin 
		enableSampleGenerationR <= EnableSampleGeneration; 
	end 
	
assign enableSampleGenerationPosEdge = EnableSampleGeneration && (! enableSampleGenerationR);
assign enableSampleGenerationNegEdge = (! EnableSampleGeneration) && enableSampleGenerationR;

/////////////////////////////////////////////////
// 
// fsm to enable / disable sample generation 
//
/////////////////////////////////////////////////
// simple fsm to control the sate of sample generator module 
// when EnableSampleGeneration arrives, the module begins producing samples
// when EnableSampleGeneration goes down, the module waits until is sends up to the end of the current packet and then stops. 

// states : 
`define FSM_STATE_IDLE		0 
`define FSM_STATE_ACTIVE 	1
`define FSM_STATE_WAIT_END	2

reg 	[1:0]		fsm_currentState; 
reg 	[1:0]		fsm_prevState; 

always @(posedge Clk) 
	if ( ! ResetL || Restart  ) begin 
		fsm_currentState <= `FSM_STATE_IDLE; 
		fsm_prevState <= `FSM_STATE_IDLE; 
	end 
	else begin 
		case ( fsm_currentState )
		`FSM_STATE_IDLE: begin 
			if ( enableSampleGenerationPosEdge ) begin 
				fsm_currentState <= `FSM_STATE_ACTIVE;
				fsm_prevState <= `FSM_STATE_IDLE;
			end 
			else begin 
				fsm_currentState <= `FSM_STATE_IDLE; 
				fsm_prevState <= `FSM_STATE_IDLE; 
			end 
		end 
		`FSM_STATE_ACTIVE: begin 
			if ( enableSampleGenerationNegEdge ) begin 
				fsm_currentState <= `FSM_STATE_WAIT_END; 
				fsm_prevState <= `FSM_STATE_ACTIVE;
			end 
			else begin 
				fsm_currentState <= `FSM_STATE_ACTIVE; 
				fsm_prevState <= `FSM_STATE_ACTIVE; 
			end 
		end 
		`FSM_STATE_WAIT_END: begin 
			if ( lastDataIsBeingTransferred ) begin 
				fsm_currentState <= `FSM_STATE_IDLE; 
				fsm_prevState <= `FSM_STATE_WAIT_END;
			end 
			else begin 
				fsm_currentState <= `FSM_STATE_WAIT_END; 
				fsm_prevState <= `FSM_STATE_WAIT_END;
			end 
		end 
		default: begin 
			fsm_currentState <= `FSM_STATE_IDLE;
			fsm_prevState <= `FSM_STATE_IDLE; 
		end 
		endcase 
	end 
	
/////////////////////////////////////////////////
// 
// data transfer qualifiers
//
/////////////////////////////////////////////////

(* mark_debug = "true", keep = "true" *)
wire 			dataIsBeingTransferred; 
(* mark_debug = "true", keep = "true" *)
wire 			lastDataIsBeingTransferred; 

assign dataIsBeingTransferred = M_AXIS_TVALID & M_AXIS_TREADY;
assign lastDataIsBeingTransferred = dataIsBeingTransferred & M_AXIS_TLAST;

/////////////////////////////////////////////////
// 
// packet size 
//
/////////////////////////////////////////////////

reg 	[AXIS_DATA_WIDTH-1-2:0]	packetSizeInDwords; 
reg 	[1:0]				validBytesInLastChunk; 

always @(posedge Clk) 
	if ( ! ResetL  ) begin 
		packetSizeInDwords <= 0; 
		validBytesInLastChunk <= 0; 
	end 
	else begin 
		if ( enableSampleGenerationPosEdge ) begin 
			if (AXIS_DATA_WIDTH == 32)
				packetSizeInDwords <= PacketSize >> 2;
			else
				packetSizeInDwords <= PacketSize >> 3;	
			validBytesInLastChunk <= PacketSize - packetSizeInDwords * 4;
		end 
	end 
	
// assign packetSizeInDwords = PacketSize >> 2; 
// assign validBytesInLastChunk = PacketSize - packetSizeInDwords * 4; 

/////////////////////////////////////////////////
// 
// global counterdataIsBeingTransferred
//
/////////////////////////////////////////////////
// this is a AXIS_DATA_WIDTH bits counter which counts up with every successful data transfer. this creates the body of the packets. 

reg 	[AXIS_DATA_WIDTH-1:0]		globalCounter; 
(* mark_debug = "true", keep = "true" *)

always @(posedge Clk) 
	if ( ! ResetL ) begin 
		globalCounter <= 0;		
	end 
	else begin 
		if ( dataIsBeingTransferred ) begin
			globalCounter <= globalCounter + 1; 
			
		end
		else  begin
			globalCounter <= globalCounter; 
			
		end
	end 



/////////////////////////////////////////////////
// 
// packet counter 
//
/////////////////////////////////////////////////
// this is a counter which counts how many dwords are being transferred for each packet 

reg 	[29:0]		packetDWORDCounter; 
reg     [1:0] channelPosTransfer; 
always @(posedge Clk) 
	if ( ! ResetL || Restart  ) begin 
		packetDWORDCounter <= 0; 
		channelPosTransfer <= 0;
	end 
	else begin 
		if ( lastDataIsBeingTransferred ) begin 
			packetDWORDCounter <= 0; 
			channelPosTransfer <= 0;
		end 
		else if ( dataIsBeingTransferred ) begin 
			packetDWORDCounter <= packetDWORDCounter + 1; 
			channelPosTransfer <= channelPosTransfer + 1;
		end 
		else begin 
			packetDWORDCounter <= packetDWORDCounter; 
			channelPosTransfer <= channelPosTransfer;
		end 
	end 

/////////////////////////////////////////////////
// 
// Packet rate counter
//
/////////////////////////////////////////////////
// with this logic, we can tune the speed of data production 
// PacketRate is an 8 bits number. this number indicates, within each 256 cycles of packet generation 
// for how many clock cycles we do not want to produce any data. 
// if PacketRate == 0 , then we produce data in all of the 256 clock cycles 
// if PacketRate == 1 , then we produce data for 255 clock cycles, and then for one clock cycle we do not produce any packet 
// ...
// if PacketRate == 255,the we produce data for 1 clock cycle and we do not produce data for the rest 255 clock cycles. 

wire 			packetRate_allowData; //trigger


//assign packetRate_allowData = ( packetRate_Counter >= PacketRate ) ? 1 : 0; 

/////////////////////////////////////////////////
// 
// Sent packet Counter
//
/////////////////////////////////////////////////
// this counts total number of packets which are being sent up to this point 

reg 	[31:0]		sentPacketCounter;

always @(posedge Clk)
	if ( ! ResetL ) begin 
		sentPacketCounter <= 0; 
	end 
	else begin 
		if ( fsm_currentState == `FSM_STATE_IDLE ) begin 
			sentPacketCounter <= 0; 
		end 
		else begin 
			if ( lastDataIsBeingTransferred ) 
				sentPacketCounter <= sentPacketCounter + 1; 
		end 
	end 
	
/////////////////////////////////////////////////
// 
// TVALID 
//
/////////////////////////////////////////////////
// generation of TVALID signal 
// if the fsm is in active state, then we generate packets 

assign M_AXIS_TVALID = ( packetRate_allowData && ( (fsm_currentState == `FSM_STATE_ACTIVE) || (fsm_currentState == `FSM_STATE_WAIT_END) ) ) ? 1 : 0; 


assign packetRate_allowData = trigger; //( (fsm_trigger_currentState == `FSM_TRIGGER_STATE_END) ) ? 0 : 1;


// assign M_AXIS_TLAST = (validBytesInLastChunk == 0) ? ( ( packetDWORDCounter == (packetSizeInDwords-1)) ? 1 : 0 ) : 
// 			( ( packetDWORDCounter == packetSizeInDwords ) ? 1 : 0 ); 

assign M_AXIS_TLAST = (validBytesInLastChunk == 0) ? ( ( packetDWORDCounter == (packetSizeInDwords-1) || tlast_assert ) ? 1 : 0 ) : 
			( ( packetDWORDCounter == packetSizeInDwords ) ? 1 : 0 ); 			

/////////////////////////////////////////////////
// 
// TSTRB
//
/////////////////////////////////////////////////

assign M_AXIS_TSTRB =   ( (! lastDataIsBeingTransferred) && dataIsBeingTransferred ) ? 4'hf :
			( lastDataIsBeingTransferred && (validBytesInLastChunk == 3) ) ? 4'h7 :
			( lastDataIsBeingTransferred && (validBytesInLastChunk == 2) ) ? 4'h3 : 
			( lastDataIsBeingTransferred && (validBytesInLastChunk == 1) ) ? 4'h1 : 4'hf; 
			
/////////////////////////////////////////////////
// 
// TKEEP and TUSER 
//
/////////////////////////////////////////////////

assign M_AXIS_TKEEP = M_AXIS_TSTRB; // 4'hf; 
assign M_AXIS_TUSER = 0; 




/////////////////////////////////////////////////
// 
// M_AXIS_TDATA
//
/////////////////////////////////////////////////



function [AXIS_DATA_WIDTH - 1:0] getData;
	input [AXIS_DATA_WIDTH-1:0] channel;
	begin
		case (channel)
			// 32'h0 : getData = {save[0], 15'd1, out_data_fir[15:0]};
			// 32'h1 : getData = {save[1], 15'd2, out_data_fir[31:16]};
			// 32'h2 : getData = {save[2], 15'd3, out_data_fir[47:32]};

			// 32'h0 : getData = {save[0], 19'd1, adc_result[11:0]};
			// 32'h1 : getData = {save[1], 19'd2, adc_result[23:12]};
			// 32'h2 : getData = {save[2], 19'd3, adc_result[35:24]};

			32'h0 : getData = {20'd1, data_1};
			32'h1 : getData = {20'd2, data_2};
			32'h2 : getData = {20'd3, data_3};
			
			32'h3 : getData = packetDWORDCounter;
			default : getData = 0;
		endcase
	end
endfunction


//assign M_AXIS_TDATA = data_1; 
assign M_AXIS_TDATA = getData(channelPosTransfer);

endmodule
