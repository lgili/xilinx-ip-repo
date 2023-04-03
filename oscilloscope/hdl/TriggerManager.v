//******************************************************************************
//TriggerManager	-	Module to handle oscilloscope triggering
//						Settings
//							Ch1Pos - Trigger on positive edge of channel 1
//							Ch1Neg - Trigger on negative edge of channel 1
//							Ch2Pos - Trigger on positive edge of channel 2
//							Ch2Neg - Trigger on negative edge of channel 2
//						Any combination of triggering can be obtained by setting
//							a combination of the setting pins. If all setting
//							pins are low, the module will trigger uncondition-
//							ally unless the reset pin is high.
//						The module will remain triggered until reset externally.
//
//******************************************************************************


module TriggerManager(Ch1Pos, Ch1Neg, Ch2Pos, Ch2Neg, Ch1Comp, Ch2Comp,
		Reset, Trig);
	input	Ch1Pos, Ch1Neg, Ch1Comp;
	input	Ch2Pos, Ch2Neg, Ch2Comp;
	input	Reset;
	output	Trig;

	reg	TrigCh1P;
	reg	TrigCh1N;
	reg	TrigCh2P;
	reg	TrigCh2N;

	always @ (posedge Ch1Comp or posedge Reset) begin
		if (Reset) begin
			TrigCh1P <= 1'b0;
		end else begin
			if (Ch1Pos)	TrigCh1P <= 1'b1;
			else		TrigCh1P <= TrigCh1P;
		end
	end

	always @ (negedge Ch1Comp or posedge Reset) begin
		if (Reset) begin
			TrigCh1N <= 1'b0;
		end else begin
			if (Ch1Neg)	TrigCh1N <= 1'b1;
			else		TrigCh1N <= TrigCh1N;
		end
	end

	always @ (posedge Ch2Comp or posedge Reset) begin
		if (Reset) begin
			TrigCh2P <= 1'b0;
		end else begin
			if (Ch2Pos)	TrigCh2P <= 1'b1;
			else 		TrigCh2P <= TrigCh2P;
		end
	end

	always @ (negedge Ch2Comp or posedge Reset) begin
		if (Reset) begin
			TrigCh2N <= 1'b0;
		end else begin
			if (Ch2Neg)	TrigCh2N <= 1'b1;
			else		TrigCh2N <= TrigCh2N;
		end
	end

	assign Trig =	(TrigCh1P | TrigCh1N | TrigCh2P | TrigCh2N) |
					~(Ch1Pos | Ch1Neg | Ch2Pos | Ch2Neg | Reset);
endmodule