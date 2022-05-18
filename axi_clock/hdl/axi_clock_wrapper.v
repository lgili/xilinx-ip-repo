
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
	module axi_clock_wrapper #
	(
		// Users to add parameters here

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer AXI_LITE_DATA_WIDTH	= 32,		
		parameter integer AXI_ADDR_WIDTH	= 5,
		// depth of synchronizer
    		parameter N = 2		
		
	)
	(
		// Users to add ports here
	   
		
				
			
		input wire                        s_axi_aclk,			
        input wire                        aresetn, 
        input wire 						  in_clock,        
        
		output wire                       out_clock,		
		output wire                       resetn,      
                         
		
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
		input wire  s_axi_rready
		
			
		
	);
	
///////////////////////////////////////////////////////////////////////////
//
// signals 
//
///////////////////////////////////////////////////////////////////////////


		

wire	[AXI_LITE_DATA_WIDTH-1:0] clockDivider; 


	
    
// Instantiation of Axi Bus Interface S_AXI
	axi_clock_s_axi # ( 
		.AXI_DATA_WIDTH(AXI_LITE_DATA_WIDTH),
		.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
	) 	clock_v1_s_axi_inst (
			
		.ClockDivider 	( clockDivider ), 		
		
		.S_AXI_ACLK			(s_axi_aclk),
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
	
   axi_clock_divider #	(
		.AXI_DATA_WIDTH(AXI_LITE_DATA_WIDTH)		
	) axi_clock_divider_inst
	(
	    .clk(in_clock),
	    .rstn(aresetn),
	    .clockDiv(clockDivider),
	    .clk_div(out_clock)
    );
   
   
/*
 * Synchronizes an active-low asynchronous reset signal to a given clock by
 * using a pipeline of N registers.
 */   
(* srl_style = "register" *)
reg [N-1:0] sync_reg = {N{1'b1}};

assign resetn = !sync_reg[N-1];

always @(posedge out_clock or negedge aresetn) begin
    if (!aresetn) begin
        sync_reg <= {N{1'b1}};
    end else begin
        sync_reg <= {sync_reg[N-2:0], 1'b0}; 
    end
end
    
endmodule

