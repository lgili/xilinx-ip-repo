
`timescale 1 ns / 1 ps


	module trigger_fast_v1_0 #
	(

        
		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        input [11:0] ADC_1_DATA,
		input [11:0] ADC_2_DATA,
		input [11:0] ADC_3_DATA,
		input ADC_CLK,
//		input adc_1_otr,
//		input adc_2_otr,
//		input adc_3_otr,
		
		output DMA_TRIG,
		output DMA_ENA,

		// User ports ends
		// Do not modify the ports beyond this line

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
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

		// conexões internas
		wire [31:0] CONTROLE;
        wire [31:0] USER_DV;
        wire [31:0] USER_DT;
        wire [31:0] STATUS;
        wire [31:0] ADC1_MAX_DV;
        wire [31:0] ADC2_MAX_DV;
        wire [31:0] ADC3_MAX_DV;
        wire [31:0] VERSION_CTE;



// Instantiation of Axi Bus Interface S00_AXI
	S_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) S_AXI (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
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
		.CONTROLE(CONTROLE),
        .USER_DV(USER_DV),
        .USER_DT(USER_DT),
        .STATUS(STATUS),
        .ADC1_MAX_DV(ADC1_MAX_DV),
        .ADC2_MAX_DV(ADC2_MAX_DV),
        .ADC3_MAX_DV(ADC3_MAX_DV),
        .VERSION(VERSION_CTE)					
	);

	// Add user logic here
    derivada dvdt_1_inst
	(
	   .MOD_ENABLED(CONTROLE[0]),
	   .CH_ENABLED(CONTROLE[1]),
	   .ADC_DATA(ADC_1_DATA),
	   .CLK(ADC_CLK),
	   .RST(s00_axi_aresetn),
	   .USER_DV(USER_DV),
	   .USER_DT(USER_DT),
	   .TRIGGED(STATUS[0]),
	   .TRIG_EDGE(STATUS[3]),
	   .MAX_DV(ADC1_MAX_DV)
	);

	derivada dvdt_2_inst
	(
	   .MOD_ENABLED(CONTROLE[0]),
	   .CH_ENABLED(CONTROLE[2]),
	   .ADC_DATA(ADC_2_DATA),
	   .CLK(ADC_CLK),
	   .RST(s00_axi_aresetn),
	   .USER_DV(USER_DV),
	   .USER_DT(USER_DT),
	   .TRIGGED(STATUS[1]),
	   .TRIG_EDGE(STATUS[4]),
	   .MAX_DV(ADC2_MAX_DV)
	);

	derivada dvdt_3_inst
	(
	   .MOD_ENABLED(CONTROLE[0]),
	   .CH_ENABLED(CONTROLE[3]),
	   .ADC_DATA(ADC_3_DATA),
	   .CLK(ADC_CLK),
	   .RST(s00_axi_aresetn),
	   .USER_DV(USER_DV),
	   .USER_DT(USER_DT),
	   .TRIGGED(STATUS[2]),
	   .TRIG_EDGE(STATUS[5]),
	   .MAX_DV(ADC3_MAX_DV)
	);



	//assign TRIG_ON = CONTROLE[0];
	assign DMA_ENA = CONTROLE[0];
	assign DMA_TRIG =  (~STATUS[0] & ~STATUS[1] & ~STATUS[2]);	
	assign VERSION_CTE = 79;

	
	

	endmodule
