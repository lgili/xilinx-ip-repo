
`timescale 1 ns / 1 ps
	module ad9226_v1_m_axis #
	(
		// Users to add parameters here
		parameter integer MAX_VALUE_COUNTER	= 65000,
        parameter ADC_DATA_WIDTH = 12,       
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input wire clk_25m,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_1,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_2,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_3,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_trigger,
		output reg irq,
		input wire button, // 0 is pressed
		output wire trigger_acq,
		output wire [2:0]  state,
		output wire eoc,
		//output wire AXIS_CLK,
		//output wire ARESETN_AXIS_M,
		
		input 	wire						EnableSampleGeneration, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]		PacketSize, 
		input 	wire 	[7:0]					EnablePacket, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]		ConfigPassband,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	DMABaseAddr,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	TriggerLevel,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	ConfigSampler,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	DataFromArm,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	Decimator,
		
		output   wire    [31:0]              TriggerOffset,  
		output   wire    [31:0]              TriggerEnable,
		// otr out of range, indicates when the input is out of limits of thw adc
		//input wire [(ADC_TRIGGER_ON)-1:0] otr,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_1,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_2,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_3,
        //output wire [ADC_DATA_WIDTH-1 : 0] adc_result_trigger,   
		
		

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
// SENo and trigger
//
/////////////////////////////////////////////////	
wire trigger_comb;

wire triggerLevel_value;
wire out_data_valid;
wire [C_M_AXIS_TDATA_WIDTH-1 : 0] out_datafilter;
	
/////////////////////////////////////////////////
// 
// Clk and ResetL
//
/////////////////////////////////////////////////
wire 		Clk; 
wire 		ResetL; 

assign Clk = M_AXIS_ACLK; 
assign ResetL = M_AXIS_ARESETN;

//assign ARESETN_AXIS_M = (!M_AXIS_ARESETN || (EnableSampleGeneration == 1)) ? 0: 1;

/////////////////////////////////////////////////
// 
// detect edges of EnableSampleGeneration
//
/////////////////////////////////////////////////

reg 	enableSampleGenerationR; 

wire 	enableSampleGenerationPosEdge; 
wire 	enableSampleGenerationNegEdge; 

wire        EnableSampleGenerationSignal;
reg         CanEnable = 1;

assign EnableSampleGenerationSignal = (CanEnable == 1) ? EnableSampleGeneration : 0;

always @(posedge Clk) 
	if ( ! ResetL ) begin 
		enableSampleGenerationR <= 0; 
	end 
	else begin 
		enableSampleGenerationR <= EnableSampleGenerationSignal; 
	end 
	
assign enableSampleGenerationPosEdge = EnableSampleGenerationSignal && (! enableSampleGenerationR);
assign enableSampleGenerationNegEdge = (! EnableSampleGenerationSignal) && enableSampleGenerationR;

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

`define FSM_TRIGGER_STATE_IDLE      0
`define FSM_TRIGGER_STATE_WAITING   1
`define FSM_TRIGGER_STATE_ACTIVE    2
`define FSM_TRIGGER_STATE_END       3

reg     [2:0]       fsm_trigger_currentState;
reg     [2:0]       fsm_trigger_nexttState;
reg     [31:0]      triggerCount;
reg     [31:0]      tlastCount;

assign state = fsm_trigger_currentState;

always @(posedge Clk) 
	if ( ResetL == 1'b0) begin 
		fsm_trigger_currentState <= `FSM_TRIGGER_STATE_IDLE; 
		fsm_trigger_nexttState <= `FSM_TRIGGER_STATE_IDLE; 
		tlastCount <= 0;
		triggerCount <= 0;
	end 
	else begin 
	
		case ( fsm_trigger_currentState )
		`FSM_TRIGGER_STATE_IDLE: begin
		      if(trigger_comb == 1'b1 || button == 1'b0 )
		          fsm_trigger_currentState <=  `FSM_TRIGGER_STATE_WAITING;
		      else
		          fsm_trigger_currentState <=  `FSM_TRIGGER_STATE_IDLE ;             
		end
		`FSM_TRIGGER_STATE_WAITING: begin
		      // count tlast (qtd of packages send after trigged)
		      if(M_AXIS_TLAST == 1) begin
		           tlastCount <= tlastCount + 1; 
		           
		           if (tlastCount >= 32'h3) begin		      
		              CanEnable <= 0;
		              fsm_trigger_currentState <=    `FSM_TRIGGER_STATE_ACTIVE;  
		           end
		           else begin		          
		               fsm_trigger_currentState <=    `FSM_TRIGGER_STATE_WAITING;
		           end 
		      end      
		      
		      else begin		          
		          fsm_trigger_currentState <=    `FSM_TRIGGER_STATE_WAITING;
		      end      
		end
		`FSM_TRIGGER_STATE_ACTIVE: begin
		      CanEnable <= 0;
		      if(triggerCount >= 32'h3) begin
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
		     if(EnablePacket == 1'b1) begin		      
		         fsm_trigger_currentState <= `FSM_TRIGGER_STATE_IDLE;
		         CanEnable <= 1;
		     end 
		      else begin
		         fsm_trigger_currentState <= `FSM_TRIGGER_STATE_END;
		         CanEnable <= 0;
		     end        		
		end      
		
		
	    default: begin 
			fsm_trigger_currentState <= `FSM_TRIGGER_STATE_IDLE;
			fsm_trigger_nexttState <= `FSM_TRIGGER_STATE_IDLE; 
		end 
		endcase 
	end 
	
always @(posedge Clk) 
	if ( ! ResetL || CanEnable ==1'b0 ) begin 
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

assign dataIsBeingTransferred = ResetL && M_AXIS_TREADY;
assign lastDataIsBeingTransferred = dataIsBeingTransferred & M_AXIS_TLAST;

/////////////////////////////////////////////////
// 
// packet size 
//
/////////////////////////////////////////////////

reg 	[C_M_AXIS_TDATA_WIDTH-1-2:0]	packetSizeInDwords; 
reg 	[1:0]				validBytesInLastChunk; 

always @(posedge Clk) 
	if ( ! ResetL || CanEnable ==1'b0 ) begin 
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
wire adc_result_1_ready;
wire adc_result_2_ready;
wire adc_result_3_ready;
wire adc_result_4_ready;
wire adc_result_1_valid;
wire [15:0] adc_result_decimator;
//wire eoc;
wire adc_ready;
wire in_data_ready;

//assign irq = ~button ;
//assign adcData = (dataIsBeingTransferred == 1'b1) ?  {adc1,adc0} : adcData;

    // ADC instance
ad_9226#(
	.ADC_DATA_WIDTH(ADC_DATA_WIDTH))
   ADC    (
        .clk(Clk),
        .rst_n(ResetL),
        .clk_sample(clk_25m),
        .ready(in_data_ready),        
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
    
 data_decimation#(
    .DATA_IN_WIDTH(12),
    .DATA_OUT_WIDTH(12),
    .DATA_REG_WIDTH(32)
 ) decimator 
 (
     .clk(clk_25m),
     .rst_n(ResetL),
     .in_data_ready(in_data_ready),
     .in_data_valid(1'b1),
     .in_data(adc_result_1),
     .out_data_ready(1'b1),
     .out_data_valid(adc_result_1_valid),
     .out_data(adc_result_decimator),
     .decimate_reg(Decimator)  
);   

//assign AXIS_CLK = M_AXIS_ACLK; //adc_result_1_valid;
    
assign triggerLevel_value = (TriggerLevel == 0) ? 65350 : TriggerLevel;
assign trigger_comb = (ConfigSampler[1] == 0) ? 0 : trigger_acq;

trigger_level_acq #(.DATA_WIDTH(12),
	               .TWOS_COMPLEMENT(0))		
					trigger_dut
					(.rst(!ResetL),
				    .clk(Clk),
				    .in_data_valid(clk_25m),
				    .in_data(adc_result_1),
				    .trigger_level(TriggerLevel),
					.in_dma_master_address(packetCounter),
				    .out_data_offset(TriggerOffset),
					.trigger_response(TriggerEnable),
					.trigger(trigger_acq));    

reg 	[31:0]		globalCounter; 



//assign M_AXIS_TDATA = globalCounter; 
assign M_AXIS_TDATA =  (C_M_AXIS_TDATA_WIDTH == 64) ? {16'd0,adc_result_4, adc_result_3, adc_result_2, adc_result_1} : {8'd0, adc_result_1, adc_result_decimator}; 

always @(posedge Clk) 
	if ( ! ResetL ) begin 
		globalCounter <= 0; 
		irq <= 1'b0;		
	end 
	else begin 
	
	  case ( fsm_trigger_currentState )
		`FSM_TRIGGER_STATE_IDLE: begin
		      irq <= 1'b0;
		      if ( dataIsBeingTransferred )  begin
		          if(globalCounter >= MAX_VALUE_COUNTER)
		              globalCounter <= 0;		           
		          else        begin
			             if(ConfigSampler[0] == 0)
			                 globalCounter <= globalCounter + 1;
			             else
			                 globalCounter <= DataFromArm;    
			      end
		      end
		      else 
			     globalCounter <= globalCounter; 
		end   
		`FSM_TRIGGER_STATE_WAITING: begin
		          globalCounter <= 32'h1b207; 
		          irq <= 1'b0;
		end
		`FSM_TRIGGER_STATE_ACTIVE: begin
            irq <= 1'b1;
            globalCounter <= globalCounter; 		
		end
		`FSM_TRIGGER_STATE_END: begin
		    irq <= 1'b0;  
		    globalCounter <= globalCounter;
		end
        default: begin 
               irq <= 1'b0;
               globalCounter <= globalCounter; 
            end 
	  endcase 	  	       
	    
	          
//		if ( dataIsBeingTransferred )  begin		      
//		    if(triggerCount != 0)
//		         globalCounter <= 32'h1b207;  
//		    else if(globalCounter >= MAX_VALUE_COUNTER)
//		          globalCounter <= 0;		           
//		    else        
//			     globalCounter <= globalCounter + 1;
//			end    
			  
//		else 
//			globalCounter <= globalCounter; 
	end 

/////////////////////////////////////////////////
// 
// packet counter 
//
/////////////////////////////////////////////////
// this is a counter which counts how many dwords are being transferred for each packet 

reg 	[29:0]		packetCounter; 

always @(posedge clk_25m) // cs_n
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
// just send data on clk 25 Mhz
assign M_AXIS_TVALID = (((fsm_currentState == `FSM_STATE_ACTIVE) || (fsm_currentState == `FSM_STATE_WAIT_END)) && (eoc ==1) )? 1 : 0;  
//assign M_AXIS_TVALID = (( (fsm_currentState == `FSM_STATE_ACTIVE) || (fsm_currentState == `FSM_STATE_WAIT_END) ) )? 1 : 0; 

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