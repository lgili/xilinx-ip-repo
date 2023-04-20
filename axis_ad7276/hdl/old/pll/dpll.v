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

`timescale 1ns/100ps
`ifdef TPDA
`else
 `define TPDB #0.1
 `define TPDA #0.1
`endif

module dpll (/*AUTOARG*/
   // Outputs
   SCLK, SDO, SYNC, vio_in, outoflock, sclki, 
   // Inputs
   refclki, vcoclk, vio_out, rstlock
   );
   input refclki;          // Reference Clock input
   input vcoclk;           // Clock from VCO
   output SCLK,SDO,SYNC;   // Output signals to control DAC
   input [63:0] vio_out;   // Chipscope vio control bus
   output [63:0] vio_in;   // Chipscope vio monitor bus
   output 	 outoflock;// signal to indicate out of lock condition 
   input 	 rstlock;  // Clear latched outoflock signal
   output 	 sclki;    // low-freq sclk output used for chipscope clock
   
   wire [3:0] bitsel;
   wire       clkendac,isync;
   wire [15:0] vc,vcx;
   wire [8:0]  phase_error;
   wire [31:0] integrator;
   wire       refclk,vcoclk;
   wire       rst;
   wire [8:0] ph_error;
   wire [8:0] f_error;
   wire [7:0] divcnt;
   wire [15:0] fixed_vc;
   wire        vc_sel;
   wire [3:0]  beta, alpha;
   wire [2:0]  refsel,vsel;
   reg 	      outoflock;
     
`ifdef SIM
   // This sections indicate default values for simultion
   // if implementing in a design which does not need programmablity
   // user can use this block to set values for synthesis
   assign      rst          = 0;    // reset signal for entire pll
   assign      divcnt[7:0]  = 8'h08;// controls speed of DAC clock
   assign      beta[3:0]    = 4'h0; // 1st order gain constant
   assign      alpha[3:0]   = 4'h4; // 2nd order gain constant
   assign      select       = 0;    // 0 phase detector : 1 = freq detector
   assign     fixed_vc[15:0] = 16'hbeef; // fixed DAC value when vc_sel = 0
   assign     vc_sel    = 1;        // select between fixed DAC value and dynamic
   assign     refsel       = 1;     // counter selection for freq detector
   assign     vsel       = 0;       // counter selection for freq detector
`else
   // remove this and chipscope busses if implementing in a design
   // which does not need programmability.
   assign     divcnt[7:0]  = vio_out[63:56];
   assign     rst          = vio_out[42];
   assign     refsel       = vio_out[2:0];
   assign     vsel       = vio_out[6:4];
   assign     beta[3:0]    = vio_out[55:52];
   assign     alpha[3:0]   = vio_out[51:48];
   assign     select       = vio_out[43];
   assign     fixed_vc[15:0] = vio_out[23:8];
   assign     vc_sel    = vio_out[41];
`endif


   
   BUFG refclk_bufg (.O(refclk) , .I(refclki));
   
  // PLL divider circuit controls DAC and LP clocking
   vcodiv vcodiv(
		 // Outputs
		 .clkendac		(clkendac),
		 .rstcnt		(rstcnt),
		 .bitsel		(bitsel[3:0]),
		 .sync			(isync),
		 .sclk			(sclki),
		 // Inputs
		 .clk			(vcoclk),
		 .divcnt		(divcnt)
		 );

   // Accumulating Bang-Bang phase detector
   pd pd(
	   // Outputs
	   .data			(),
	   .phase_error			(phase_error),
	   // Inputs
	   .refsig			(refclki),
	   .rstcnt			(rstcnt),
	   .vcoclk			(vcoclk),
	   .reset			(rst)
	   );
   
   // Frequency Detector
   fd fd_i(   // Outputs
	    .error	(f_error),
	    // Inputs
	    .refsig  (refclk), 
	    .vcoclk  (vcoclk),
	    .reset   (rst),
	    .refsel  (refsel),
	    .rstcnt  (rstcnt),
            .vcosel  (vsel)
	    );

   
   // mux input to loopfilter between ABB-Phase detector and Frequency Detector
   assign      ph_error = (select) ? f_error : phase_error;
   
   // digital dual path loop filter
   lp lp(
	 // Outputs
	 .vc				(vc[15:0]),
	 // Inputs
	 .clk				(vcoclk),
	 .clken				(clkendac),
	 .error	       		        (ph_error),
	 .beta				(beta),
	 .alpha				(alpha),
	 .rstcnt			(rstcnt),
	 .rstint                        (rst)
	 );

   // select between fixed and closed loop control voltage values
   assign vcx = (vc_sel) ? vc : fixed_vc;

   // out of lock register
   always@(posedge vcoclk or posedge rst)
      if(rst)
	 outoflock <= `TPDB 0;
      else if(rstlock)
	 outoflock <= `TPDB 0;
      else if (vc[11:0] > 12'hf00 | vc[11:0] < 12'h0ff)
	 outoflock <= `TPDB 1;
   
		 
   // Serial Peripheral Interface to DAC
   /*spi spi(
	   // Outputs
	   .SYNC			(SYNC),
	   .SDO				(SDO),
	   .SCLK			(SCLK),
	   // Inputs
	   .clk				(vcoclk),
	   .sclki			(sclki),
	   .data			(vcx[15:0]),
	   .isync			(isync),
	   .clkendac			(clkendac),
	   .bitsel			(bitsel[3:0])
	   );*/
   
   // assigns status signals to Chipscope Pro VIO bus
   assign  vio_in = {7'h00,ph_error,vcx,16'h0000};
   
endmodule // dpll
