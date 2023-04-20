// Repeatedly output a byte vector as an AXI stream
// This could be replaced with axis_width converter at some point...

`include "axis.vh"
`include "utility.vh"

module vector_to_axis
#(
	parameter VEC_BYTES = 2,
	parameter AXIS_BYTES = 1,
	parameter MSB_FIRST = 0
) (
	input clk,
	input sresetn,

	input [(VEC_BYTES*8)-1:0] vec,

	`M_AXIS_PORT_NO_USER(axis, AXIS_BYTES)
);

`STATIC_ASSERT(VEC_BYTES % AXIS_BYTES == 0);


localparam integer CTR_MAX = (VEC_BYTES/AXIS_BYTES) -1;

localparam integer CTR_WIDTH = CTR_MAX == 0? 1 : $clog2(CTR_MAX +1);

logic [CTR_WIDTH-1:0] ctr;
/* verilator lint_off WIDTH */
localparam [CTR_WIDTH-1:0] CTR_INIT = MSB_FIRST? CTR_MAX : 0;
localparam [CTR_WIDTH-1:0] CTR_LAST = MSB_FIRST? 0       : CTR_MAX;
/* verilator lint_on WIDTH */

always @(posedge clk)
begin
	if (sresetn == 0)
	begin
		ctr <= CTR_INIT;
	end else begin
		if (axis_tready == 1)
		begin
			if (ctr == CTR_LAST)
			begin
				ctr <= CTR_INIT;
			end else begin
				if(MSB_FIRST)
					ctr <= ctr - 1;
				else
					ctr <= ctr + 1;
			end
		end
	end
end

assign axis_tvalid = sresetn; // Valid whenver not in reset
assign axis_tlast = (ctr == CTR_LAST) ? 1'b1 : 1'b0;
/* verilator lint_off WIDTH */
assign axis_tdata = vec[ ((ctr+1)*AXIS_BYTES*8)-1 -: AXIS_BYTES*8];
/* verilator lint_on WIDTH */
assign axis_tkeep = '1;

endmodule