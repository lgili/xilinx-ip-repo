//*******************************************************************************
//** Copyright © 2004,2005,2006, Xilinx, Inc. 
//** This design is confidential and proprietary of Xilinx, Inc. All Rights Reserved.
//*******************************************************************************
//**   ____  ____ 
//**  /   /\/   / 
//** /___/  \  /   Vendor: Xilinx 
//** \   \   \/    Version: 1.0
//**  \   \        Filename: fd.v 
//**  /   /        Date Last Modified: 6/22/2006 
//** /___/   /\    Date Created: 12/23/2004
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
//  This block is the frequency detector circuit which is useful for
//  digitally recovered clock signals. 
//-----------------------------------------------------------------
`timescale 1ns/1fs
`ifdef TPDA
`else
 `define TPDB #0.1
 `define TPDA #0.1
`endif

module fd (/*AUTOARG*/
   // Outputs
   error, 
   // Inputs
   refsig, vcoclk, rstcnt, reset, refsel, vcosel
   );
   input refsig;         // reference clock signal 
   input vcoclk;         // clock from VCO
   input rstcnt;         // reset signal for Accumulating BB
   output [8:0] error;   // Output error signal     
   input  reset;         // Reset all circuits
   input [2:0] refsel;   // selection of input counter terminal count
   input [2:0] vcosel;   // selection of input counter terminal count
   
   
   reg [8:0] 	error;
   reg [10:0] 	refcnt, vcocnt;
   reg 		refreset1,refreset;
   reg 		vcoreset1,vcoreset;

   reg 		a,b,t,ta;
   reg 		up, down;
   wire 	data;
   reg 		rsig,vsig;
   reg  [11:0] 	upcnt,dncnt;
   wire [11:0] 	new_pe;
   reg 	[1:0]	redge;

   initial begin
      upcnt = 0;
      dncnt = 0;
      error = 0;
   end

// input counters selection   
   always@(refsel or refcnt)
      case(refsel)
	 3'h0 : rsig = refcnt[2];
	 3'h1 : rsig = refcnt[3];
	 3'h2 : rsig = refcnt[4];
	 3'h3 : rsig = refcnt[5];
	 3'h4 : rsig = refcnt[6];
	 3'h5 : rsig = refcnt[7];
	 3'h6 : rsig = refcnt[8];
	 3'h7 : rsig = refcnt[9];
      endcase // case(refsel)
   always@(vcosel or vcocnt)
      case(vcosel)
	 3'h0 : vsig = vcocnt[2];
	 3'h1 : vsig = vcocnt[3];
	 3'h2 : vsig = vcocnt[4];
	 3'h3 : vsig = vcocnt[5];
	 3'h4 : vsig = vcocnt[6];
	 3'h5 : vsig = vcocnt[7];
	 3'h6 : vsig = vcocnt[8];
	 3'h7 : vsig = vcocnt[9];
      endcase // case(refsel)
   

//-----------------------------------------------------------------
// Standard Bang-Bang Phase Detector
//-----------------------------------------------------------------
   
   always@(negedge vsig)
      ta <= `TPDB rsig;
   
   
   always@(posedge vsig)
   begin
      b <= `TPDB rsig;
      a <= `TPDB b;
      t <= `TPDB ta;
   end
  
//-----------------------------------------------------------------
// Decode phase detector outputs
//-----------------------------------------------------------------

   always@(a or b or t)
      case({a,t,b})
	 3'b000 : begin // no trans
	    up = 0;
	    down = 0;
	 end
	 3'b001 : begin // too fast
	    up = 0;
	    down = 1;
	 end
	 3'b010 : begin // invalid
	    up = 1;
	    down = 1;
	    $display("Error in PFD %b %b %b %t",a,t,b,$time);
	 end
	 3'b011 : begin // too slow
	    up = 1;
	    down = 0;
	 end
	 3'b100 : begin // too slow
	    up = 1;
	    down = 0;
	 end
	 3'b101 : begin // invalid
	    up = 1;
	    down = 1;
	    $display("Error in PFD %b %b %b %t",a,t,b,$time);
	 end
	 3'b110 : begin // too fast
	    up = 0;
	    down = 1;
	 end
	 3'b111 : begin // no trans
	    up = 0;
	    down = 0;
	 end
      endcase // case(a,t,b)


//-----------------------------------------------------------------
// Up and Down Counters
// up/down counters count on higher speed vcoclk and increase the 
// gain of the phase detector to compensate for the lower gain
// from the divided clock inputs.   
//-----------------------------------------------------------------

   always@(posedge vcoclk) begin
      if(rstcnt) begin
	 upcnt <= `TPDB 12'h0000;
	 dncnt <= `TPDB 12'h0000;
	 error  <= `TPDB {new_pe[11],new_pe[7:0]};
      end
      else if(up & !down)
	 upcnt <= `TPDB upcnt + 1;
      else if(down & !up)
	 dncnt <= `TPDB dncnt + 1;
   end

   assign new_pe = upcnt - dncnt;

//-----------------------------------------------------------------
// wrap-around counters and reset retiming
//   
//-----------------------------------------------------------------

   always@(posedge refsig or posedge refreset)
      if(refreset) begin
	 refcnt <= `TPDB 11'h0000;
      end
      else begin
	 refcnt <= `TPDB refcnt + 1;
      end
   always@(posedge vcoclk or posedge vcoreset)
      if(vcoreset) begin
	 vcocnt <= `TPDB 11'h0000;
      end
      else begin
	 vcocnt <= `TPDB vcocnt + 1;
      end

  
   always@(posedge refsig or posedge reset)
      if(reset) begin
	 refreset1 <= `TPDB 1;
	 refreset <= `TPDB 1;
      end
      else begin
	 refreset1 <= `TPDB 0;
	 refreset <= `TPDB refreset1;
      end
   always@(posedge vcoclk or posedge reset)
      if(reset) begin
	 vcoreset1 <= `TPDB 1;
	 vcoreset <= `TPDB 1;
      end
      else begin
	 vcoreset1 <= `TPDB 0;
	 vcoreset <= `TPDB vcoreset1;
      end
	
   
endmodule // fd
