
`timescale 1ns / 1ps
// `define HARD_FLOAT
// // `define FLOAT_REAL
// `include "../../svreal/svreal.sv"
`include "axis.vh"
`include "utility.vh"

module opal_com_wrapper #
	(
		// Users to add parameters here
        parameter DATA_WIDHT = 32,
        parameter QTD_VARIABLES_RECEIVE = 16,
        parameter QTD_VARIABLES_SEND = 14,
        parameter OPAL_INPUT_WIDTH = 16,
        parameter AXIS_BYTES = 4,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6
	)
	(
		input wire                           CLK100MHz,
        input wire                           ARESETN, 

        input wire [QTD_VARIABLES_RECEIVE+1:0]          i_data_rx, // variable + enable + clk
        output wire [7:0]             o_data_tx,
        output wire tx_valid,

        output [3:0] state_watch_rx,

        `S_AXI_PORT(s_axi, AXIS_BYTES, C_S_AXI_ADDR_WIDTH)
    );

logic i_clk;
logic i_enable;
logic [(OPAL_INPUT_WIDTH*QTD_VARIABLES_RECEIVE)-1:0] o_data;
logic data_ready;


assign i_clk = i_data_rx[QTD_VARIABLES_RECEIVE+1]; // based on simulink pins
assign i_enable = i_data_rx[QTD_VARIABLES_RECEIVE]; // based on simulink pins


logic [OPAL_INPUT_WIDTH-1:0] from_var1, from_var2, from_var3, from_var4, from_var5, from_var6, from_var7, from_var8, from_var9, from_var10, from_var11, from_var12, from_var13, from_var14, from_var15, from_var16;
logic [7:0] to_var1, to_var2, to_var3, to_var4, to_var5, to_var6, to_var7, to_var8, to_var9, to_var10, to_var11, to_var12, to_var13, to_var14, to_var15, to_var16;


opal_rx # ( 
	.OPAL_INPUT_WIDTH(OPAL_INPUT_WIDTH)	
) opal_com_inst (

	.i_clk 	            ( i_clk ), 
	.i_enable 			( i_enable ), 
	.i_data				( i_data_rx[QTD_VARIABLES_RECEIVE-1:0] ), 
    // .o_data             ( o_data ),
    .o_ready            ( data_ready ),

    .var1 ( from_var1 ),
    .var2 ( from_var2 ),
    .var3 ( from_var3 ),
    .var4 ( from_var4 ),
    .var5 ( from_var5 ),
    .var6 ( from_var6 ),
    .var7 ( from_var7 ),
    .var8 ( from_var8 ),
    .var9 ( from_var9 ),
    .var10 ( from_var10 ),
    .var11 ( from_var11 ),
    .var12 ( from_var12 ),
    .var13 ( from_var13 ),
    .var14 ( from_var14 ),
    .var15 ( from_var15 ),
    .var16 ( from_var16 ),

    .state_watch (state_watch_rx),

	.clk			(CLK100MHz),
	.rst_n			(ARESETN)

);

opal_com_s_axi # ( 
	.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
	.AXI_BYTES(AXIS_BYTES)
) opal_com_s_axi_inst (

	.from_var1 ( {from_var2,from_var1} ),
    .from_var2 ( {from_var4,from_var3} ),
    .from_var3 ( {from_var6,from_var5} ),
    .from_var4 ( {from_var8,from_var7} ),
    .from_var5 ( {from_var10,from_var9} ),
    .from_var6 ( {from_var12,from_var11} ),
    .from_var7 ( {from_var14,from_var13} ),
    .from_var8 ( {from_var16,from_var15} ),
    .to_var1 ( var_to_opal ),
    .to_var2 ( {to_var8,to_var7,to_var6,to_var5} ),
    .to_var3 ( {to_var12,to_var11,to_var10,to_var9} ),
    .to_var4 ( {to_var16,to_var15,to_var14,to_var13} ),
	.s_axi_aclk			    (CLK100MHz),
	.s_axi_aresetn			(ARESETN),
	`AXI_MAP(s_axi, s_axi)

);

// initial var_to_opal = 2;
logic [31:0] var_to_opal;
opal_tx to_var1_inst(
    .clk(i_clk),
    .rst_n(ARESETN),
    .data_in(var_to_opal[7:0]),
    .enable(i_enable),
    .tx(o_data_tx),
    .valid(tx_valid)
);

// assign meas1 = o_data[15];
endmodule