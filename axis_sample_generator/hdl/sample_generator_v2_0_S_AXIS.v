// Sadri - May - 22 - 2016 - Updated so that the C_S_AXIS_TDATA_WIDTH be used for the width of the axi stream data port. 
// Sadri - May - 13 - 2016 - Added error detection for the counter received at the slave port. 
// Sadri - May - 06 - 2015 - updated !

// This is a simple axi stream slave plug which reads the incoming packets and reflects their statistics.

// Author : Mohammadsadegh Sadri 

`timescale 1 ns / 1 ps

module sample_generator_v2_0_S_AXIS #
(
	// Users to add parameters here
	// User parameters ends
	// Do not modify the parameters beyond this line

	// AXI4Stream sink: Data Width
	parameter integer C_S_AXIS_TDATA_WIDTH	= 32
)
(
	// Users to add ports here
	output 	reg 	[31:0]					TotalReceivedPacketData,
	output 	reg 	[31:0]					TotalReceivedPackets,
	output 	reg 	[C_S_AXIS_TDATA_WIDTH-1:0]		LastReceivedPacket_head,
	output 	reg 	[C_S_AXIS_TDATA_WIDTH-1:0]		LastReceivedPacket_tail,
	
	output 	reg 						ErrorDetectedInCounter, 
	output 	reg 	[C_S_AXIS_TDATA_WIDTH-1:0]	 	ErrorDetectedCounterValue_current,
	output 	reg 	[C_S_AXIS_TDATA_WIDTH-1:0]	 	ErrorDetectedCounterValue_prev,
	
	// User ports ends
	// Do not modify the ports beyond this line

	// AXI4Stream sink: Clock
	input wire  S_AXIS_ACLK,
	// AXI4Stream sink: Reset
	input wire  S_AXIS_ARESETN,
	// Ready to accept data in
	output wire  S_AXIS_TREADY,
	// Data in
	input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
	// Byte qualifier
	input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
	input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TKEEP,
	// Indicates boundary of last packet
	input wire  S_AXIS_TLAST,
	// Data is in valid
	input wire  S_AXIS_TVALID
);

/////////////////////////////////////////////////////////////////////////
//
// Clock and Reset 
//
/////////////////////////////////////////////////////////////////////////
wire 		Clk; 
wire 		ResetL; 

assign Clk = S_AXIS_ACLK; 
assign ResetL = S_AXIS_ARESETN;

/////////////////////////////////////////////////////////////////////////
//
// tvalid 
//
/////////////////////////////////////////////////////////////////////////

assign S_AXIS_TREADY = 1; 		// always ready to received data 

/////////////////////////////////////////////////////////////////////////
//
// Total received packet data 
//
/////////////////////////////////////////////////////////////////////////

reg 	[31:0]		packetSizeCounter; 
wire 	[7:0]		numberOfValidBytes;

assign numberOfValidBytes = 	( S_AXIS_TKEEP == 4'hf ) ? 4 : 
				( S_AXIS_TKEEP == 4'h7 ) ? 3 : 
				( S_AXIS_TKEEP == 4'h3 ) ? 2 : 
				( S_AXIS_TKEEP == 4'h1 ) ? 1 : 0; 

always @(posedge Clk) 
	if ( ! ResetL ) begin 
		TotalReceivedPacketData <= 0; 
		packetSizeCounter <= 0; 
	end 
	else begin 
		if ( S_AXIS_TVALID ) begin 
			if ( S_AXIS_TLAST ) begin 
				packetSizeCounter <= 0; 
			end 
			else begin 
				packetSizeCounter <= packetSizeCounter + 4; 
			end 
		end 
		else begin 
			packetSizeCounter <= packetSizeCounter; 
		end 
		
		if ( S_AXIS_TVALID ) begin // && S_AXIS_TLAST ) begin 
			TotalReceivedPacketData <= TotalReceivedPacketData + numberOfValidBytes; // packetSizeCounter + numberOfValidBytes; 
		end 
		else begin 
			TotalReceivedPacketData <= TotalReceivedPacketData;
		end 
		
	end 

/////////////////////////////////////////////////////////////////////////
//
// Total Received Packets 
//
/////////////////////////////////////////////////////////////////////////

always @(posedge Clk)
	if ( ! ResetL ) begin 
		TotalReceivedPackets <= 0; 
	end 
	else begin 
		if ( S_AXIS_TVALID && S_AXIS_TLAST ) 
			TotalReceivedPackets <= TotalReceivedPackets + 1; 
	end 
	
/////////////////////////////////////////////////////////////////////////
//
// Last packet head and tail 
//
/////////////////////////////////////////////////////////////////////////

reg 					headIsGoingToArrive; 
reg	[C_S_AXIS_TDATA_WIDTH-1:0]	lastReceivedPacket_headR; 

always @(posedge Clk)
	if ( ! ResetL ) begin 
		headIsGoingToArrive <= 1; 
	end 
	else begin 
		if ( S_AXIS_TVALID && ( ! S_AXIS_TLAST ) )
			headIsGoingToArrive <= 0; 
		else if ( S_AXIS_TVALID && S_AXIS_TLAST ) 
			headIsGoingToArrive <= 1; 
		else 
			headIsGoingToArrive <= headIsGoingToArrive; 
	end 
	
always @(posedge Clk) 
	if ( ! ResetL ) begin 
		LastReceivedPacket_head <= 0; 
		lastReceivedPacket_headR <= 0; 
		LastReceivedPacket_tail <= 0; 
	end 
	else begin 
		if ( S_AXIS_TVALID ) begin 
			if ( headIsGoingToArrive ) begin 
				lastReceivedPacket_headR <= S_AXIS_TDATA; 
			end 
				
			if ( S_AXIS_TLAST ) begin 
				LastReceivedPacket_tail <= S_AXIS_TDATA;
				LastReceivedPacket_head <= lastReceivedPacket_headR;
			end 
		end 
	end 

/////////////////////////////////////////////////////////////////////////
//
// packet content check 
//
/////////////////////////////////////////////////////////////////////////
// the packets coming back, if counter, we check here to see the counter is incrementing one by one. no data is added and no data is missed. 

always @(posedge Clk)
	if ( ! ResetL ) begin 
		ErrorDetectedInCounter <= 0;
		ErrorDetectedCounterValue_current <= 32'hffffffff; 
		ErrorDetectedCounterValue_prev <= 0;
	end 
	else begin 
	
		if ( S_AXIS_TVALID ) begin
		
			if ( ! ErrorDetectedInCounter ) begin 
			
				ErrorDetectedCounterValue_current <= S_AXIS_TDATA; 
				ErrorDetectedCounterValue_prev <= ErrorDetectedCounterValue_current; 
				
				if ( S_AXIS_TDATA != (ErrorDetectedCounterValue_current+1) ) begin 
					ErrorDetectedInCounter <= 1;
				end 
				
			end 
			else begin 
				ErrorDetectedCounterValue_current <= ErrorDetectedCounterValue_current; 
				ErrorDetectedCounterValue_prev <= ErrorDetectedCounterValue_prev;
			end 
		end 
		
	end 

endmodule
