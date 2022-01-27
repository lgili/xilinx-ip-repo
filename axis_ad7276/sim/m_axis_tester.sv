// Sadri - may - 08 - 2015 - Updated , added also the axis slave plug and connected the master and slave together. 
// Sadri - may - 05 - 2015 - Created! 

// This is the tester for axi stream master plug 

// Author : MohammadSadegh Sadri 

`timescale 1ns/1ps

module m_axis_tester (); 

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

logic clk_48MHz;
logic [1:0] inData;
logic adcData;
logic cs;
logic sclk;

////////////////////////////////////////////////////////////////////
//
// axi stream master plug 
//
////////////////////////////////////////////////////////////////////

//ad7276_v1_m_axis #(
//.C_M_AXIS_TDATA_WIDTH ( 32 ),
//.C_M_START_COUNT ( 32 )
//) sample_generator_v2_0_M_AXIS_Ins (
//.EnableSampleGeneration			(enableSampleGeneration), 		
//.PacketSize				(packetSize), 
//.PacketRate				(), 
//.PacketPattern				(),
//.M_AXIS_ACLK				(Clk),
//.M_AXIS_ARESETN				(ResetL),
//.M_AXIS_TVALID				(m_axis_tvalid),
//.M_AXIS_TDATA				(m_axis_tdata),
//.M_AXIS_TSTRB				(m_axis_tstrb),
//.M_AXIS_TLAST				(m_axis_tlast),
//.M_AXIS_TREADY				(m_axis_tready),
//.M_AXIS_TKEEP				(m_axis_tkeep),
//.M_AXIS_TUSER				(m_axis_tuser)
//);

//ad7276_v1_m_axis # ( 
//		.C_M_AXIS_TDATA_WIDTH(32),
//		.C_M_START_COUNT(32)
//	) ad7276_v1_m_axis_inst (
	
//	    .clk_48MHz(clk_48MHz),
//	    .inData(inData),
//	    //.adcData(adcData),
//	    .cs(cs),
//	    .sclk(sclk)
	    //.sampleDone(),   
	
//		.EnableSampleGeneration 	( enableSampleGeneration ), 
//		.PacketSize 			( packetSize ), 
//		.PacketRate			( packetRate ), 
//		.PacketPattern 			( packetPattern ), 

//		.M_AXIS_ACLK			(ACLK),
//		.M_AXIS_ARESETN			(ARESETN),
//		.M_AXIS_TVALID			(m_axis_tvalid),
//		.M_AXIS_TDATA			(m_axis_tdata),
//		.M_AXIS_TSTRB			(m_axis_tstrb),
//		.M_AXIS_TLAST			(m_axis_tlast),
//		.M_AXIS_TREADY			(m_axis_tready),
//		.M_AXIS_TKEEP 			( m_axis_tkeep ), 
//		.M_AXIS_TUSER 			( m_axis_tuser )
//	);

////////////////////////////////////////////////////////////////////
//
// axi stream slave plug 
//
////////////////////////////////////////////////////////////////////

//sample_generator_v2_0_S_AXIS #(
//.C_S_AXIS_TDATA_WIDTH ( 32 )
//) sample_generator_v2_0_S_AXIS_Ins (
//.TotalReceivedPacketData		( totalReceivedPacketData ),
//.TotalReceivedPackets			( totalReceivedPackets ),
//.LastReceivedPacket_head		( lastReceivedPacket_head ),
//.LastReceivedPacket_tail		( lastReceivedPacket_tail),

//.S_AXIS_ACLK				( Clk ),
//.S_AXIS_ARESETN				( ResetL ),
//.S_AXIS_TREADY				( m_axis_tready ),
//.S_AXIS_TDATA				( m_axis_tdata ),
//.S_AXIS_TSTRB				( m_axis_tstrb ),
//.S_AXIS_TLAST				( m_axis_tlast ),
//.S_AXIS_TVALID				( m_axis_tvalid )
//);

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
		
////////////////////////////////////////////////////////////////////
//
// enable sample generation 
//
////////////////////////////////////////////////////////////////////

always @(posedge Clk)
	if ( ! ResetL ) 
		enableSampleGeneration <= 0; 
	else begin 
		if (globalCounter == 100) 
			enableSampleGeneration <= 1; 
		else if ( globalCounter == 1000 )
			enableSampleGeneration <= 0; 
		else if ( globalCounter == 1200 ) 
			enableSampleGeneration <= 1; 
		else if ( globalCounter == 1500 ) 
			enableSampleGeneration <= 0; 
	end 
	

always @(posedge Clk) 
	if (! ResetL ) 
		packetSize <= 0; 
	else begin 
		if (globalCounter == 100) 
			packetSize <= 31; 
		else if ( globalCounter == 1000 )
			packetSize <= 0; 
		else if ( globalCounter == 1200 ) 
			packetSize <= 75; 
		else if ( globalCounter == 1500 ) 
			packetSize <= 0; 
	end 

// always @(posedge Clk)
// 	if ( ! ResetL ) 
// 		m_axis_tready <= 1; 
// 	else 
// 		m_axis_tready <= ~ m_axis_tready; 
		
endmodule 