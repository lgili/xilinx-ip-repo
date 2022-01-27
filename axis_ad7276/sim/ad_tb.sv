`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2022 05:52:43 PM
// Design Name: 
// Module Name: ad_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module ad_tb (); 

logic 		m_axis_tvalid; 
logic 		m_axis_tready; 
logic 	[31:0]	m_axis_tdata;
logic 	[3:0]	m_axis_tstrb; 
logic 		m_axis_tlast; 
logic 	[3:0]	m_axis_tkeep; 
logic 		m_axis_tuser; 

logic 		Clk;
logic 	[63:0]	globalCounter;
logic 		ResetL; 
logic 		enableSampleGeneration; 
logic 	[31:0]	packetSize; 
logic 	[31:0]	totalReceivedPacketData; 
logic 	[31:0]	totalReceivedPackets; 
logic 	[31:0]	lastReceivedPacket_head;
logic 	[31:0]	lastReceivedPacket_tail;

////////////////////////////////////////////////////////////////////
//
// sample generator
//
////////////////////////////////////////////////////////////////////

ad7276_v3_0 #(
.C_S00_AXI_DATA_WIDTH ( 32 ),
.C_S00_AXI_ADDR_WIDTH ( 5 ),
.C_M_AXIS_START_COUNT ( 32) ) sample_generator_v2_0_Ins (
.s00_axi_aclk		(Clk),
.s00_axi_aresetn		(ResetL),
.s00_axi_awaddr		(),
.s00_axi_awprot		(),
.s00_axi_awvalid		(),
.s00_axi_awready		(),
.s00_axi_wdata		(),
.s00_axi_wstrb		(),
.s00_axi_wvalid		(),
.s00_axi_wready		(),
.s00_axi_bresp		(),
.s00_axi_bvalid		(),
.s00_axi_bready		(),
.s00_axi_araddr		(),
.s00_axi_arprot		(),
.s00_axi_arvalid		(),
.s00_axi_arready		(),
.s00_axi_rdata		(),
.s00_axi_rresp		(),
.s00_axi_rvalid		(),
.s00_axi_rready		(),

.s_axis_aclk		(Clk),
.s_axis_aresetn		(ResetL),
.s_axis_tready		(s_axis_tready),
.s_axis_tdata		(s_axis_tdata),
.s_axis_tstrb		(s_axis_tstrb),
.s_axis_tkeep		(s_axis_tkeep),
.s_axis_tlast		(s_axis_tlast),
.s_axis_tvalid		(s_axis_tvalid),

.m_axis_aclk		(Clk),
.m_axis_aresetn		(ResetL),
.m_axis_tvalid		(m_axis_tvalid),
.m_axis_tdata		(m_axis_tdata),
.m_axis_tstrb		(m_axis_tstrb),
.m_axis_tlast		(m_axis_tlast),
.m_axis_tready		(m_axis_tready), 
.m_axis_tkeep		(m_axis_tkeep), 
.m_axis_tuser		(m_axis_tuser)
);

////////////////////////////////////////////////////////////////////
//
// Clk
//
////////////////////////////////////////////////////////////////////

initial begin 
	Clk = 0; 
	forever #10 Clk = ~ Clk; 
end 

initial begin 
	globalCounter = 0; 
end 

always @(posedge Clk) 
	globalCounter <= globalCounter + 1; 
	
initial begin 
	ResetL = 0; 
end 

always @(posedge Clk) 
	if ( globalCounter == 10 ) 
		ResetL = 1; 

assign m_axis_tready = s_axis_tready; 
assign s_axis_tdata = m_axis_tdata; 
assign s_axis_tstrb = m_axis_tstrb; 
assign s_axis_tkeep = m_axis_tkeep; 
assign s_axis_tlast = m_axis_tlast; 
assign s_axis_tvalid = m_axis_tvalid; 

endmodule 