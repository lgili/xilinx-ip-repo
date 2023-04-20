//*******************************************************************************
//** Copyright © 2004,2005,2006, Xilinx, Inc. 
//** This design is confidential and proprietary of Xilinx, Inc. All Rights Reserved.
//*******************************************************************************
//**   ____  ____ 
//**  /   /\/   / 
//** /___/  \  /   Vendor: Xilinx 
//** \   \   \/    Version: 1.0
//**  \   \        Filename: lp.v 
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
// Patent Pending
//-----------------------------------------------------------------
//  Digital Dual Loop Filter
//
//-----------------------------------------------------------------
`timescale 1ns/100ps
`ifdef TPDA
`else
 `define TPDB #0.1
 `define TPDA #0.1
`endif

module lp (/*AUTOARG*/
   // Outputs
   vc, 
   // Inputs
   clk, clken, error, beta, alpha, rstcnt, rstint
   );
   input clk;         // input clock
   input clken;       // clock enable to run at DAC rate
   input [8:0] error; // error input signal
   input [3:0] beta;  // controls the 1st order loop gain
   input [3:0] alpha; // controls the 2nd order loop gain
   input rstcnt;      // reset signal indicating sample
   output [15:0] vc;  // output control voltage to DAC
   input rstint;      // signal to reset integrator
   
   reg [15:0]  vc;
   reg [31:0]  integrator;
   reg load;
   reg [11:0]  b1,a1;
   wire [31:0] new_int;
   wire [11:0] new_vc,new_vcx;
   wire [11:0] vc_new;
   
   initial begin
      integrator = 32'h00006cc0;
      vc = 16'd1676;
   end
 
// register the control voltage(vc) and integrator  
   always@(posedge clk) begin
      if ((rstcnt))
	 load <= `TPDB 1;
      else if(clken)
	 load <= `TPDB 0;
      if (rstint) 
	 integrator <= `TPDB 32'h00000000;
      else if(load & clken) begin
	 integrator <= `TPDB new_int;
	 vc <= `TPDB new_vc;
      end
   end

   // sum first and second order outputs
   assign new_vc = b1 + a1;

   assign new_int = integrator + {{23{error[8]}},error};
   
   // Simple way to saturate the Control Voltage similar to what an Analog filter would do.
   //  assign `TPDA vc_new = (vc[11:8] == 4'hf & new_vc[11:8] == 4'h0) ? 16'h0FFF : (vc[11:8] == 4'h0 & new_vc[11:8] == 4'hf) ? 16'h0000 : {4'h0,new_vc[11:0]};
   
   
//-----------------------------------------------------------------
// Gain Stages
//-----------------------------------------------------------------

   always@(posedge clk)
      case(beta)
	 4'h0 : b1 = {{3{error[8]}},error}; // keep sign
	 4'h1 : b1 = {{4{error[8]}},error[8:1]};
	 4'h2 : b1 = {{5{error[8]}},error[8:2]};
	 4'h3 : b1 = {{6{error[8]}},error[8:3]};
	 4'h4 : b1 = {{7{error[8]}},error[8:4]};
	 4'h5 : b1 = {{8{error[8]}},error[8:5]};
	 4'h6 : b1 = {{9{error[8]}},error[8:6]};
	 4'h7 : b1 = {{10{error[8]}},error[8:7]};
	 4'h8 : b1 = {{11{error[8]}},error[8:8]};
	 4'h9 : b1 = 12'h0; // not valid
	 4'ha : b1 = 12'h0;
	 4'hb : b1 = 12'h0;
	 4'hc : b1 = 12'h0;
	 4'hd : b1 = 12'h0;
	 4'he : b1 = 12'h0;
	 4'hf : b1 = 12'h0;
      endcase // case(beta)
   always@(posedge clk)
      case(alpha)
	 4'h0 : a1 = new_int[11:0]; // keep sign
	 4'h1 : a1 = new_int[12:1];
	 4'h2 : a1 = new_int[13:2];
	 4'h3 : a1 = new_int[14:3];
	 4'h4 : a1 = new_int[15:4];
	 4'h5 : a1 = new_int[16:5];
	 4'h6 : a1 = new_int[17:6];
	 4'h7 : a1 = new_int[18:7];
	 4'h8 : a1 = new_int[19:8];
	 4'h9 : a1 = new_int[20:9];
	 4'ha : a1 = new_int[21:10];
	 4'hb : a1 = new_int[22:11];
	 4'hc : a1 = new_int[23:12];
	 4'hd : a1 = new_int[24:13];
	 4'he : a1 = new_int[25:14];
	 4'hf : a1 = new_int[26:15];
      endcase // case(beta)
   

endmodule // div8
