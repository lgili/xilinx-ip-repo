
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

//`define POST_SYNTHESIS_SIMULATION 1
module ad7276_v3_0 #
(
	// Users to add parameters here
	parameter ADC_LENGTH = 12,
	parameter ADC_QTD = 1,
	// User parameters ends
	// Do not modify the parameters beyond this line


	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 5,
	
	
	parameter integer C_M_AXIS_START_COUNT	= 32
	
)
(
	// Users to add ports here
	input  wire		    clk_48MHz,           
	input  wire  [2*ADC_QTD-1:0]   inData,           
	output wire [2*ADC_QTD*ADC_LENGTH-1:0]   adcData, 
	output wire [2*ADC_QTD*ADC_LENGTH-1:0]   adcData_fil,            
	
   
	output wire [ADC_QTD-1:0]     cs,
	output wire [ADC_QTD-1:0]     sclk,

	output wire [2*ADC_QTD-1:0]      dataready,
	


	// Ports of Axi Slave Bus Interface S00_AXI
	input wire                           ADC_CLK,
	input wire                           ARESETN,
						
	
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready
	
	
);
	
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////
wire 	[7:0]	packetRate; 
wire	[31:0]	packetPattern; 

wire 	[31:0]	totalReceivedPacketData; 
wire 	[31:0]	totalReceivedPackets; 
wire 	[31:0]	lastReceivedPacket_head; 
wire 	[31:0]	lastReceivedPacket_tail; 

/*reg 		enableSampleGeneration; 
reg 	[31:0]	packetSize; 

initial begin 
#1000
	enableSampleGeneration = 1; 
end 

initial begin 
	packetSize = 31; 
end 
*/

wire 		enableSampleGeneration; 
wire 	[31:0]	packetSize; 	
	
	
// Instantiation of Axi Bus Interface S_AXI
	ad7276_v1_s_axi # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) ad7276_v1_s_axi_inst (
	
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			    ( packetSize ), 
		.PacketRate			        ( packetRate ), 
		.PacketPattern 			    ( packetPattern ), 

		.TotalReceivedPacketData 	( totalReceivedPacketData ), 
		.TotalReceivedPackets 		( totalReceivedPackets ), 
		.LastReceivedPacket_head 	( lastReceivedPacket_head ), 
		.LastReceivedPacket_tail 	( lastReceivedPacket_tail ), 
		
		.S_AXI_ACLK			(ADC_CLK),
		.S_AXI_ARESETN			(ARESETN),
		.S_AXI_AWADDR			(s00_axi_awaddr),
		.S_AXI_AWPROT			(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);	




	endmodule
