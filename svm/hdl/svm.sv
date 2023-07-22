
interface svm_t
  logic [4:0] CA1;
  logic [4:0] CA2;
  logic [4:0] CA3;
  logic [4:0] CB1;
  logic [4:0] CB2;
  logic [4:0] CB3;
  logic [4:0] CC1;
  logic [4:0] CC2;
  logic [4:0] CC3;
  logic [4:0] DA1;
  logic [4:0] DA2;
  logic [4:0] DA3;
  logic [4:0] DB1;
  logic [4:0] DB2;
  logic [4:0] DB3;
  logic [4:0] DC1;
  logic [4:0] DC2;
  logic [4:0] DC3;
endinterface 

interface vls_t
    logic [4:0] L;
    logic [4:0] G;
endinterface

module opal_com 

/* BEGIN PARAMETERS LIST */
	#(
		parameter DATA_WIDTH = 32,		
	)
	/* END PARAMETERS LIST */ 
	
	/* BEGIN MODULE IO LIST */
	(
		input clk,
        input rst_n,

		input i_enable,		
        input [DATA_WIDTH-1:0] vin,
    )

  vls_t Vu();  	
		


endmodule