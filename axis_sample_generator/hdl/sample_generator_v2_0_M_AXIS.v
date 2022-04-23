// Sadri - may - 22 - 2016 - Updated so that the C_M_AXIS_TDATA_WIDTH really defines the width of output data. 
// Sadri - may - 05 - 2015 - updated ! 
// Sadri - may - 03 - 2015 - created ! 

// this is the axi stream master plug for our sample generator 

`timescale 1 ns / 1 ps

	module sample_generator_v2_0_M_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input 	wire						EnableSampleGeneration, 
		input 	wire 	[31:0]					PacketSize, 
		input 	wire 	[7:0]					PacketRate, 
		input 	wire 	[31:0]					PacketPattern,
		input 	wire 	[31:0]					NumberOfPacketsToSend,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  						M_AXIS_ACLK,
		input wire  						M_AXIS_ARESETN,
		output wire  						M_AXIS_TVALID,
		output wire 	[C_M_AXIS_TDATA_WIDTH-1 : 0] 		M_AXIS_TDATA,
		output wire 	[(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	M_AXIS_TSTRB,
		output wire  						M_AXIS_TLAST,
		input wire  						M_AXIS_TREADY,
		output wire 	[(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	M_AXIS_TKEEP,
		output wire 						M_AXIS_TUSER
	);
	
/////////////////////////////////////////////////
// 
// Clk and ResetL
//
/////////////////////////////////////////////////
wire 		Clk; 
wire 		ResetL; 

assign Clk = M_AXIS_ACLK; 
assign ResetL = M_AXIS_ARESETN; 

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
			if ( enableSampleGenerationNegEdge || ( sentPacketCounter == (NumberOfPacketsToSend-1) )) begin 
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

assign dataIsBeingTransferred = M_AXIS_TVALID & M_AXIS_TREADY;
assign lastDataIsBeingTransferred = dataIsBeingTransferred & M_AXIS_TLAST;

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
	
// assign packetSizeInDwords = PacketSize >> 2; 
// assign validBytesInLastChunk = PacketSize - packetSizeInDwords * 4; 

/////////////////////////////////////////////////
// 
// global counterdataIsBeingTransferred
//
/////////////////////////////////////////////////
// this is a C_M_AXIS_TDATA_WIDTH bits counter which counts up with every successful data transfer. this creates the body of the packets. 

reg 	[C_M_AXIS_TDATA_WIDTH-1:0]		globalCounter; 

always @(posedge Clk) 
	if ( ! ResetL ) begin 
		globalCounter <= 0; 
	end 
	else begin 
		if ( dataIsBeingTransferred ) 
			globalCounter <= globalCounter + 1; 
		else 
			globalCounter <= globalCounter; 
	end 

assign M_AXIS_TDATA = packetDWORDCounter; 

/////////////////////////////////////////////////
// 
// packet counter 
//
/////////////////////////////////////////////////
// this is a counter which counts how many dwords are being transferred for each packet 

reg 	[29:0]		packetDWORDCounter; 

always @(posedge Clk) 
	if ( ! ResetL ) begin 
		packetDWORDCounter <= 0; 
	end 
	else begin 
		if ( lastDataIsBeingTransferred ) begin 
			packetDWORDCounter <= 0; 
		end 
		else if ( dataIsBeingTransferred ) begin 
			packetDWORDCounter <= packetDWORDCounter + 1; 
		end 
		else begin 
			packetDWORDCounter <= packetDWORDCounter; 
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

reg 	[7:0]		packetRate_Counter; 
wire 			packetRate_allowData;

always @(posedge Clk)
	if ( ! ResetL ) begin 
		packetRate_Counter <= 0; 
	end 
	else begin 
		packetRate_Counter <= packetRate_Counter + 1; 
	end 

assign packetRate_allowData = ( packetRate_Counter >= PacketRate ) ? 1 : 0; 

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

/////////////////////////////////////////////////
// 
// TLAST
//
/////////////////////////////////////////////////

assign M_AXIS_TLAST = (validBytesInLastChunk == 0) ? ( ( packetDWORDCounter == (packetSizeInDwords-1) ) ? 1 : 0 ) : 
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

endmodule
