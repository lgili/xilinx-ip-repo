// Sadri - May - 26 - 2016 - I want the sample generator to be able to reset the fifo 
// Sadri - May - 25 - 2016 - Added a signal AsynchFIFO_AlmostFull which shows if the axi stream asynchronous fifo has got full. this situation should never happen.
// Sadri - May - 22 - 2016 - Updated so that the width of AXI stream master and slave ports can be configured through the IP parameters. 
// Sadri - may - 11 - 2015 - bug removal, also updated the design to be able to do also post-synthesis simulation 
// Sadri - may - 02 - 2015 - updated ! 

`timescale 1 ns / 1 ps

// `define POST_SYNTHESIS_SIMULATION 1

	module sample_generator_v2_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 5,

		// Parameters of Axi Slave Bus Interface S_AXIS
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M_AXIS
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input 	wire 	AsynchFIFO_AlmostFull,
		output 	wire 	AsynchFIFO_ResetN,
		output 	wire 	enableSampleGeneration, 
		
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI
		input wire  s_axi_aclk,
		input wire  s_axi_aresetn,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
		input wire [2 : 0] s_axi_awprot,
		input wire  s_axi_awvalid,
		output wire  s_axi_awready,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
		input wire  s_axi_wvalid,
		output wire  s_axi_wready,
		output wire [1 : 0] s_axi_bresp,
		output wire  s_axi_bvalid,
		input wire  s_axi_bready,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
		input wire [2 : 0] s_axi_arprot,
		input wire  s_axi_arvalid,
		output wire  s_axi_arready,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
		output wire [1 : 0] s_axi_rresp,
		output wire  s_axi_rvalid,
		input wire  s_axi_rready,

		// Ports of Axi Slave Bus Interface S_AXIS
		input wire  s_axis_aclk,
		input wire  s_axis_aresetn,
		output wire  s_axis_tready,
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] s_axis_tdata,
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] s_axis_tstrb,
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] s_axis_tkeep,
		input wire  s_axis_tlast,
		input wire  s_axis_tvalid,

		// Ports of Axi Master Bus Interface M_AXIS
		input wire  m_axis_aclk,
		input wire  m_axis_aresetn,
		output wire  m_axis_tvalid,
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] m_axis_tdata,
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] m_axis_tstrb,
		output wire  m_axis_tlast,
		input wire  m_axis_tready, 
		output wire 	[(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] m_axis_tkeep, 
		output wire 	m_axis_tuser
	);
	
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////
wire 	[7:0]				packetRate; 
wire	[31:0]				packetPattern; 
wire	[C_S_AXI_DATA_WIDTH-1:0]	NumberOfPacketsToSend;

wire 	[31:0]				totalReceivedPacketData; 
wire 	[31:0]				totalReceivedPackets; 
wire 	[C_S_AXIS_TDATA_WIDTH-1:0]	lastReceivedPacket_head; 
wire 	[C_S_AXIS_TDATA_WIDTH-1:0]	lastReceivedPacket_tail; 

wire 					errorDetectedInCounter;
wire 	[C_S_AXIS_TDATA_WIDTH-1:0]	errorDetectedCounterValue_prev;
wire 	[C_S_AXIS_TDATA_WIDTH-1:0]	errorDetectedCounterValue_current;

`ifdef POST_SYNTHESIS_SIMULATION
reg 					enableSampleGeneration; 
reg 	[31:0]				packetSize; 

initial begin 
#1000
	enableSampleGeneration = 1; 
end 

initial begin 
	packetSize = 31; 
end 

`else 

// wire 		enableSampleGeneration; 
wire 	[31:0]	packetSize; 

// Instantiation of Axi Bus Interface S_AXI
	sample_generator_v2_0_S_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) sample_generator_v2_0_S_AXI_inst (
	
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			( packetSize ), 
		.PacketRate			( packetRate ), 
		.PacketPattern 			( packetPattern ), 
		.NumberOfPacketsToSend		( NumberOfPacketsToSend ), 
		
		.TotalReceivedPacketData 	( totalReceivedPacketData ), 
		.TotalReceivedPackets 		( totalReceivedPackets ), 
		.LastReceivedPacket_head 	( lastReceivedPacket_head ), 
		.LastReceivedPacket_tail 	( lastReceivedPacket_tail ), 
		
		.ErrorDetectedInCounter 	( errorDetectedInCounter ), 
		.ErrorDetectedCounterValue_current ( errorDetectedCounterValue_current ),
		.ErrorDetectedCounterValue_prev ( errorDetectedCounterValue_prev ),

		.AsynchFIFO_AlmostFull		( AsynchFIFO_AlmostFull ), 
		.AsynchFIFO_ResetN		( AsynchFIFO_ResetN ), 
		
		.S_AXI_ACLK			(s_axi_aclk),
		.S_AXI_ARESETN			(s_axi_aresetn),
		.S_AXI_AWADDR			(s_axi_awaddr),
		.S_AXI_AWPROT			(s_axi_awprot),
		.S_AXI_AWVALID			(s_axi_awvalid),
		.S_AXI_AWREADY			(s_axi_awready),
		.S_AXI_WDATA			(s_axi_wdata),
		.S_AXI_WSTRB			(s_axi_wstrb),
		.S_AXI_WVALID			(s_axi_wvalid),
		.S_AXI_WREADY			(s_axi_wready),
		.S_AXI_BRESP			(s_axi_bresp),
		.S_AXI_BVALID			(s_axi_bvalid),
		.S_AXI_BREADY			(s_axi_bready),
		.S_AXI_ARADDR			(s_axi_araddr),
		.S_AXI_ARPROT			(s_axi_arprot),
		.S_AXI_ARVALID			(s_axi_arvalid),
		.S_AXI_ARREADY			(s_axi_arready),
		.S_AXI_RDATA			(s_axi_rdata),
		.S_AXI_RRESP			(s_axi_rresp),
		.S_AXI_RVALID			(s_axi_rvalid),
		.S_AXI_RREADY			(s_axi_rready)
	);
`endif 

// Instantiation of Axi Bus Interface S_AXIS
	sample_generator_v2_0_S_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S_AXIS_TDATA_WIDTH)
	) sample_generator_v2_0_S_AXIS_inst (
		.TotalReceivedPacketData 	( totalReceivedPacketData ), 
		.TotalReceivedPackets 		( totalReceivedPackets ), 
		.LastReceivedPacket_head 	( lastReceivedPacket_head ), 
		.LastReceivedPacket_tail 	( lastReceivedPacket_tail ), 
		
		.ErrorDetectedInCounter 	( errorDetectedInCounter ), 
		.ErrorDetectedCounterValue_current ( errorDetectedCounterValue_current ),
		.ErrorDetectedCounterValue_prev ( errorDetectedCounterValue_prev ),
		
		.S_AXIS_ACLK			(s_axis_aclk),
		.S_AXIS_ARESETN			(s_axis_aresetn),
		.S_AXIS_TREADY			(s_axis_tready),
		.S_AXIS_TDATA			(s_axis_tdata),
		.S_AXIS_TSTRB			(s_axis_tstrb),
		.S_AXIS_TKEEP			(s_axis_tkeep), 
		.S_AXIS_TLAST			(s_axis_tlast),
		.S_AXIS_TVALID			(s_axis_tvalid)
	);

// Instantiation of Axi Bus Interface M_AXIS
	sample_generator_v2_0_M_AXIS # ( 
		.C_M_AXIS_TDATA_WIDTH(C_M_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M_AXIS_START_COUNT)
	) sample_generator_v2_0_M_AXIS_inst (
	
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			( packetSize ), 
		.PacketRate			( packetRate ), 
		.PacketPattern 			( packetPattern ), 
		.NumberOfPacketsToSend		( NumberOfPacketsToSend ), 
		
		.M_AXIS_ACLK			(m_axis_aclk),
		.M_AXIS_ARESETN			(m_axis_aresetn),
		.M_AXIS_TVALID			(m_axis_tvalid),
		.M_AXIS_TDATA			(m_axis_tdata),
		.M_AXIS_TSTRB			(m_axis_tstrb),
		.M_AXIS_TLAST			(m_axis_tlast),
		.M_AXIS_TREADY			(m_axis_tready),
		.M_AXIS_TKEEP 			( m_axis_tkeep ), 
		.M_AXIS_TUSER 			( m_axis_tuser )
	);

	// Add user logic here

	// User logic ends

	endmodule
