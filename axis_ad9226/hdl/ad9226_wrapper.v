
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
	module ad9226_wrapper #
	(
		// Users to add parameters here
		parameter ADC1_ENABLE = 1,
		parameter ADC2_ENABLE = 0,
		parameter ADC3_ENABLE = 0,
		parameter ADC4_ENABLE = 0,
		
		parameter DEBUG_PORTS_ENABLE = 0,
		
        parameter ADC_DATA_WIDTH = 12,
        parameter FIFO_SIZE = 4096,  
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer AXI_LITE_DATA_WIDTH	= 32,
		parameter integer AXIS_DATA_WIDTH	= 32,
		parameter integer AXI_ADDR_WIDTH	= 6,
		
		
		parameter integer C_M_AXIS_START_COUNT	= 32

		//Parameters of Axi Master Bus Interface M01_AXIS
		//parameter integer C_M01_AXIS_TDATA_WIDTH	= 32,
		//parameter integer C_M01_AXIS_START_COUNT	= 32,
		
		// Parameters of Axi Master Bus Interface M00_AXIS
		//parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		//parameter integer C_M00_AXIS_START_COUNT	= 32
		
	)
	(
		// Users to add ports here
	   
		input wire [ADC_DATA_WIDTH-1 : 0] s1_ad9226_data,
		input wire                        s1_otr,
		output wire                       s1_ad9226_clk,
		
		input wire [ADC_DATA_WIDTH-1 : 0] s2_ad9226_data,
		input wire                        s2_otr,
		output wire                       s2_ad9226_clk,
		
		input wire [ADC_DATA_WIDTH-1 : 0] s3_ad9226_data,
		input wire                        s3_otr,
		output wire                       s3_ad9226_clk,
		
		input wire [ADC_DATA_WIDTH-1 : 0] s4_ad9226_data,
		input wire                        s4_otr,
		output wire                       s4_ad9226_clk,
		
		
		output wire irq,		
		input wire button,
		output wire debugPin,	
		
		
		// User ports ends
		// Do not modify the ports beyond this line

		// Ports of Axi Slave Bus Interface S00_AXI	
		input wire  clk_100m,	
		input wire  clk_adc,		
        input wire  aresetn,       
                         
		
		input wire [AXI_LITE_DATA_WIDTH-1 : 0] s_axi_awaddr,
		input wire [2 : 0] s_axi_awprot,
		input wire  s_axi_awvalid,
		output wire  s_axi_awready,
		input wire [AXI_LITE_DATA_WIDTH-1 : 0] s_axi_wdata,
		input wire [(AXI_LITE_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
		input wire  s_axi_wvalid,
		output wire  s_axi_wready,
		output wire [1 : 0] s_axi_bresp,
		output wire  s_axi_bvalid,
		input wire  s_axi_bready,
		input wire [AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
		input wire [2 : 0] s_axi_arprot,
		input wire  s_axi_arvalid,
		output wire  s_axi_arready,
		output wire [AXI_LITE_DATA_WIDTH-1 : 0] s_axi_rdata,
		output wire [1 : 0] s_axi_rresp,
		output wire  s_axi_rvalid,
		input wire  s_axi_rready,
		
		
		
		// Ports of Axi Master Bus Interface M_AXIS
		//input wire  m_axis_aclk,
		//input wire  m_axis_aresetn,
		output wire  m_axis_tvalid,
		output wire [AXIS_DATA_WIDTH-1 : 0] m_axis_tdata,
		output wire [(AXIS_DATA_WIDTH/8)-1 : 0] m_axis_tstrb,
		output wire  m_axis_tlast,
		input wire  m_axis_tready, 
		output wire 	[(AXIS_DATA_WIDTH/8)-1 : 0] m_axis_tkeep, 
		output wire 	m_axis_tuser
		
		/////////////////////////////////////////////////////////////////	
		
	);
	
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////

		
wire 	[7:0]  enablePacket; 
wire	[AXI_LITE_DATA_WIDTH-1:0] configPassband; 
wire    [AXI_LITE_DATA_WIDTH-1:0] configZCDValue;
wire    [AXI_LITE_DATA_WIDTH-1:0] triggerLevel;
wire    [AXI_LITE_DATA_WIDTH-1:0] triggerEnable;
wire    [AXI_LITE_DATA_WIDTH-1:0] configSampler;
wire    [AXI_LITE_DATA_WIDTH-1:0] configAdc;
wire    [AXI_LITE_DATA_WIDTH-1:0] decimator;
wire    [AXI_LITE_DATA_WIDTH-1:0] mavgFactor;
wire    [AXI_LITE_DATA_WIDTH-1:0] packetSizeToStop;
wire    [AXI_LITE_DATA_WIDTH-1:0] restart;
wire    [AXI_LITE_DATA_WIDTH-1:0] adcData;
wire    [AXI_LITE_DATA_WIDTH-1:0] status;

wire    [AXI_LITE_DATA_WIDTH-1:0]  firstPositionZcd;
wire    [AXI_LITE_DATA_WIDTH-1:0]  lastPositionZcd;
wire    [AXI_LITE_DATA_WIDTH-1:0]  triggerOffset;
wire 	[AXI_LITE_DATA_WIDTH-1:0]	totalReceivedPacketData; 
wire 	[AXI_LITE_DATA_WIDTH-1:0]	totalReceivedPackets; 
wire 	[AXI_LITE_DATA_WIDTH-1:0]	lastReceivedPacket_head; 
wire 	[AXI_LITE_DATA_WIDTH-1:0]	lastReceivedPacket_tail; 

wire [ADC_DATA_WIDTH-1:0] data_1;
wire [ADC_DATA_WIDTH-1:0] data_2;
wire [ADC_DATA_WIDTH-1:0] data_3;
wire [ADC_DATA_WIDTH-1:0] data_4;
wire trigger;
wire tlast_assert;

//wire              clk_adc;
assign s1_ad9226_clk = clk_adc;
assign s2_ad9226_clk = clk_adc;
assign s3_ad9226_clk = clk_adc;
assign s4_ad9226_clk = clk_adc;





wire 	enableSampleGeneration; 
wire 	[31:0]	packetSize; 	

/////////////////////////////////////////////////
// 
// Instantiation of Axi Bus Interface S_AXI
//
/////////////////////////////////////////////////	    
ad9226_v1_s_axi # ( 
	.AXI_DATA_WIDTH(AXI_LITE_DATA_WIDTH),
	.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
) 	ad9226_v1_s_axi_inst (
		
	.EnableSampleGeneration 	( enableSampleGeneration ), 
	.PacketSize 			( packetSize ), 
	//.PacketRate			( packetRate ), 
	.ConfigAdc 			( configAdc ), 
	//.NumberOfPacketsToSend		( NumberOfPacketsToSend ), 
	.ConfigZCDValue             (configZCDValue),
	.Decimator                   (decimator),
	.MavgFactor                  (mavgFactor),
	.PacketSizeToStop			(packetSizeToStop),	
	.Restart                    (restart), 
	.AdcData                    (adcData),
	.Status                     (status), 
	.TriggerLevel                (triggerLevel),
	
	
	.S_AXI_ACLK			    (clk_100m),
	.S_AXI_ARESETN			(aresetn),
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
	

/////////////////////////////////////////////////
// 
// Instantiation of AD9226 with 4 channels
//
/////////////////////////////////////////////////
	// 
	ad9226_if # ( 
		.QTD_ADC(4),
		.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),		
		.ADC_DATA_WIDTH(ADC_DATA_WIDTH)
	) ad9226_if_inst (	

		.clk_100m(clk_100m),
		.reset_n(aresetn),

		/*
		* ADC input
		*/
		.adc_1(s1_ad9226_data),
		.adc_2(s2_ad9226_data),
		.adc_3(s3_ad9226_data),
		.adc_4(s4_ad9226_data),	

		.irq(irq),
		.adc_clk(clk_adc),		
		.button(button),	
		.trigger(trigger),	
		.tlast_assert(tlast_assert),
		.debug(debugPin),
		
		/*
		* ADC output
		*/
		.data_1(data_1),
		.data_2(data_2),
		.data_3(data_3),
		.data_4(data_4),
		
		/*
		* Configurations 
		*/
		.PacketSize 			    ( packetSize ),
		.ConfigAdc 			        ( configAdc  ), 		
		.ConfigZCDValue             (configZCDValue),
		.Decimator                  (decimator),
		.MavgFactor                 (mavgFactor),
		.PacketSizeToStop			(packetSizeToStop),	
		.Restart                    (restart),
		.AdcData                    (adcData),
		.Status                     (status), 
		.TriggerLevel               (triggerLevel)		
	);

	
	// Instantiation of Axi Bus Interface M_AXIS
	ad9226_v1_m_axis # ( 
		.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
		.C_M_START_COUNT(C_M_AXIS_START_COUNT),
		.ADC_DATA_WIDTH(ADC_DATA_WIDTH)
	) ad9226_v1_m_axis_inst (	
		
		.data_1(data_1),
		.data_2(data_2),
		.data_3(data_3),
		.data_4(data_4),		
		.trigger(trigger),

		.adc_clk(clk_adc),		
		
		.EnableSampleGeneration 	( enableSampleGeneration ), 
		.PacketSize 			    ( packetSize ), 
		.PacketRate			        ( packetRate ), 		
		.NumberOfPacketsToSend		( NumberOfPacketsToSend ), 
		.Restart                    (restart),
		.tlast_assert(tlast_assert),
				
		.M_AXIS_ACLK			(clk_100m),
		.M_AXIS_ARESETN			(aresetn),
		.M_AXIS_TVALID			(m_axis_tvalid),
		.M_AXIS_TDATA			(m_axis_tdata),
		.M_AXIS_TSTRB			(m_axis_tstrb),
		.M_AXIS_TLAST			(m_axis_tlast),
		.M_AXIS_TREADY			(m_axis_tready),
		.M_AXIS_TKEEP 			(m_axis_tkeep), 
		.M_AXIS_TUSER 			(m_axis_tuser)
	);


endmodule
