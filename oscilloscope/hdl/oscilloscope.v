
`timescale 1 ns / 1 ps
`default_nettype none

module oscilloscope #(
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH	= 32,
    parameter integer C_S00_AXI_ADDR_WIDTH	= 6,
    // oscilloscope parameters
    parameter DSIZE = 12,
    parameter ASIZE = 10,
    parameter reg_size = 2**ASIZE,
    parameter Baud = 115200
)(
    input wire CLK100MHz, 
    input wire CLKADC, 
    input wire rst_n, 
    
    // input trig_up,
    // input trig_down,
    // input trig_reset,
    
    // input trig_off,
    
    // input time_scale_in,
    // input time_scale_out,
    // input time_left,
    // input time_right,
    // input time_reset,

    input wire [11:0]  ch1_data,
    // input ch1_en,
    // input ch1_scale_in,
    // input ch1_scale_out,   
    // input ch1_up,
    // input ch1_down, 
    // input ch1_reset,
    // input ch1_couple_sw,
    // output logic ch1_couple,

    input wire [11:0] ch2_data,
    // input ch2_en,
    // input ch2_scale_in,
    // input ch2_scale_out,   
    // input ch2_up,
    // input ch2_down, 
    // input ch2_reset,
    // input ch2_couple_sw,
    // output logic ch2_couple,

    output wire sclk,
    output wire cs_n,

    // output data_out_ch1,
    // input en_read,
    input wire clk_reading,
    input wire RxD,
    output wire TxD,

    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
    input wire [2 : 0] s_axi_awprot,
    input wire  s_axi_awvalid,
    output wire  s_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input wire  s_axi_wvalid,
    output wire  s_axi_wready,
    output wire [1 : 0] s_axi_bresp,
    output wire  s_axi_bvalid,
    input wire  s_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    input wire [2 : 0] s_axi_arprot,
    input wire  s_axi_arvalid,
    output wire  s_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
    output wire [1 : 0] s_axi_rresp,
    output wire  s_axi_rvalid,
    input wire  s_axi_rready

    );


///////////////////////////////////////////////////////////////////
wire clk_sampling;
// reg [9:0] data_out_1 [reg_size - 1:0];
// reg [9:0] data_out_2 [reg_size - 1:0];
reg [3:0] ch1_scale, ch2_scale;
reg [4:0] time_scale;

reg [9:0] ch1_offset, ch2_offset, trig, time_offset;
wire [DSIZE-1:0] data_out_ch1;

wire TxD_busy, data_ready_ch1;
wire TxD_start; 
wire en_read = (TriggerStartRead || RxD_data_ready);


wire [7:0] RxD_data;
wire RxD_data_ready;
async_receiver async_rxd(.clk(clk_reading), .RxD(RxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
async_transmitter  async_txd(.clk(clk_reading), .TxD(TxD), .TxD_start(TxD_start), .TxD_busy(TxD_busy), .TxD_data(data_out_ch1[11:4]));


Sampling #(
    DSIZE,
    ASIZE
)
sampling (
    .rst_n(rst_n),
    .CLK100MHz(CLK100MHz),
    .CLKADC(CLKADC),
    .trig_off(EnableTrigger),
    .ch1_data(ch1_data),
    .ch2_data(ch2_data),
    .ch1_en(EnableCh1),
    .ch2_en(EnableCh2),
    .ch1_couple(CoupleCh1),
    .ch2_couple(CoupleCh2),
    .ch1_scale(ScaleCh1),
    .ch2_scale(ScaleCh2),
    .time_scale(ScaleTime),
    .trig(Trigger),
    .ch1_offset(OffsetCh1),
    .ch2_offset(OffsetCh1),
    .data_out_1(),
    .data_out_2(),
    .clk_sampling(clk_sampling),
    .sclk(sclk),
    .cs_n(cs_n),

    .data_out_ch1(data_out_ch1),
    .en_read(en_read),
    .clk_reading(clk_reading),
    .data_ready_ch1(data_ready_ch1),
    .TxD_start(TxD_start),
    .TxD_busy(TxD_busy)
);

// assign ch1_couple = ch1_couple_sw;
// assign ch2_couple = ch2_couple_sw;
wire en, ready, sw;
assign en = 1;

// Control #(100, 0, 400) trig_control (.en, .rst_n, .clk(CLK100MHz), .rst(trig_reset), .up(trig_up), .down(trig_down), .data_ctrl(trig));
// Control #(300, 0, 600) time_control (.en, .rst_n, .clk(CLK100MHz), .rst(time_reset), .up(time_left), .down(time_right), .data_ctrl(time_offset));
// Control #(1, 1, 16) time_scale_control (.en, .rst_n, .clk(CLK100MHz), .rst(1'b1), .up(time_scale_in), .down(time_scale_out), .data_ctrl(time_scale));
// Control #(9, 3, 11) ch1_scale_control ( .en, .rst_n, .clk(CLK100MHz), .rst(1'b1), .up(ch1_scale_in), .down(ch1_scale_out), .data_ctrl(ch1_scale));
// Control #(200, 0, 400) ch1_position_control (.en, .rst_n, .clk(CLK100MHz), .rst(ch1_reset), .up(ch1_up), .down(ch1_down), .data_ctrl(ch1_offset));
// Control #(9, 3, 11) ch2_scale_control (.en, .rst_n, .clk(CLK100MHz), .rst(1'b1), .up(ch2_scale_in), .down(ch2_scale_out), .data_ctrl(ch2_scale));
// Control #(200, 0, 400) ch2_position_control (.en, .rst_n, .clk(CLK100MHz), .rst(ch2_reset), .up(ch2_up), .down(ch2_down), .data_ctrl(ch2_offset));



wire			EnableCh1;
wire 	     	EnableCh2; 
wire 			EnableTrigger;
wire 	[3:0]	ScaleCh1; 
wire 	[3:0]	ScaleCh2;
wire 	[4:0]	ScaleTime;
wire 	[11:0]	OffsetCh1;
wire 	[11:0]	OffsetCh2;
wire 			CoupleCh1;
wire 			CoupleCh2;
wire 	[11:0]	Trigger;
wire            TriggerStartRead;
// Instantiation of Axi Bus Interface S_AXI
	osc_s_axi # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) ad7276_v1_s_axi_inst (
	
		.EnableCh1(EnableCh1),
        .EnableCh2(EnableCh2),
        .ScaleCh1(ScaleCh1),
        .ScaleCh2(ScaleCh2),
        .ScaleTime(ScaleTime),
        .OffsetCh1(OffsetCh1),
        .OffsetCh2(OffsetCh2),
        .CoupleCh1(CoupleCh1),
        .CoupleCh2(CoupleCh2),
        .EnableTrigger(EnableTrigger),
        .Trigger(Trigger),
        .TriggerStartRead(TriggerStartRead),
 
		
		.S_AXI_ACLK			    (CLK100MHz),
		.S_AXI_ARESETN			(rst_n),
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
	

endmodule

`resetall