//Generates a synchronous reset for one period after reset
//en is an enable signal, e.g. from a PLL lock indicator

module reset_gen(clk_slow, reset_in, reset_out);

parameter POLARITY = 0;
parameter COUNT = 3;

localparam integer CTR_WIDTH = $clog2(COUNT);

input clk_slow, reset_in;
output reset_out;

//Lattice guarantees that all registers will contain 0 on power up
reg [CTR_WIDTH-1:0] ctr = 0;

always @(posedge clk_slow)
	if(reset_in && clk_slow)
	begin
		if(ctr != COUNT-1) //Halt on 10
			ctr <= ctr + 1'b1;
	end

if (POLARITY)
	assign reset_out = !(ctr == COUNT-1); //Active high
else
	assign reset_out = (ctr == COUNT-1); //Active low
endmodule