

`timescale 1 ns / 1 ps

	module ad7276_m_axis #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32,
		parameter NUM_CHANNELS = 16,
		parameter DATA_WIDTH_ADC = 16
	)
	(
		// Users to add ports here
		input 	wire						    					EnableSampleGeneration, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]					PacketSize, 
		input 	wire 	[7:0]										PacketRate, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]					NumberOfPacketsToSend,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]					TriggerLevelValue,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]					TriggerChannel,
		output 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	                TriggerPosMemory,
		
		input   wire 	[(DATA_WIDTH_ADC*NUM_CHANNELS)-1:0] 		InData,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  						m_axis_aclk,
		input wire  						m_axis_aresetn,
		output wire  						m_axis_tvalid,
		output wire 	[C_M_AXIS_TDATA_WIDTH-1 : 0] 		m_axis_tdata,
		output wire 	[(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	m_axis_tstrb,
		output wire  						m_axis_tlast,
		input wire  						m_axis_tready,
		output wire 	[(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 	m_axis_tkeep,
		output wire 						m_axis_tuser
	);
	
/////////////////////////////////////////////////
// 
// Clk and ResetL
//
/////////////////////////////////////////////////
wire 		Clk; 
wire 		ResetL; 

assign Clk = m_axis_aclk; 
assign ResetL = m_axis_aresetn; 

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
			packetSizeInDwords <= PacketSize >> 2 ;
			validBytesInLastChunk <= PacketSize  - packetSizeInDwords * 4;
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

// assign m_axis_tdata = packetDWORDCounter; 

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

assign m_axis_tvalid = ( packetRate_allowData && ( (fsm_currentState == `FSM_STATE_ACTIVE) || (fsm_currentState == `FSM_STATE_WAIT_END) ) ) ? 1 : 0; 

/////////////////////////////////////////////////
// 
// TLAST
//
/////////////////////////////////////////////////

assign m_axis_tlast = (validBytesInLastChunk == 0) ? ( ( packetDWORDCounter == (packetSizeInDwords-1) ) ? 1 : 0 ) : 
			( ( packetDWORDCounter == packetSizeInDwords ) ? 1 : 0 ); 

/////////////////////////////////////////////////
// 
// TSTRB
//
/////////////////////////////////////////////////

assign m_axis_tstrb =   ( (! lastDataIsBeingTransferred) && dataIsBeingTransferred ) ? 4'hf :
			( lastDataIsBeingTransferred && (validBytesInLastChunk == 3) ) ? 4'h7 :
			( lastDataIsBeingTransferred && (validBytesInLastChunk == 2) ) ? 4'h3 : 
			( lastDataIsBeingTransferred && (validBytesInLastChunk == 1) ) ? 4'h1 : 4'hf; 
			
/////////////////////////////////////////////////
// 
// TKEEP and TUSER 
//
/////////////////////////////////////////////////

assign m_axis_tkeep = m_axis_tstrb; // 4'hf; 
assign m_axis_tuser = 0; 

localparam integer CTR_WIDTH = NUM_CHANNELS == 1? 1 : $clog2(NUM_CHANNELS);
localparam CTR_MAX = (NUM_CHANNELS>>1)-1;
reg [CTR_WIDTH-1:0] ctr;

always @(posedge Clk)
begin
	if (ResetL == 0)
	begin
		ctr <= 0;
	end else begin
		if (m_axis_tready && m_axis_tvalid)
		begin
			if (ctr == CTR_MAX)
			begin
				ctr <= 0;
			end else begin
				ctr <= ctr + 1;
			end
		end
	end
end

assign m_axis_tdata = InData[(1+ctr)*(C_M_AXIS_TDATA_WIDTH)-1 -: C_M_AXIS_TDATA_WIDTH];



wire [15:0] channel_data;

assign channel_data = InData[(1+TriggerChannel)*(C_M_AXIS_TDATA_WIDTH)-1 -: C_M_AXIS_TDATA_WIDTH];
////////////////////////////////
trigger_acq#(
	.DATA_WIDTH(16),			 
	.MEMORY_ADDR_LEN(32)
) trigger_inst(
            .rstn(ResetL),
			.clk(Clk),
			.in_data_valid(m_axis_tready && m_axis_tvalid),
			.in_data(channel_data),
			.in_dma_master_address(packetDWORDCounter),
			.trigger_level(TriggerLevelValue),    // HPS Register
			.trigger_response(), // HPS Register 
			.out_data_offset(TriggerPosMemory)  // HPS Register 
);
endmodule
