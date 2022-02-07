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

module ad9226_v1_s_axis #
(
	// Users to add parameters here
	// User parameters ends
	// Do not modify the parameters beyond this line

	// AXI4Stream sink: Data Width
	parameter integer C_S_AXIS_TDATA_WIDTH	= 32
)
(
	// Users to add ports here
	output 	reg 	[31:0]		TotalReceivedPacketData,
	output 	reg 	[31:0]		TotalReceivedPackets,
	output 	reg 	[31:0]		LastReceivedPacket_head,
	output 	reg 	[31:0]		LastReceivedPacket_tail,
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
		
		if ( S_AXIS_TVALID && S_AXIS_TLAST ) begin 
			TotalReceivedPacketData <= TotalReceivedPacketData + packetSizeCounter + numberOfValidBytes; 
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

reg 		headIsGoingToArrive; 
reg	[31:0]	lastReceivedPacket_headR; 

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
			
endmodule
