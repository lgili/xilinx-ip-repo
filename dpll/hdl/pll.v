
`default_nettype	none
// }}}
module	pll #(
		parameter	PHASE_BITS = 32,
		parameter	[0:0]	OPT_TRACK_FREQUENCY = 1'b1,
		parameter	[PHASE_BITS-1:0]	INITIAL_PHASE_STEP = 0,
		parameter	[0:0]	OPT_GLITCHLESS = 1'b1,
		parameter IN_DATA_WIDTH = 12,
		localparam	MSB=PHASE_BITS-1
		
	) (
		input	wire			i_clk,
		input	wire			i_rstn,
		//
		input	wire			i_ld,
		input	wire	[(MSB-1):0]	i_step,
		//
		input	wire			i_ce,
		input	wire			i_input,
		input	wire	[11:0]	phase_a,
		input	wire	[11:0]	phase_b,
		input	wire	[11:0]	phase_c,
		input	wire	[4:0]		i_lgcoeff,
		output	wire	[PHASE_BITS-1:0] o_phase,
		output	reg	[15:0]		o_err		
	);

localparam VALUE = 32767/1.164435; // reduce by a factor of 1.647 since thats the gain of the system

wire signed [15:0] signed_phase_a;
wire signed [15:0] signed_phase_b;
wire signed [15:0] signed_phase_c;

reg signed [15:0] sin;
reg signed [15:0] cos;
reg signed [15:0] theta_o;

assign signed_phase_a = phase_a - 2047;
assign signed_phase_b = phase_b - 2047;
assign signed_phase_c = phase_c - 2047;

// sdpll #(
		
// ) sdpll(
// 	.i_clk(i_clk),
// 	.i_ld(i_ld),
// 	.i_step(i_step),
// 	.i_ce(i_ce),
// 	.i_input(phase_a[IN_DATA_WIDTH-1]),
// 	.i_lgcoeff(i_lgcoeff),
// 	.o_phase(o_phase),
// 	.o_err(o_err)	
// );

dblcordicpll #() sdpll(
	.i_clk(i_clk),
	.i_ld(i_ld),
	.i_step(i_step),
	.i_ce(i_ce),
	.i_input(signed_phase_a),
	.i_lgcoeff(i_lgcoeff),
	// .o_phase(o_phase),
	.o_err(o_err)
);

// cordic #
// (
//     // .DATA_WIDTH(PHASE_BITS)
// ) sin_cos
// (
//     .i_clk(i_clk),
//     .i_reset(!i_rstn),
//     .i_ce(i_ce),
//     .i_phase(o_phase), 
//     .i_xval(VALUE), 
//     .i_yval(1'd0), 
//     .o_xval(cos),
//     .o_yval(sin)    
// );
// cordic #(
	
// )sin_cos (
//   .clk(i_clk),
//   .rst(!i_rstn),

//   .x_i(`CORDIC_1),
//   .y_i(1'd0),
//   .theta_i(o_phase),
 
//   .x_o(cos),
//   .y_o(sin),
//   .theta_o(theta_o) 
// );	
endmodule