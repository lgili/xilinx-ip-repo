//*******************************************************************************
//** Copyright © 2004,2005,2006, Xilinx, Inc. 
//** This design is confidential and proprietary of Xilinx, Inc. All Rights Reserved.
//*******************************************************************************
//**   ____  ____ 
//**  /   /\/   / 
//** /___/  \  /   Vendor: Xilinx 
//** \   \   \/    Version: 1.0
//**  \   \        Filename: spi.v 
//**  /   /        Date Last Modified: 6/22/2006 
//** /___/   /\    Date Created: 11/12/2004
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
//-----------------------------------------------------------------
//  Serial peripheral interface circuit to shift data out to DAC
//  consists of 16:1 mux and obuf's
//-----------------------------------------------------------------
`timescale 1ns/100ps
`ifdef TPDA
`else
 `define TPDB #0.1
 `define TPDA #0.1
`endif

module spi(/*AUTOARG*/
   // Outputs
   SYNC, SDO, SCLK,  
   // Inputs
   clk, data, isync, sclki, clkendac, bitsel
   );
   input clk;            // input clock
   input [15:0] data;    // parallel input data from loopfilter
   input 	isync;   // input sync signal indicates start of words
   input 	sclki;   // input clock signal for DAC
   input 	clkendac;// clock enable for clk
   input [3:0] 	bitsel;  // bit select for DAC transmission
   output 	SYNC;    // Buffered signal to DAC
   output 	SDO;     // Buffered signal to DAC
   output 	SCLK;    // Buffered signal to DAC

   reg 		syn,dout,en,busy;
   reg [3:0] 	cnt;
   reg [15:0] 	datav;
   reg 		clko;
   
   OBUF sclk_buf (.O(SCLK), .I(clko));
   OBUF sdo_buf  (.O(SDO),  .I(dout));
   OBUF sync_buf (.O(SYNC), .I(syn));
   
   always@(posedge clk) begin
      clko <= `TPDB sclki;
      if(clkendac) begin
	 if(!isync)
	    datav <= `TPDB data;
	 syn <= `TPDB ~isync;
	 dout <= `TPDB datav[bitsel];
      end
   end
   
   
endmodule // spi

     
