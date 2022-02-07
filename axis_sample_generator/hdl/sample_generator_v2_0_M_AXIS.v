// Sadri - may - 05 - 2015 - updated ! 
// Sadri - may - 03 - 2015 - created ! 

// this is the axi stream master plug for our sample generator 

`timescale 1 ns / 1 ps

	module sample_generator_v2_0_M_AXIS #
	(
		// Users to add parameters here
        parameter integer MAX_VALUE_COUNTER	= 65000,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		output wire [2:0]  state,
		input   wire      trigger,
		input wire        clk_sample,   		
		output  reg irq,
		input 	wire						EnableSampleGeneration, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]		PacketSize, 
		input 	wire 	[7:0]					EnablePacket, 
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]		ConfigPassband,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	DMABaseAddr,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	TriggerLevel,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	ConfigSampler,
		input 	wire 	[C_M_AXIS_TDATA_WIDTH-1:0]	DataFromArm,
		
		output   wire    [31:0]              TriggerOffset,  
		output   wire    [31:0]              TriggerEnable,

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
wire trigger_acq;
wire triggerLevel_value;
wire out_data_valid;
wire [C_M_AXIS_TDATA_WIDTH-1 : 0] out_datafilter;

parameter SIZE = 12468;
integer i;
integer sin_data;
reg  signed [15:0] in_data_a;
reg  signed [15:0] rom_memory [SIZE-1:0];

initial begin
   $readmemh("sin_60_bad.mem", rom_memory);  //sin_data = $fopen("/home/lgili/Documents/FPGA/marciomoura-tcc-fpga/DE10_NANO_SoC_GHRD/design_files/sin_60hz_wnoise.txt","r");
end	
	
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
		      if(trigger_comb == 1'b1 || trigger == 1'b0 )
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

reg 	[31:0]		globalCounter;



//assign  irq = ~CanEnable ;

always @(posedge clk_sample) 
	if ( ! ResetL || CanEnable ==1'b0 ) begin 
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
	
  
//At every positive edge of the clock, output a sine wave sample.
always@(posedge Clk)
begin
    in_data_a = rom_memory[i];
    i = i+ 1;
    if(i == SIZE)
        i = 0;
end

assign triggerLevel_value = (TriggerLevel == 0) ? 65350 : TriggerLevel;
assign trigger_comb = (ConfigSampler[1] == 0) ? 0 : trigger_acq;

trigger_level_acq #(.DATA_WIDTH(16),
	               .TWOS_COMPLEMENT(0))		
					trigger_dut
					(.rst(!ResetL),
				    .clk(Clk),
				    .in_data_valid(M_AXIS_TVALID),
				    .in_data(globalCounter[15:0]),
				    .trigger_level(triggerLevel_value),
					.in_dma_master_address(packetCounter),
				    .out_data_offset(TriggerOffset),
					.trigger_response(TriggerEnable),
					.trigger(trigger_acq));
					
					 
//	trigger_level_signed	#(.DATA_WIDTH(16),	
//							  .MEMORY_ADDR_LEN(32))
				
//							trigger_acquisition
							
//							(.rst(!ResetL),
//							.clk(Clk),
//							.in_data_valid(M_AXIS_TVALID), // && trigger_en_reg
//							.in_data(in_data_a),
//							.in_dma_master_address(DMABaseAddr),
//							.trigger_level(TriggerLevel),
//							.trigger_response(TriggerEnable),
//							.out_data_offset(TriggerOffset)
//							);
							
//	passband_filter_new passband(.rst(!ResetL),
//                                .clk(Clk),
//                                .in_data_valid(M_AXIS_TVALID),
//                                .in_data(sin_data),
//                                .out_data_valid(out_data_valid),
//                                .out_data(out_data),
//                                .in_coeff_a1(-32'd1073738109),
//                                .in_coeff_a2(32'd536867332),
//                                .in_coeff_b0(32'd1789),
//                                .in_coeff_b2(-32'd1789),
//                                .config_reg(ConfigPassband)
//                                );
                                
                                
//     zero_crossing_detector			#(.DATA_WIDTH(46))
//											zcd_dut
//											(.clk(Clk),
//											.rst(!ResetL),
//											.in_data_valid(out_data_valid),
//											.in_data(out_data), 
//											.out_data_valid(out_number_samples_valid),
//											.out_number_samples(out_number_samples),
//											.int_start(int_start),
//											.int_stop(int_stop),
//											.config_reg(config_reg)
//											);                           

assign M_AXIS_TDATA = globalCounter; 

/////////////////////////////////////////////////
// 
// packet counter 
//
/////////////////////////////////////////////////
// this is a counter which counts how many dwords are being transferred for each packet 

reg 	[29:0]		packetCounter; 

always @(posedge Clk) 
	if ( ! ResetL || CanEnable ==1'b0 ) begin 
		packetCounter <= 0; 
	end 
	else begin 
		if ( lastDataIsBeingTransferred || CanEnable == 1'b0 ) begin 
			packetCounter <= 0; 
		end 		
		else if ( dataIsBeingTransferred  && CanEnable == 1'b1) begin 
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

assign M_AXIS_TVALID = ( (fsm_currentState == `FSM_STATE_ACTIVE) || (fsm_currentState == `FSM_STATE_WAIT_END) || (CanEnable == 1'b1)) ? 1 : 0; 

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
