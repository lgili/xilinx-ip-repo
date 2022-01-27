
`timescale 1 ns / 1 ps

	module ad9226_v1_m_axis #
	(
		// Users to add parameters here
        parameter ADC_DATA_WIDTH = 12,       
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 64,
		// Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input wire  clk_25m,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_1,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_2,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_3,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_trigger,
		// otr out of range, indicates when the input is out of limits of thw adc
		//input wire [(ADC_TRIGGER_ON)-1:0] otr,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_1,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_2,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_3,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_trigger,        
        //output wire eoc,
		
		
		
		input 	wire						EnableSampleGeneration, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]		PacketSize, 
		input 	wire 	[7:0]					PacketRate, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]		PacketPattern,

		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  						M_AXIS_ACLK,
		input wire  						M_AXIS_ARESETN,
		output wire  						M_AXIS_TVALID,
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] 		M_AXIS_TDATA,
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] 		M_AXIS_TSTRB,
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
// global counter
//
/////////////////////////////////////////////////
// this is a 32 bits counter which counts up with every successful data transfer. this creates the body of the packets. 

wire [11:0] adc_result_1;
wire [11:0] adc_result_2;
wire [11:0] adc_result_3;
wire [11:0] adc_result_4;
wire eoc;
wire adc_ready;

assign cs = cs_n;
assign adcData = (dataIsBeingTransferred == 1'b1) ?  {adc1,adc0} : adcData;

    // ADC instance
ad_9226#(
	.ADC_DATA_WIDTH(ADC_DATA_WIDTH))
   ADC    (
        .clk(Clk),
        .rst_n(ResetL),
        .clk_sample(clk_25m),
        .ready(enableSampleGenerationR),        
        .eoc(eoc),
        .data_in0(adc_1),
        .data_in1(adc_2),
        .data_in2(adc_2),
        .data_in3(adc3_3),
        .data_out0(adc_result_1), 
        .data_out1(adc_result_2),
        .data_out2(adc_result_3),
        .data_out3(adc_result_4)             
    );

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
assign M_AXIS_TDATA =  (C_M_AXIS_TDATA_WIDTH == 64) ? {16'd0,adc_result_4, adc_result_3, adc_result_2, adc_result_1} : {8'd0, adc_result_2, adc_result_1}; 

/////////////////////////////////////////////////
// 
// packet counter 
//
/////////////////////////////////////////////////
// this is a counter which counts how many dwords are being transferred for each packet 

reg 	[29:0]		packetCounter; 

always @(posedge eoc) // cs_n
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

assign M_AXIS_TVALID = ( (fsm_currentState == `FSM_STATE_ACTIVE) || (fsm_currentState == `FSM_STATE_WAIT_END) ) ? 1 : 0; 

/////////////////////////////////////////////////
// 
// TLAST
//
/////////////////////////////////////////////////

assign M_AXIS_TLAST = (validBytesInLastChunk == 0) ? ( ( packetCounter == (packetSizeInDwords-1) ) ? 1 : 0 ) : 
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
