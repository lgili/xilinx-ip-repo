// Sadri - may - 11 - 2015 - bug removal, also updated the design to be able to do also post-synthesis simulation 
// Sadri - may - 02 - 2015 - updated ! 

`timescale 1 ns / 1 ps

// `define POST_SYNTHESIS_SIMULATION 1

	module sample_generator_v2_0 #
	(
		// Users to add parameters here
        parameter integer MAX_VALUE_COUNTER	= 1666666,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,

		// Parameters of Axi Slave Bus Interface S_AXIS
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32,

		// Parametedrs of Axi Master Bus Interface M_AXIS
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M_AXIS_START_COUNT	= 32,
		
		// Parameters of Axi Slave Bus Interface S_AXI_INTR
		parameter integer C_S_AXI_INTR_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_INTR_ADDR_WIDTH	= 5,
		parameter integer C_NUM_OF_INTR	= 1,
		parameter  C_INTR_SENSITIVITY	= 32'hFFFFFFFF,
		parameter  C_INTR_ACTIVE_STATE	= 32'hFFFFFFFF,
		parameter integer C_IRQ_SENSITIVITY	= 1,
		parameter integer C_IRQ_ACTIVE_STATE	= 1
	)
	(
		// Users to add ports here
        input wire trigger,
        output wire irq,
        output wire [2:0] state,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI
		input wire  S_ACLK,
		input wire  M_ACLK,
		input wire  ARESETN,
		input wire  M_ARESETN,
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
		//input wire  s_axis_aclk,
		//input wire  s_axis_aresetn,
		output wire  s_axis_tready,
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] s_axis_tdata,
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] s_axis_tstrb,
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] s_axis_tkeep,
		input wire  s_axis_tlast,
		input wire  s_axis_tvalid,

		// Ports of Axi Master Bus Interface M_AXIS
		//input wire  m_axis_aclk,
		//input wire  m_axis_aresetn,
		output wire  m_axis_tvalid,
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] m_axis_tdata,
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] m_axis_tstrb,
		output wire  m_axis_tlast,
		input wire  m_axis_tready, 
		output wire 	[(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] m_axis_tkeep, 
		output wire 	m_axis_tuser,
		
		
		// Ports of Axi Slave Bus Interface S_AXI_INTR		
		input wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0] s_axi_intr_awaddr,
		input wire [2 : 0] s_axi_intr_awprot,
		input wire  s_axi_intr_awvalid,
		output wire  s_axi_intr_awready,
		input wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0] s_axi_intr_wdata,
		input wire [(C_S_AXI_INTR_DATA_WIDTH/8)-1 : 0] s_axi_intr_wstrb,
		input wire  s_axi_intr_wvalid,
		output wire  s_axi_intr_wready,
		output wire [1 : 0] s_axi_intr_bresp,
		output wire  s_axi_intr_bvalid,
		input wire  s_axi_intr_bready,
		input wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0] s_axi_intr_araddr,
		input wire [2 : 0] s_axi_intr_arprot,
		input wire  s_axi_intr_arvalid,
		output wire  s_axi_intr_arready,
		output wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0] s_axi_intr_rdata,
		output wire [1 : 0] s_axi_intr_rresp,
		output wire  s_axi_intr_rvalid,
		input wire  s_axi_intr_rready
	);
	
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////
wire 	[7:0]	enablePacket; 
wire	[31:0]	configPassband; 
wire    [31:0] dmaBaseAddr;
wire    [31:0] triggerLevel;
wire    [31:0] triggerEnable;

wire    [31:0]  triggerOffset;
wire 	[31:0]	totalReceivedPacketData; 
wire 	[31:0]	totalReceivedPackets; 
wire 	[31:0]	lastReceivedPacket_head; 
wire 	[31:0]	lastReceivedPacket_tail; 

//assign irq = ~trigger ;

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
	sample_generator_v2_0_S_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) sample_generator_v2_0_S_AXI_inst (
	
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			( packetSize ), 
		.EnablePacket			( enablePacket ), 
		.ConfigPassband 			( packetPattern ), 
		.DMABaseAddr                 (dmaBaseAddr),
		.TriggerLevel                (triggerLevel),
		
		.TriggerOffset                (triggerOffset), 
		.TriggerEnable                (triggerEnable),

		.TotalReceivedPacketData 	( totalReceivedPacketData ), 
		.TotalReceivedPackets 		( totalReceivedPackets ), 
		.LastReceivedPacket_head 	( lastReceivedPacket_head ), 
		.LastReceivedPacket_tail 	( lastReceivedPacket_tail ), 
		
		.S_AXI_ACLK			(ACLK),
		.S_AXI_ARESETN			(ARESETN),
		.S_AXI_AWADDR			(s_axi_awaddr),
		.S_AXI_AWPROT			(s_axi_awprot),
		.S_AXI_AWVALID(s_axi_awvalid),
		.S_AXI_AWREADY(s_axi_awready),
		.S_AXI_WDATA(s_axi_wdata),
		.S_AXI_WSTRB(s_axi_wstrb),
		.S_AXI_WVALID(s_axi_wvalid),
		.S_AXI_WREADY(s_axi_wready),
		.S_AXI_BRESP(s_axi_bresp),
		.S_AXI_BVALID(s_axi_bvalid),
		.S_AXI_BREADY(s_axi_bready),
		.S_AXI_ARADDR(s_axi_araddr),
		.S_AXI_ARPROT(s_axi_arprot),
		.S_AXI_ARVALID(s_axi_arvalid),
		.S_AXI_ARREADY(s_axi_arready),
		.S_AXI_RDATA(s_axi_rdata),
		.S_AXI_RRESP(s_axi_rresp),
		.S_AXI_RVALID(s_axi_rvalid),
		.S_AXI_RREADY(s_axi_rready)
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
	sample_generator_v2_0_M_AXIS # ( 
		.C_M_AXIS_TDATA_WIDTH(C_M_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M_AXIS_START_COUNT),
		.MAX_VALUE_COUNTER(MAX_VALUE_COUNTER)
	) sample_generator_v2_0_M_AXIS_inst (
	
	    .trigger(trigger ),	    
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			( packetSize ), 
		.EnablePacket			( enablePacket ), 
		.ConfigPassband 		( configPassband ), 
		.DMABaseAddr            (dmaBaseAddr),
		.TriggerLevel           (triggerLevel),
		
		.TriggerOffset          (triggerOffset),
		.TriggerEnable          (triggerEnable),
		

		.M_AXIS_ACLK			(ACLK),
		.M_AXIS_ARESETN			(ARESETN),
		.M_AXIS_TVALID			(m_axis_tvalid),
		.M_AXIS_TDATA			(m_axis_tdata),
		.M_AXIS_TSTRB			(m_axis_tstrb),
		.M_AXIS_TLAST			(m_axis_tlast),
		.M_AXIS_TREADY			(m_axis_tready),
		.M_AXIS_TKEEP 			( m_axis_tkeep ), 
		.M_AXIS_TUSER 			( m_axis_tuser ),
		.irq(irq),
		.state(state)
	);
	
	
	// Instantiation of Axi Bus Interface S_AXI_INTR
//	s_axi_int # ( 
//		.C_S_AXI_DATA_WIDTH(C_S_AXI_INTR_DATA_WIDTH),
//		.C_S_AXI_ADDR_WIDTH(C_S_AXI_INTR_ADDR_WIDTH),
//		.C_NUM_OF_INTR(C_NUM_OF_INTR),
//		.C_INTR_SENSITIVITY(C_INTR_SENSITIVITY),
//		.C_INTR_ACTIVE_STATE(C_INTR_ACTIVE_STATE),
//		.C_IRQ_SENSITIVITY(C_IRQ_SENSITIVITY),
//		.C_IRQ_ACTIVE_STATE(C_IRQ_ACTIVE_STATE)
//	) myip_v1_0_S_AXI_INTR_inst (
//		.S_AXI_ACLK(S_ACLK),
//		.S_AXI_ARESETN(S_ARESETN),
//		.S_AXI_AWADDR(s_axi_intr_awaddr),
//		.S_AXI_AWPROT(s_axi_intr_awprot),
//		.S_AXI_AWVALID(s_axi_intr_awvalid),
//		.S_AXI_AWREADY(s_axi_intr_awready),
//		.S_AXI_WDATA(s_axi_intr_wdata),
//		.S_AXI_WSTRB(s_axi_intr_wstrb),
//		.S_AXI_WVALID(s_axi_intr_wvalid),
//		.S_AXI_WREADY(s_axi_intr_wready),
//		.S_AXI_BRESP(s_axi_intr_bresp),
//		.S_AXI_BVALID(s_axi_intr_bvalid),
//		.S_AXI_BREADY(s_axi_intr_bready),
//		.S_AXI_ARADDR(s_axi_intr_araddr),
//		.S_AXI_ARPROT(s_axi_intr_arprot),
//		.S_AXI_ARVALID(s_axi_intr_arvalid),
//		.S_AXI_ARREADY(s_axi_intr_arready),
//		.S_AXI_RDATA(s_axi_intr_rdata),
//		.S_AXI_RRESP(s_axi_intr_rresp),
//		.S_AXI_RVALID(s_axi_intr_rvalid),
//		.S_AXI_RREADY(s_axi_intr_rready)
//		//.irq(irq)
		
//	);

	// Add user logic here

	// User logic ends

	endmodule
