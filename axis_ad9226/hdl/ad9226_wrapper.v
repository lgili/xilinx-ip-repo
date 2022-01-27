
`timescale 1 ns / 1 ps
//`define POST_SYNTHESIS_SIMULATION 1
	module ad9226_v1_0 #
	(
		// Users to add parameters here
        parameter ADC_DATA_WIDTH = 12,        
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 64,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5,
		
		
		parameter integer C_M_AXIS_START_COUNT	= 32

		// Parameters of Axi Master Bus Interface M01_AXIS
		//parameter integer C_M01_AXIS_TDATA_WIDTH	= 32,
		//parameter integer C_M01_AXIS_START_COUNT	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		//parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		//parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here
	    input wire  clk_25m,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_1,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_2,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_3,
		input wire [ADC_DATA_WIDTH-1 : 0] adc_trigger,		
		//input wire [(ADC_TRIGGER_ON)-1:0] otr,

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire                           ACLK,
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
		input wire  s00_axi_rready,
		
		
		//////////////////////////////////////////////////////////////////
		// Ports of Axi Slave Bus Interface S_AXIS
		//input wire  s_axis_aclk,
		//input wire  s_axis_aresetn,
		output wire  s_axis_tready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axis_tdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s_axis_tstrb,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s_axis_tkeep,
		input wire  s_axis_tlast,
		input wire  s_axis_tvalid,

		// Ports of Axi Master Bus Interface M_AXIS
		//input wire  m_axis_aclk,
		//input wire  m_axis_aresetn,
		output wire  m_axis_tvalid,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] m_axis_tdata,
		output wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] m_axis_tstrb,
		output wire  m_axis_tlast,
		input wire  m_axis_tready, 
		output wire 	[(C_S00_AXI_DATA_WIDTH/8)-1 : 0] m_axis_tkeep, 
		output wire 	m_axis_tuser
		
		/////////////////////////////////////////////////////////////////	
		
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

`ifdef POST_SYNTHESIS_SIMULATION
reg 		enableSampleGeneration; 
reg 	[31:0]	packetSize; 

initial begin 
#1000
	enableSampleGeneration = 1; 
end 

initial begin 
	packetSize = 31; 
end 

`else 

wire 		enableSampleGeneration; 
wire 	[31:0]	packetSize; 	
	
	
// Instantiation of Axi Bus Interface S_AXI
	ad9226_v1_s_axi # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) ad9226_v1_s_axi_inst (
	
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			    ( packetSize ), 
		.PacketRate			        ( packetRate ), 
		.PacketPattern 			    ( packetPattern ), 

		.TotalReceivedPacketData 	( totalReceivedPacketData ), 
		.TotalReceivedPackets 		( totalReceivedPackets ), 
		.LastReceivedPacket_head 	( lastReceivedPacket_head ), 
		.LastReceivedPacket_tail 	( lastReceivedPacket_tail ), 
		
		.S_AXI_ACLK			(ACLK),
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
	
`endif 	
	// Instantiation of Axi Bus Interface S_AXIS
	ad9226_v1_s_axis # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXI_DATA_WIDTH)
	) ad9226_v1_s_axis_inst (
		.TotalReceivedPacketData 	( totalReceivedPacketData ), 
		.TotalReceivedPackets 		( totalReceivedPackets ), 
		.LastReceivedPacket_head 	( lastReceivedPacket_head ), 
		.LastReceivedPacket_tail 	( lastReceivedPacket_tail ), 
		
		.S_AXIS_ACLK			(ACLK),
		.S_AXIS_ARESETN			(ARESETN),
		.S_AXIS_TREADY			(s_axis_tready),
		.S_AXIS_TDATA			(s_axis_tdata),
		.S_AXIS_TSTRB			(s_axis_tstrb),
		.S_AXIS_TKEEP			(s_axis_tkeep), 
		.S_AXIS_TLAST			(s_axis_tlast),
		.S_AXIS_TVALID			(s_axis_tvalid)
	);
	
	
	// Instantiation of Axi Bus Interface M_AXIS
	ad9226_v1_m_axis # ( 
		.C_M_AXIS_TDATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_M_START_COUNT(C_M_AXIS_START_COUNT)
	) ad9226_v1_m_axis_inst (
	
	    .clk_25m(clk_25m),
		.adc_1(adc_1),
		.adc_2(adc_2),
		.adc_3(adc_3),
		.adc_trigger(adc_trigger),		
		.otr(otr),
	    
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			( packetSize ), 
		.PacketRate			( packetRate ), 
		.PacketPattern 			( packetPattern ), 

		.M_AXIS_ACLK			(ACLK),
		.M_AXIS_ARESETN			(ARESETN),
		.M_AXIS_TVALID			(m_axis_tvalid),
		.M_AXIS_TDATA			(m_axis_tdata),
		.M_AXIS_TSTRB			(m_axis_tstrb),
		.M_AXIS_TLAST			(m_axis_tlast),
		.M_AXIS_TREADY			(m_axis_tready),
		.M_AXIS_TKEEP 			( m_axis_tkeep ), 
		.M_AXIS_TUSER 			( m_axis_tuser )
	);
	


	endmodule
