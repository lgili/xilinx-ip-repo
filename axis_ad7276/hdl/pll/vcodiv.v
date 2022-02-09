//*******************************************************************************
//** Copyright © 2004,2005,2006, Xilinx, Inc. 
//** This design is confidential and proprietary of Xilinx, Inc. All Rights Reserved.
//*******************************************************************************
//**   ____  ____ 
//**  /   /\/   / 
//** /___/  \  /   Vendor: Xilinx 
//** \   \   \/    Version: 1.0
//**  \   \        Filename: vcodiv.v 
//**  /   /        Date Last Modified: 6/22/2006 
//** /___/   /\    Date Created: 11/9/2004
//** \   \  /  \ 
//**  \___\/\___\ 
//** 
//**   
//*******************************************************************************
//**
//**  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//**              provided to you "as is." Xilinx and its licensors make and you
//**              receive no warranties or conditions, express, implied,
//**              statutory or otherwise, and Xilinx specifically disclaims any
//**              implied warranties of merchantability, noninfringement, or
//**              fitness for a particular purpose. Xilinx does not warrant that
//**              the functions contained in these designs will meet your
//**              requirements, or that the operation of these designs will be
//**              uninterrupted or error free, or that defects in the Designs
//**              will be corrected. Furthermore, Xilinx does not warrant or
//**              make any representations regarding use or the results of the
//**              use of the designs in terms of correctness, accuracy,
//**              reliability, or otherwise.
//**
//**              LIMITATION OF LIABILITY. In no event will Xilinx or its
//**              licensors be liable for any loss of data, lost profits, cost
//**              or procurement of substitute goods or services, or for any
//**              special, incidental, consequential, or indirect damages
//**              arising from the use or operation of the designs or
//**              accompanying documentation, however caused and on any theory
//**              of liability. This limitation will apply even if Xilinx
//**              has been advised of the possibility of such damage. This
//**              limitation shall apply notwithstanding the failure of the
//**              essential purpose of any limited remedies herein.
//**
//*******************************************************************************
// This file provides necessary dividers, clocks and strobes necessary to write
// data to the serial DAC device.  It currently supports the AD5320


`timescale 1ns/100ps
`ifdef TPDA
`else
 `define TPDB #0.1
 `define TPDA #0.1
`endif

module vcodiv(/*AUTOARG*/
   // Outputs
   clkendac, rstcnt, bitsel, sync, sclk, 
   // Inputs
   clk, divcnt
   );
   input clk;           // input clock
   input [7:0] divcnt;  // programmable divider value
   output clkendac;     // output clock enable signal for dac circuits
   output rstcnt;       // output reset to Accumulating bang-bang phase detector
   output [3:0] bitsel; // bit selection for transmission to DAC.
   output 	sync;   // sync signal for DAC transmission
   output 	sclk;   // output clock to DAC

   reg [3:0] 	bitsel;
   reg 		rstcnt;
   wire		clkendac;
   reg [7:0] 	cnt;
   reg 		sync;
   
   initial begin
      cnt = 1;
      bitsel = 4'hf;
      sync = 0;
      rstcnt = 0;
   end
   
   always@(posedge clk) begin
      cnt <= `TPDB (cnt < divcnt) ? cnt + 1 : 8'h01;
      if(clkendac & bitsel == 4'h3) 
	 rstcnt <= `TPDB 1;
      else // single clk pulse
	 rstcnt <= `TPDB 0;
      if (clkendac) begin
	 if(bitsel == 4'h0) begin
	    bitsel <= `TPDB 4'hf;
	    sync <= `TPDB 0;
	 end
	 else if(sync)
	    bitsel <= `TPDB bitsel - 1;
	 else 
	    sync <= `TPDB 1;
      end
   end
      
   assign clkendac = (cnt == divcnt);
   assign sclk = (cnt <= {1'b0,divcnt[7:1]});

   
endmodule 
