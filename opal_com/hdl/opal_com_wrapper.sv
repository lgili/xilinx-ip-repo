
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
        parameter QTD_VARIABLES = 16,
        parameter OPAL_INPUT_WIDTH = 16,
        parameter AXIS_BYTES = 4,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6
	)
	(
		input wire                           CLK100MHz,
        input wire                           ARESETN, 

        input wire [QTD_VARIABLES+1:0]          i_data, // variable + enable + clk

        `S_AXI_PORT(s_axi, AXIS_BYTES, C_S_AXI_ADDR_WIDTH)
    );

logic i_clk;
logic i_enable;
logic [QTD_VARIABLES-1:0] o_data [OPAL_INPUT_WIDTH-1:0];
logic data_ready;

assign i_clk = i_data[QTD_VARIABLES+1]; // based on simulink pins
assign i_enable = i_data[QTD_VARIABLES]; // based on simulink pins
logic [OPAL_INPUT_WIDTH-1:0] var1, var2, var3, var4, var5, var6, var7, var8, var9, var10, var11, var12, var13, var14, var15, var16;
logic [OPAL_INPUT_WIDTH-1:0] meas1, meas2, meas3, meas4, meas5, meas6, meas7, meas8, meas9, meas10, meas11, meas12, meas13, meas14, meas15, meas16;


opal_com # ( 
	.OPAL_INPUT_WIDTH(OPAL_INPUT_WIDTH)	
) opal_com_inst (

	.i_clk 	            ( i_clk ), 
	.i_enable 			( i_enable ), 
	.i_data				( i_data[QTD_VARIABLES-1:0] ), 
    .o_data             ( o_data ),
    .o_ready            ( data_ready ),

    .var1 ( var1 ),
    .var2 ( var2 ),
    .var3 ( var3 ),
    .var4 ( var4 ),
    .var5 ( var5 ),
    .var6 ( var6 ),
    .var7 ( var7 ),
    .var8 ( var8 ),
    .var9 ( var9 ),
    .var10 ( var10 ),
    .var11 ( var11 ),
    .var12 ( var12 ),
    .var13 ( var13 ),
    .var14 ( var14 ),
    .var15 ( var15 ),
    .var16 ( var16 ),

	.clk			(CLK100MHz),
	.rst_n			(ARESETN)

);

opal_com_s_axi # ( 
	.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
	.AXI_BYTES(AXIS_BYTES)
) opal_com_s_axi_inst (

	.var1 ( {var2,var1} ),
    .var2 ( {var4,var3} ),
    .var3 ( {var6,var5} ),
    .var4 ( {var8,var7} ),
    .var5 ( {var10,var9} ),
    .var6 ( {var12,var11} ),
    .var7 ( {var14,var13} ),
    .var8 ( {var16,var15} ),
    // .var9 ( {var1,var2} ),
    // .var10 ( {var1,var2} ),
    // .var11 ( {var1,var2} ),
    // .var12 ( {var1,var2} ),
	.s_axi_aclk			    (CLK100MHz),
	.s_axi_aresetn			(ARESETN),
	`AXI_MAP(s_axi, s_axi)

);


endmodule