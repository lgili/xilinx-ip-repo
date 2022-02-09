
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

module ad7276_v1_m_axis #
(
	// Users to add parameters here
	parameter ADC_LENGTH = 12,        
	// User parameters ends
	// Do not modify the parameters beyond this line

	// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
	parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
	// Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
	parameter integer C_M_START_COUNT	= 32
)
(
	// Users to add ports here
	input  wire                         Clk_100m,
	input  wire  						Clk_adc,
	input  wire  						Resetn,

	input wire [31:0] angle ,
	/*
     * ADC port
     */	
	input  wire  [1:0]                inData,              
	output wire  [2*ADC_LENGTH-1:0]   adcData,
	output wire                       cs,  
	output wire                       sclk,      
	output wire                       sampleDone,
	
	
	/*
     * Configurations 
     */	
	input 	wire						         EnableSampleGeneration, 
	input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	 PacketSize, 
	input 	wire 	[7:0]					     EnablePacket, 
	input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	 ConfigPassband,
	input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	 DMABaseAddr,
	input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	 TriggerLevel,
	input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	 ConfigSampler,
	input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	 DataFromArm,
	input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	 Decimator,	
	input   wire    [C_M_AXIS_TDATA_WIDTH-1:0]   MavgFactor,

	output   wire    [31:0]              TriggerOffset,  
	output   wire    [31:0]              TriggerEnable,

	// User ports ends
	// Do not modify the ports beyond this line

	// Global ports
	
	output wire  									m_axis_tvalid, 
	output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] 		m_axis_tdata, 
	output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	m_axis_tstrb, 
	output wire  									m_axis_tlast, 
	input  wire  									m_axis_tready, 
	output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	m_axis_tkeep, 
	output wire 									m_axis_tuser 
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
// detect edges of EnableSampleGeneration
//
/////////////////////////////////////////////////

reg 	enableSampleGenerationR; 

wire 	enableSampleGenerationPosEdge; 
wire 	enableSampleGenerationNegEdge; 

always @(posedge Clk) 
	if ( ! ResetL ) begin 
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
	if ( ! ResetL ) begin 
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

wire 			dataIsBeingTransferred; 
wire 			lastDataIsBeingTransferred; 

assign dataIsBeingTransferred = m_axis_tvalid & m_axis_tready;
assign lastDataIsBeingTransferred = dataIsBeingTransferred & m_axis_tlast;

/////////////////////////////////////////////////
// 
// packet size 
//
/////////////////////////////////////////////////

reg 	[C_M_AXIS_TDATA_WIDTH-1-2:0]	packetSizeInDwords; 
reg 	[1:0]				validBytesInLastChunk; 

always @(posedge Clk) 
	if ( ! ResetL ) begin 
		packetSizeInDwords <= 0; 
		validBytesInLastChunk <= 0; 
	end 
	else begin 
		if ( enableSampleGenerationPosEdge ) begin 
			packetSizeInDwords <= PacketSize >> 2;
			validBytesInLastChunk <= PacketSize - packetSizeInDwords * 4;
		end 
	end 
	

/////////////////////////////////////////////////
// 
// global counter
//
/////////////////////////////////////////////////
// this is a 32 bits counter which counts up with every successful data transfer. this creates the body of the packets. 

wire [11:0] adc0;
wire [11:0] adc1;
wire cs_n;
wire adc_ready;

assign cs = cs_n;
assign adcData = (dataIsBeingTransferred == 1'b1) ?  {adc1,adc0} : adcData;

wire in_data_ready;
wire eoc_adc;
wire [11:0] adc_result_decimator;
wire adc_result_1_valid;

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

data_decimation#(
    .DATA_IN_WIDTH(12),
    .DATA_OUT_WIDTH(12),
    .DATA_REG_WIDTH(32)
) decimator 
(
	.clk(Clk),
	.rst_n(ResetL),
	.in_data_ready(in_data_ready),
	.in_data_valid(eoc_adc),
	.in_data(adc0),
	.out_data_ready(1'b1),
	.out_data_valid(adc_result_1_valid),
	.out_data(adc_result_decimator),
	.decimate_reg(Decimator)  
);  


wire [15:0] out_data_fir;
wire out_data_valid_fir;

moving_average_fir #
(
	.IN_DATA_WIDTH(12),
	.OUT_DATA_WIDTH(16)
)	mavg_fir
(
	.clk(Clk), 
	.rst(ResetL), 
	.mavg_factor(MavgFactor),
	.in_data_valid(adc_result_1_valid), 
	.in_data(adc_result_decimator),
	.out_data_valid(out_data_valid_fir), 
	.out_data(out_data_fir)
);

reg [15:0] sin;
reg [15:0] cos;

localparam VALUE = 32000/1.647; // reduce by a factor of 1.647 since thats the gain of the system

cordic#
(
	.DATA_WIDTH(16)
) sine_cosine 
(
	.clock(Clk),
	.angle(angle),
	.Amp(VALUE), // amplitude
	.Phase_shift(1'd0),
	.Cos_out(sin),
	.Sin_out(cos)
);

/*
cordic cordic
(
	.clock(Clk),
	.reset(!ResetL),
	.start(1'b1),
	.angle_in(32'hc0000000),
	.cos_out(sin),
	.sin_out(cos)
);*/

reg 	[31:0]		globalCounter; 

always @(posedge Clk)  //cs_n
	if ( ! ResetL ) begin 
		globalCounter <= 0; 
	end 
	else begin 
		if ( dataIsBeingTransferred ) 
			globalCounter <= globalCounter + 1; 
		else 
			globalCounter <= globalCounter; 
	end 

//assign M_AXIS_TDATA = globalCounter; 
assign M_AXIS_TDATA = {8'd0, adc1,adc0}; 

/////////////////////////////////////////////////
// 
// packet counter 
//
/////////////////////////////////////////////////
// this is a counter which counts how many dwords are being transferred for each packet 

reg 	[29:0]		packetCounter; 

always @(negedge cs_n) // cs_n
	if ( ! ResetL ) begin 
		packetCounter <= 0; 
	end 
	else begin 
		if ( lastDataIsBeingTransferred ) begin 
			packetCounter <= 0; 
		end 
		else if ( dataIsBeingTransferred ) begin 
			packetCounter <= packetCounter + 1; 
		end 
		else begin 
			packetCounter <= packetCounter; 
		end 
	end 

/////////////////////////////////////////////////
// 
// TVALID 
//
/////////////////////////////////////////////////
// generation of TVALID signal 
// if the fsm is in active state, then we generate packets 

assign m_axis_tvalid = ( (fsm_currentState == `FSM_STATE_ACTIVE) || (fsm_currentState == `FSM_STATE_WAIT_END) ) ? 1 : 0; 

/////////////////////////////////////////////////
// 
// TLAST
//
/////////////////////////////////////////////////

assign m_axis_tlast = (validBytesInLastChunk == 0) ? ( ( packetCounter == (packetSizeInDwords-1) ) ? 1 : 0 ) : 
			( ( packetCounter == packetSizeInDwords ) ? 1 : 0 ); 

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

endmodule
