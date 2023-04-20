// `default_nettype	none
// }}}
module	dblcordicpll #(
		// {{{
		parameter	IW = 16, // input width
				PW = 32, // phase width in bits
				OW = IW, // output width
		parameter [0:0]	OPT_TRACK_FREQUENCY = 1'b1,
		//
		// OPT_FILTER
		// {{{
		// It is possible to place a filter into the middle of this
		// operation.  With the filter, you can achieve a much sharper
		// out of band cutoff at the expense of some band-edge peaking.
		// This implementation only approximates the correct filter
		// when OPT_TRACK_FREQUENCY is set.
		parameter [0:0]	OPT_FILTER = 1'b1
		// }}}
		// }}}
	) (
		// {{{
		input	wire				i_clk,
		// Frequency control
		input	wire				i_ld,
		input	wire		[PW-1:0]	i_step,
		// Incoming signal
		input	wire				i_ce,
		input	wire	signed	[IW-1:0]	i_input,
		// Tracking control
		input	wire	[4:0]			i_lgcoeff,
		// Outgoiing error
		output	wire	[OW-1:0]		o_err
		// }}}
	);

	// Internal register/wire declarations
	// {{{
	reg	[PW-1:0]		r_phase, r_step;
	wire				pm_busy, pm_done;
	wire	signed	[IW-1:0]	pm_sin, pm_cos;
	//
	wire				fil_ce;
	reg	signed	[IW-1:0]	fil_sin, fil_cos;
	//
	wire				pd_busy, pd_done;
	wire	[IW-1:0]		pd_mag;
	wire	signed [PW-1:0]		pd_phase;
	reg	[4:0]			log_gamma;
	reg	signed [PW-1:0]		phase_correction;


	reg	s_reset;

	initial	s_reset  = 1'b1;
	always @(posedge i_clk)
		s_reset <= 1'b0;
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Multiply
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	seqcordic
	phasemultiply (
		.i_clk(i_clk), 
		.i_reset(s_reset), 
		.i_stb(i_ce), 
		.i_xval({(IW){1'b0}}), 
		.i_yval(i_input),
		.i_phase(~r_phase), 
		.o_busy(pm_busy), 
		.o_done(pm_done), 
		.o_xval(pm_cos), 
		.o_yval(pm_sin)
		);
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Filter
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	generate if (OPT_FILTER && OPT_TRACK_FREQUENCY)
	begin
		// {{{
		reg		[2:0]		shift_ce;
		reg	signed	[IW-1:0]	diff_sin, diff_cos,
						tripl_sin, tripl_cos;
		reg	[5:0]			log_alpha;

		always @(*)
			log_alpha = i_lgcoeff - 1;

		always @(posedge i_clk)
			shift_ce <= { shift_ce[1:0], pm_done };

		always @(posedge i_clk)
		if (pm_done)
		begin
			diff_sin <= pm_sin - fil_sin;
			diff_cos <= pm_cos - fil_cos;
		end

		always @(posedge i_clk)
		if (shift_ce[0])
		begin
			tripl_sin <= diff_sin + (diff_sin >>> 1);
			tripl_cos <= diff_cos + (diff_cos >>> 1);
		end

		always @(posedge i_clk)
		if (shift_ce[1])
		begin
			fil_sin <= fil_sin + (tripl_sin >>> log_alpha);
			fil_cos <= fil_cos + (tripl_cos >>> log_alpha);
		end

		assign	fil_ce = shift_ce[2];
		// }}}
	end else if (OPT_FILTER)
	begin
		// {{{
		reg		[1:0]		shift_ce;
		reg	signed	[IW-1:0]	diff_sin, diff_cos;
		reg	[5:0]			log_alpha;

		always @(*)
			log_alpha = i_lgcoeff - 2;


		always @(posedge i_clk)
			shift_ce <= { shift_ce[0], pm_done };


		always @(posedge i_clk)
		if (pm_done)
		begin
			diff_sin <= pm_sin - fil_sin;
			diff_cos <= pm_cos - fil_cos;
		end

		always @(posedge i_clk)
		if (shift_ce[0])
		begin
			fil_sin <= fil_sin + (diff_sin >>> log_alpha);
			fil_cos <= fil_cos + (diff_cos >>> log_alpha);
		end

		assign	fil_ce = shift_ce[1];
		// }}}
	end else begin
		// {{{
		assign	fil_ce  = pm_done;
		always @(*)
			fil_sin = pm_sin;
		always @(*)
			fil_cos = pm_cos;
		// }}}
	end endgenerate
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Atan2 phase detect
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	seqpolar
	phasedet(i_clk, s_reset, fil_ce, fil_cos, fil_sin, pd_busy,
			pd_done, pd_mag, pd_phase);

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Tracking loops
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(*)
		log_gamma = i_lgcoeff;

	// Track frequency
	generate if (OPT_TRACK_FREQUENCY)
	begin
		// {{{
		reg	[5:0]			log_beta;
		reg	signed [PW-1:0]		freq_correction;

		always @(*)
			// beta = gamma ^2 / 4
			log_beta = { i_lgcoeff, 1'b0 } + 2;

		always @(*)
			freq_correction = pd_phase >>> log_beta;

		always @(posedge i_clk)
		if (i_ld)
			r_step <= i_step;
		else if (pd_done)
			r_step <= r_step - freq_correction;
		// }}}
	end else begin
		// {{{
		always @(posedge i_clk)
		if (i_ld)
			r_step = i_step;
		// }}}
	end endgenerate

	assign	o_err = pd_phase[PW-1:PW-OW];

	// Track phase
	// {{{
	always @(*)
		phase_correction = pd_phase >>> log_gamma;

	always @(posedge i_clk)
	if (pd_done)
		r_phase <= r_phase + r_step - phase_correction;
	// }}}
	// }}}

	// Make Verilator happy
	// {{{
	// Verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, pm_busy, pd_busy, pd_mag };
	// Verilator lint_on  UNUSED
	// }}}
endmodule