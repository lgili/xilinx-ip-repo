
`timescale 1 ns / 1 ps
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

		// Parameters of Axi Master Bus Interface M01_AXIS
		//parameter integer C_M01_AXIS_TDATA_WIDTH	= 32,
		//parameter integer C_M01_AXIS_START_COUNT	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		//parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		//parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here
	    input  wire		    clk_48MHz,           
        input  wire  [2*ADC_QTD-1:0]   inData,           
        output wire [2*ADC_QTD*ADC_LENGTH-1:0]   adcData, 
        output wire [2*ADC_QTD*ADC_LENGTH-1:0]   adcData_fil,            
       
        //output wire [ADC_LENGTH-1:0]   adcData2,
        //output wire [ADC_LENGTH-1:0]   adcData3,
        //output wire [ADC_LENGTH-1:0]   adcData4,
        //output wire [ADC_LENGTH-1:0]   adcData5,
        //output wire [ADC_LENGTH-1:0]   adcData6,      
        output wire [ADC_QTD-1:0]     cs,
        output wire [ADC_QTD-1:0]     sclk,
        //output wire [ADC_QTD-1:0]     sampleDone,
        //output wire [2*ADC_QTD-1:0]    current_state,
        //output wire [4*ADC_QTD-1:0]    count,
        output wire [2*ADC_QTD-1:0]      dataready,
        
        // filter 
		//output wire [ADC_LENGTH-1:0] filter_adc,
		//output wire filter_ready,

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
		
		
//		// Ports of Axi Master Bus Interface M00_AXIS		
//		output wire  m00_axis_tvalid,
//		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] m00_axis_tdata,
//		//output wire [(ADC_LENGTH/8)-1 : 0] m00_axis_tstrb,
//		output wire  m00_axis_tlast,
//		input wire  m00_axis_tready,

//		// Ports of Axi Master Bus Interface M01_AXIS		
//		output wire  m01_axis_tvalid,
//		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] m01_axis_tdata,
//		//output wire [(ADC_LENGTH/8)-1 : 0] m01_axis_tstrb,
//		output wire  m01_axis_tlast,
//		input wire  m01_axis_tready,
		
//		// Ports of Axi Master Bus Interface M01_AXIS		
//		output wire  m02_axis_tvalid,
//		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] m02_axis_tdata,
//		//output wire [(ADC_LENGTH/8)-1 : 0] m01_axis_tstrb,
//		output wire  m02_axis_tlast,
//		input wire  m02_axis_tready,
		
//		// Ports of Axi Master Bus Interface M01_AXIS		
//		output wire  m03_axis_tvalid,
//		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] m03_axis_tdata,
//		//output wire [(ADC_LENGTH/8)-1 : 0] m01_axis_tstrb,
//		output wire  m03_axis_tlast,
//		input wire  m03_axis_tready,
		
//		// Ports of Axi Master Bus Interface M01_AXIS		
//		output wire  m04_axis_tvalid,
//		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] m04_axis_tdata,
//		//output wire [(ADC_LENGTH/8)-1 : 0] m01_axis_tstrb,
//		output wire  m04_axis_tlast,
//		input wire  m04_axis_tready,
		
//		// Ports of Axi Master Bus Interface M01_AXIS		
//		output wire  m05_axis_tvalid,
//		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] m05_axis_tdata,
//		//output wire [(ADC_LENGTH/8)-1 : 0] m01_axis_tstrb,
//		output wire  m05_axis_tlast,
//		input wire  m05_axis_tready

		
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
	ad7276_v1_s_axis # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXI_DATA_WIDTH)
	) ad7276_v1_s_axis_inst (
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
	ad7276_v1_m_axis # ( 
		.C_M_AXIS_TDATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_M_START_COUNT(C_M_AXIS_START_COUNT)
	) ad7276_v1_m_axis_inst (
	
	    .clk_48MHz(clk_48MHz),
	    .inData(inData),
	    .adcData(adcData),
	    .cs(cs),
	    .sclk(sclk),
	    //.sampleDone(),   
	
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
	
// Instantiation of Axi Bus Interface S00_AXI
	/*ad7276_v3_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
		.ADC_LENGTH(ADC_LENGTH)
	) ad7276_v3_0_S00_AXI_inst (
		.S_AXI_ACLK(ACLK),
		.S_AXI_ARESETN(ARESETN),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
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
		.S_AXI_RREADY(s00_axi_rready),
		
		.clk(clk_48MHz),        
        .inData(inData),        
        .adcData(adcData),
        //.adcData2(adcData_2),       
        .sclk(sclk),
        .cs(cs),        
        //.sampleDone(sampleDone),
        //.current_state(current_state),
        //.count(count),
        
        .axis_tvalid(axis_tvalid),				
		.axis_tlast(axis_tlast),
		.axis_tready(axis_tready),
		.axis_tdata(axis_tdata),
		//.axis_tdata2(axis_tdata2),
		
		.filter_ready(dataready),
		.filter_adc(adcData_fil)	
		
        
	);*/
	
//	parameter SIZE_LEFT_FOR_TDATA = C_S00_AXI_DATA_WIDTH - ADC_LENGTH;
	
	/*wire [2*ADC_QTD*ADC_LENGTH-1:0] filter_adc;*/
	// clean data
	//wire [2*ADC_QTD*ADC_LENGTH-1:0] adcData_1;
	//wire [ADC_QTD*ADC_LENGTH-1:0] adcData_2;	
	
	
	/*assign adcData1 = filter_adc[ADC_LENGTH-1 : 0];
	assign adcData2 = filter_adc[4*ADC_LENGTH-1 : 3*ADC_LENGTH];
	
	assign adcData3 = filter_adc[2*ADC_LENGTH-1 : ADC_LENGTH];
	assign adcData4 = filter_adc[5*ADC_LENGTH-1 : 4*ADC_LENGTH];
	
	assign adcData5 = filter_adc[3*ADC_LENGTH-1 : 2*ADC_LENGTH];
	assign adcData6 = filter_adc[6*ADC_LENGTH-1 : 5*ADC_LENGTH];*/
	
	
        
	
	
	// axi stream data 
//	wire [2*ADC_QTD *ADC_LENGTH-1 : 0] axis_tdata;	
//	//wire [ADC_QTD *ADC_LENGTH-1 : 0] axis_tdata2;	
	
//	wire [2*ADC_QTD -1:0] axis_tlast;
//	wire [2*ADC_QTD -1:0] axis_tready;
//	wire [2*ADC_QTD -1:0] axis_tvalid;
	
//	assign m00_axis_tdata = (axis_tready[0] == 1'b1) ? adcData[ADC_LENGTH-1 : 0] : 32'h0;
//	assign m01_axis_tdata = (axis_tready[1] == 1'b1) ? adcData[2*ADC_LENGTH-1 : 1*ADC_LENGTH-1] : 32'h0;
	
//	assign m02_axis_tdata = (axis_tready[2] == 1'b1) ? adcData[3*ADC_LENGTH-1 : 2*ADC_LENGTH-1] : 32'h0;
//	assign m03_axis_tdata = (axis_tready[3] == 1'b1) ? adcData[4*ADC_LENGTH-1 : 3*ADC_LENGTH-1] : 32'h0;
	
//	assign m04_axis_tdata = (axis_tready[4] == 1'b1) ? adcData[5*ADC_LENGTH-1 : 4*ADC_LENGTH-1] : 32'h0;
//	assign m05_axis_tdata = (axis_tready[5] == 1'b1) ? adcData[6*ADC_LENGTH-1 : 5*ADC_LENGTH-1] : 32'h0;
	
//	assign m00_axis_tvalid =  axis_tvalid[0];
//	assign m01_axis_tvalid =  axis_tvalid[1];
//	assign m02_axis_tvalid =  axis_tvalid[2];
//	assign m03_axis_tvalid =  axis_tvalid[3];
//	assign m04_axis_tvalid =  axis_tvalid[4];
//	assign m05_axis_tvalid =  axis_tvalid[5];
	
//	assign m00_axis_tlast =  axis_tlast[0];
//	assign m01_axis_tlast =  axis_tlast[1];
//	assign m02_axis_tlast =  axis_tlast[2];
//	assign m03_axis_tlast =  axis_tlast[3];
//	assign m04_axis_tlast =  axis_tlast[4];
//	assign m05_axis_tlast =  axis_tlast[5];
	
//	assign axis_tready[0] =  m00_axis_tready;
//	assign axis_tready[1] =  m01_axis_tready;
//	assign axis_tready[2] =  m02_axis_tready;
//	assign axis_tready[3] =  m03_axis_tready;
//	assign axis_tready[4] =  m04_axis_tready;
//	assign axis_tready[5] =  m05_axis_tready;
	
		

    
    //assign dataready =  axis_tlast;

// Instantiation of Axi Bus Interface M01_AXIS
//	ad7276_v3_0_M01_AXIS # ( 
//		.C_M_AXIS_TDATA_WIDTH(C_M01_AXIS_TDATA_WIDTH),
//		.C_M_START_COUNT(C_M01_AXIS_START_COUNT)
//	) ad7276_v3_0_M01_AXIS_inst (
//		.M_AXIS_ACLK(m01_axis_aclk),
//		.M_AXIS_ARESETN(m01_axis_aresetn),
//		.M_AXIS_TVALID(m01_axis_tvalid),
//		.M_AXIS_TDATA(m01_axis_tdata),
//		.M_AXIS_TSTRB(m01_axis_tstrb),
//		.M_AXIS_TLAST(m01_axis_tlast),
//		.M_AXIS_TREADY(m01_axis_tready)
//	);

// Instantiation of Axi Bus Interface M00_AXIS
//	ad7276_v3_0_M00_AXIS # ( 
//		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
//		.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
//	) ad7276_v3_0_M00_AXIS_inst (
//		.M_AXIS_ACLK(m00_axis_aclk),
//		.M_AXIS_ARESETN(m00_axis_aresetn),
//		.M_AXIS_TVALID(m00_axis_tvalid),
//		.M_AXIS_TDATA(m00_axis_tdata),
//		.M_AXIS_TSTRB(m00_axis_tstrb),
//		.M_AXIS_TLAST(m00_axis_tlast),
//		.M_AXIS_TREADY(m00_axis_tready)
//	);

	// Add user logic here

	// User logic ends

	endmodule
