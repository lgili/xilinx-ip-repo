//*******************************************************************************
//** Copyright © 2004,2005,2006, Xilinx, Inc. 
//** This design is confidential and proprietary of Xilinx, Inc. All Rights Reserved.
//*******************************************************************************
//**   ____  ____ 
//**  /   /\/   / 
//** /___/  \  /   Vendor: Xilinx 
//** \   \   \/    Version: 1.0
//**  \   \        Filename: rocket_pll.v 
//**  /   /        Date Last Modified: 6/22/2006 
//** /___/   /\    Date Created: 11/22/2005
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
/// This top level design provides an example of using a digital
//  PLL for recovered clock jitter cleanup.  This design uses an external DAC
//  and VCXO to implement the digital PLL.  Data is recovered by RX and written
//  into a FIFO.  The data is then read from the FIFO into TX side.
//  the recovered RX clock is feed into the digital PLL and the PLL locks to
//  the clock and generates a clean reference clock to the TX RocketIO and FIFO.
//-----------------------------------------------------------------
`timescale 1ns/100ps

module rocket_pll (/*AUTOARG*/
   // Outputs
   MGT105B_TX1N_OUT, MGT105B_TX1P_OUT, MGT105A_RXLOCK_OUT, 
   MGT105A_TXLOCK_OUT, MGT105A_TX1N_OUT, MGT105A_TX1P_OUT, SCLK, SDO, 
   SYNC, RECCLKP, RECCLKN, 
   // Inputs
   UPPER_MGTCLK_PAD_N_IN, UPPER_MGTCLK_PAD_P_IN, 
   LOWER_MGTCLK_PAD_N_IN, LOWER_MGTCLK_PAD_P_IN, SYSTEM_RESET_IN, 
   MGT105B_RX1N_IN, MGT105B_RX1P_IN, MGT105A_RX1N_IN, 
   MGT105A_RX1P_IN, GRESET, GCLK
   );
   input               UPPER_MGTCLK_PAD_N_IN;
   input               UPPER_MGTCLK_PAD_P_IN;
   input               LOWER_MGTCLK_PAD_N_IN;
   input               LOWER_MGTCLK_PAD_P_IN;
   input               SYSTEM_RESET_IN;
   
   input               MGT105B_RX1N_IN;
   input               MGT105B_RX1P_IN;
   output              MGT105B_TX1N_OUT;
   output              MGT105B_TX1P_OUT;
   

   output              MGT105A_RXLOCK_OUT;
   output              MGT105A_TXLOCK_OUT;
   input               MGT105A_RX1N_IN;
   input               MGT105A_RX1P_IN;
   output              MGT105A_TX1N_OUT;
   output              MGT105A_TX1P_OUT;
   input 	       GRESET;
   output 	       SCLK;
   output 	       SDO;
   output 	       SYNC;
   output 	       RECCLKP,RECCLKN;
   input 	       GCLK;

`ifdef SIM
   parameter SIMULATION_P =   1;
`else
   parameter SIMULATION_P =   0;
`endif

   
// *************************** Wire Declarations ******************************
  //-----------------------------------------------------------------
  //
  //  ICON core wire declarations
  //
  //-----------------------------------------------------------------
   wire [35:0] 	       control0;
   wire [63:0] 	       async_in;
   wire [63:0] 	       async_out;
   wire [63:0] 	       sync_in;
   wire [63:0] 	       sync_out;
   wire 	       vcoclki;
   wire 	       usrclk, usrclk2;
   wire 	       outoflock;
   wire 	       rstlock;
   
   //wire 	       reset;
   //wire 	       dclk_i;
   
   //---------------------- Reference Clock Wires ----------------------------
   wire                refclk1_i;
   wire                refclk2_i;

   //------------------------ MGT Wrapper Wires ------------------------------
   //________________________________________________________________________
   //________________________________________________________________________
   //MGT105B   (X0Y2)
    //------------------------ Calibration Block Ports -------------------------
    wire                mgt105b_active_i;
    wire                mgt105b_disable_i;
    //------------------- Dynamic Reconfiguration Port (DRP) -------------------
    wire    [7:0]       daddr_i;
    wire                mgt105b_den_i;
    wire    [15:0]      di_i;
    wire    [15:0]      mgt105b_do_i;
    wire                mgt105b_drdy_i;
    wire                mgt105b_dwe_i;

    //------------------------------ Serial Ports ------------------------------
    wire                MGT105B_RX1N_I;
    wire                MGT105B_RX1P_I;
    wire                MGT105B_TX1N_I;
    wire                MGT105B_TX1P_I;

    //________________________________________________________________________
    //________________________________________________________________________
    //MGT105A   (X0Y3)
    //------------------------ Calibration Block Ports -------------------------
    wire                mgt105a_active_i;
    wire                mgt105a_disable_i;
    wire                mgt105a_rx_signal_detect_i;
    wire                mgt105a_tx_signal_detect_i;
    //--------------------------- Calibration Ports ----------------------------
    wire                mgt105a_rxclkstable_i;
    wire                mgt105a_txclkstable_i;
    //------------------- Dynamic Reconfiguration Port (DRP) -------------------
    wire                mgt105a_den_i;
    wire    [15:0]      mgt105a_do_i;
    wire                mgt105a_drdy_i;
    wire                mgt105a_dwe_i;
    //------------------------------ Global Ports ------------------------------
    wire                mgt105a_powerdown_i;
    wire                mgt105a_txinhibit_i;
    //-------------------------------- PLL Lock --------------------------------
    wire                MGT105A_RXLOCK_I;
    wire                MGT105A_TXLOCK_I;
    //--------------------------------- Resets ---------------------------------
    wire                mgt105a_rxpmareset_i;
    wire                mgt105a_rxreset_i;
    wire                mgt105a_txpmareset_i;
    wire                mgt105a_txreset_i;

    //------------------------------ Serial Ports ------------------------------
    wire                MGT105A_RX1N_I;
    wire                MGT105A_RX1P_I;
    wire                MGT105A_TX1N_I;
    wire                MGT105A_TX1P_I;
    //--------------------------------- Status ---------------------------------
    wire                mgt105a_rxbuferr_i;
    wire    [5:0]       mgt105a_rxstatus_i;
    wire                mgt105a_txbuferr_i;
    //------------------ Transmit Data Path and Control Ports ------------------
    wire    [15:0]      mgt105a_txdata_i;
    //------------------------------ User Clocks -------------------------------
    wire                mgt105a_rxrecclk1_i;
    wire                mgt105a_rxrecclk2_i;
    wire                mgt105a_rxusrclk_i;
    wire                mgt105a_rxusrclk2_i;
    wire                mgt105a_txoutclk1_i;
    wire                mgt105a_txoutclk2_i;
    wire                mgt105a_txusrclk_i;
    wire                mgt105a_txusrclk2_i;
   wire 		dcmreset;
   wire 		recclk;
   wire 		refclk_i;
   wire [63:0] 		vio_din, vio_dout;
   wire 		sclki;
    
    wire    [15:0]      tile1_combusout_a_i;
    wire    [15:0]      tile1_combusout_b_i;
    
   IBUF ibuf_reset(.I(SYSTEM_RESET_IN), .O(reset));

   IBUFG ibufg_dclk (.I(GCLK),.O(gclki));
   
   BUFG bufg_dclk (.I(gclki),.O(dclk_i));

   //--------------------- Instantiate an MGTCLK module  ---------------------
   // Modified to accept either MGTCLK input or CREFCLK input based on UCF file.
   MGT_CLOCK_MODULE mgt_clock_module_i
      (
       //----------------- Input Differential Clocks from Pads ---------------
       .UPPER_MGTCLK_PAD_N_IN(UPPER_MGTCLK_PAD_N_IN),
       .UPPER_MGTCLK_PAD_P_IN(UPPER_MGTCLK_PAD_P_IN),
       .LOWER_MGTCLK_PAD_N_IN(LOWER_MGTCLK_PAD_N_IN),
       .LOWER_MGTCLK_PAD_P_IN(LOWER_MGTCLK_PAD_P_IN),
       //----------------------- Output Reference Clocks ---------------------
       .REFCLK1_OUT(refclk1_i),
       .REFCLK2_OUT(refclk2_i)
       
       );


    defparam rocketio_wrapper_i.SIMULATION_P = SIMULATION_P;
    defparam rocketio_wrapper_i.MGT0_GT11_MODE_P  = "A";
    defparam rocketio_wrapper_i.MGT0_MGT_ID_P     = 0;

    ROCKETIO_WRAPPER rocketio_wrapper_i
    (


        //_____________________________________________________________________
        //_____________________________________________________________________
        //MGT0   (X0Y3)
        //------------------------ Calibration Block Ports -------------------------
        .MGT0_ACTIVE_OUT                (mgt105a_active_i),
        .MGT0_DISABLE_IN                (mgt105a_disable_i),
        .MGT0_DRP_RESET_IN              (reset),
        .MGT0_RX_SIGNAL_DETECT_IN       (mgt105a_rx_signal_detect_i),
        .MGT0_TX_SIGNAL_DETECT_IN       (mgt105a_tx_signal_detect_i),
        //--------------------------- Calibration Ports ----------------------------
        .MGT0_RXCLKSTABLE_IN            (mgt105a_rxclkstable_i),
        .MGT0_TXCLKSTABLE_IN            (mgt105a_txclkstable_i),
        //------------------- Dynamic Reconfiguration Port (DRP) -------------------
        .MGT0_DADDR_IN                  (daddr_i),
        .MGT0_DCLK_IN                   (dclk_i),
        .MGT0_DEN_IN                    (mgt105a_den_i),
        .MGT0_DI_IN                     (di_i),
        .MGT0_DO_OUT                    (mgt105a_do_i),
        .MGT0_DRDY_OUT                  (mgt105a_drdy_i),
        .MGT0_DWE_IN                    (mgt105a_dwe_i),
        //------------------------------ Global Ports ------------------------------
        .MGT0_POWERDOWN_IN              (1'b0),
        .MGT0_TXINHIBIT_IN              (1'b0),
        //-------------------------------- PLL Lock --------------------------------
        .MGT0_RXLOCK_OUT                (MGT105A_RXLOCK_I),
        .MGT0_TXLOCK_OUT                (MGT105A_TXLOCK_I),
        //------------------------- Polarity Control Ports -------------------------
        .MGT0_RXPOLARITY_IN             (1'b0),
        .MGT0_TXPOLARITY_IN             (1'b0),
        //-------------------------- Ports for Simulation --------------------------
        .MGT0_COMBUSIN_IN               (tile1_combusout_b_i),
        .MGT0_COMBUSOUT_OUT             (tile1_combusout_a_i),
        //------------------ Receive Data Path and Control Ports -------------------
        .MGT0_RXDATA_OUT                (mgt105a_txdata_i),
        //---------------------------- Reference Clocks ----------------------------
        .MGT0_REFCLK1_IN                (refclk1_i),
        .MGT0_REFCLK2_IN                (refclk2_i),
        //--------------------------------- Resets ---------------------------------
        .MGT0_RXPMARESET_IN             (reset | mgt105a_rxpmareset_i),	
        .MGT0_RXRESET_IN                (reset | mgt105a_rxreset_i), 
        .MGT0_TXPMARESET_IN             (reset | mgt105a_txpmareset_i),	
        .MGT0_TXRESET_IN                (reset | mgt105a_txreset_i), 
        //------------------------------ Serial Ports ------------------------------
        .MGT0_RX1N_IN                   (MGT105A_RX1N_IN), 
        .MGT0_RX1P_IN                   (MGT105A_RX1P_IN), 
        .MGT0_TX1N_OUT                  (MGT105A_TX1N_OUT),
        .MGT0_TX1P_OUT                  (MGT105A_TX1P_OUT),
        //--------------------------------- Status ---------------------------------
        .MGT0_RXBUFERR_OUT              (mgt105a_rxbuferr_i),
        .MGT0_RXSTATUS_OUT              (mgt105a_rxstatus_i),
        .MGT0_TXBUFERR_OUT              (mgt105a_txbuferr_i),
        //------------------ Transmit Data Path and Control Ports ------------------
        .MGT0_TXDATA_IN                 (mgt105a_txdata_i),
        //------------------------------ User Clocks -------------------------------
        .MGT0_RXRECCLK1_OUT             (mgt105a_rxrecclk1_i ),
        .MGT0_RXRECCLK2_OUT             (mgt105a_rxrecclk2_i ),
        .MGT0_RXUSRCLK_IN               (mgt105a_rxusrclk_i ),
        .MGT0_RXUSRCLK2_IN              (mgt105a_rxusrclk2_i ),
        .MGT0_TXOUTCLK1_OUT             (mgt105a_txoutclk1_i ),
        .MGT0_TXOUTCLK2_OUT             (mgt105a_txoutclk2_i ),
        .MGT0_TXUSRCLK_IN               (mgt105a_txusrclk_i ),
        .MGT0_TXUSRCLK2_IN              (mgt105a_txusrclk2_i )

  );

   
    defparam unused_mgt_0_i.SIMULATION_P = SIMULATION_P;
    defparam unused_mgt_0_i.GT11_MODE_P  = "B";
    defparam unused_mgt_0_i.MGT_ID_P     = 1;      
    UNUSED_MGT unused_mgt_0_i
    (        
        
        //------------------------ Calibration Block Ports -------------------------
        .MGT0_ACTIVE_OUT                (mgt105b_active_i),
        .MGT0_DISABLE_IN                (mgt105b_disable_i),
        .MGT0_DRP_RESET_IN              (reset),
        .MGT0_RX_SIGNAL_DETECT_IN       (1'b0),
        .MGT0_TX_SIGNAL_DETECT_IN       (1'b0),
        //--------------------------- Calibration Ports ----------------------------
        .MGT0_RXCLKSTABLE_IN            (1'b1),
        .MGT0_TXCLKSTABLE_IN            (1'b1),
        //------------------- Dynamic Reconfiguration Port (DRP) -------------------
        .MGT0_DADDR_IN                  (daddr_i),	 
        .MGT0_DCLK_IN                  	(dclk_i),	 
        .MGT0_DEN_IN                   	(mgt105b_den_i), 
        .MGT0_DI_IN                    	(di_i),		 
        .MGT0_DO_OUT                   	(mgt105b_do_i),	 
        .MGT0_DRDY_OUT                 	(mgt105b_drdy_i),
        .MGT0_DWE_IN                   	(mgt105b_dwe_i), 
        //------------------------------- PLL Lock --------------------------------
        .MGT0_RXLOCK_OUT                (),
        .MGT0_TXLOCK_OUT                (),
        //-------------------------- Ports for Simulation --------------------------
        .MGT0_COMBUSIN_IN               (tile1_combusout_a_i),
        .MGT0_COMBUSOUT_OUT             (tile1_combusout_b_i),
        //---------------------------- Reference Clocks ----------------------------
        .MGT0_REFCLK1_IN                (refclk1_i),
        .MGT0_REFCLK2_IN                (refclk2_i),
        //--------------------------------- Resets ---------------------------------
        .MGT0_RXPMARESET_IN             (reset | mgt105a_rxpmareset_i),
        .MGT0_RXRESET_IN                (reset | mgt105a_rxreset_i),   
        .MGT0_TXPMARESET_IN             (reset | mgt105a_txpmareset_i),
        .MGT0_TXRESET_IN                (reset | mgt105a_txreset_i),   
        //------------------------------ Serial Ports ------------------------------
        .MGT0_RX1N_IN                   (MGT105B_RX1N_IN), 
        .MGT0_RX1P_IN                   (MGT105B_RX1P_IN), 
        .MGT0_TX1N_OUT                  (MGT105B_TX1N_OUT),
        .MGT0_TX1P_OUT                  (MGT105B_TX1P_OUT)
    );



   
   assign 		mgt105a_rxusrclk_i = ~usrclk;
   assign 		mgt105a_rxusrclk2_i = usrclk2;
 
   assign 		mgt105a_txusrclk_i = ~usrclk;
   assign 		mgt105a_txusrclk2_i = usrclk2;

   BUFG CLK_BUFG_INST (.I(refclk1_i),  .O(vcoclki));//, .I1(grefclk_i), .S(vcoclk_sel),

 

   OBUFDS rxrecclk1_buf (.I(recclk),.O(RECCLKP),.OB(RECCLKN));

   OBUF rxlock_buf (.I(MGT105A_RXLOCK_I),.O(MGT105A_RXLOCK_OUT));
   OBUF txlock_buf (.I(MGT105A_TXLOCK_I),.O(MGT105A_TXLOCK_OUT));

   // Clock DCM to generate USRCLK's
   
   clock_gen clock_geni (
			 .CLKIN_IN(vcoclki),
			 .CLKDV_OUT(usrclk),
			 .CLK0_OUT(usrclk2),
			 .LOCKED_OUT(dcm_locked),
			 .RST_IN(dcmreset | reset) 
			 );
`ifdef SIM

   assign 		async_out = 63'h0000000000000000;
   assign 		daddr_i[7:0]      = 8'h00;
   assign 		mgt105b_dwe_i     = 0;
   assign 		mgt105b_den_i     = 0;
   assign 		mgt105b_disable_i = 0;
   assign 		mgt105a_dwe_i     = 0;
   assign 		mgt105a_den_i     = 0;
   assign 		mgt105a_disable_i = 0;
   assign 		di_i[15:0]        = 16'h0000;
   
   assign 		mgt105a_rx_signal_detect_i = 1;
   assign 		mgt105a_tx_signal_detect_i = 1;
   assign 		mgt105a_rxclkstable_i      = 1;
   assign 		mgt105a_txclkstable_i      = 1;

   assign 		mgt105a_rxpmareset_i = reset;
   assign 		mgt105a_rxreset_i    = reset;
   assign 		mgt105a_txpmareset_i = reset;
   assign 		mgt105a_txreset_i    = reset;
   assign 		dcmreset = 0;
   assign 		rstlock = 0;
   
`else

   assign 		daddr_i[7:0]      = vio_dout[7:0];
   assign 		mgt105b_dwe_i     = vio_dout[9];
   assign 		mgt105b_den_i     = vio_dout[11];
   assign 		mgt105b_disable_i = vio_dout[13];
   assign 		mgt105a_dwe_i     = vio_dout[8];
   assign 		mgt105a_den_i     = vio_dout[10];
   assign 		mgt105a_disable_i = vio_dout[12];
   assign 		di_i[15:0]        = vio_dout[31:16];
   
   assign 		mgt105a_rx_signal_detect_i = vio_dout[14];
   assign 		mgt105a_tx_signal_detect_i = vio_dout[15];
   assign 		mgt105a_rxclkstable_i      = vio_dout[32];
   assign 		mgt105a_txclkstable_i      = vio_dout[33];

   assign 		mgt105a_rxpmareset_i = vio_dout[34];
   assign 		mgt105a_rxreset_i    = vio_dout[35];
   assign 		mgt105a_txpmareset_i = vio_dout[36];
   assign 		mgt105a_txreset_i    = vio_dout[37];
   assign 		dcmreset = vio_dout[38];
   assign 		rstlock = vio_dout[42];
   
   assign               vio_din[31:16] = mgt105b_do_i[15:0];
   assign 		vio_din[35]    = mgt105b_active_i;
   assign 		vio_din[34]    = mgt105b_drdy_i;
   assign               vio_din[15:0 ] = mgt105a_do_i[15:0];
   assign 		vio_din[33]    = mgt105a_active_i;
   assign 		vio_din[32]    = mgt105a_drdy_i;
   assign 		vio_din[36]    = MGT105A_RXLOCK_I;
   assign 		vio_din[37]    = MGT105A_TXLOCK_I;
   assign 		vio_din[38]    = mgt105a_rxbuferr_i;
   assign 		vio_din[45:40] = mgt105a_rxstatus_i[5:0];
   assign 		vio_din[39]    = mgt105a_txbuferr_i;
   assign 		vio_din[46]    = dcm_locked;
   assign 		vio_din[47]    = outoflock;

   
  //-----------------------------------------------------------------
  //
  //  ICON core instance
  //
  //-----------------------------------------------------------------
  icon i_icon
    (
      .control0(control0)
    );


  //-----------------------------------------------------------------
  //
  //  VIO core instance
  //
  //-----------------------------------------------------------------
  vio i_vio
    (
      .control(control0),
      .clk(sclki),
      .async_in(async_in),
      .async_out(async_out),
      .sync_in(vio_din),
      .sync_out(vio_dout)
    );
   
`endif // !`ifdef SIM

// selects either external reference input or Recovered Clock from RocketIO   
   assign recclk = mgt105a_rxrecclk1_i;

//-----------------------------------------------------------------
// Digital PLL instance.
//-----------------------------------------------------------------

   dpll dpll_i (
		// Outputs
		.SCLK(SCLK), 
		.SDO(SDO), 
		.SYNC(SYNC),
		.vio_in(async_in),
		.outoflock(outoflock),
		.sclki (sclki),
		// Inputs
		.rstlock(rstlock),
		.refclki(recclk),
		.vcoclk(vcoclki), 
		.vio_out(async_out)
		);

endmodule // rocket_pll
