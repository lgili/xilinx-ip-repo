module pwm_wrapper #(
  parameter DW = 8,
  parameter PWM_CLK_DIV = 10
) (
  input  logic                 CLK100MHz,
  input  logic                 ARESETN,
  input  logic [DW-1:0] duty,
  output logic                 pwm
);

  logic [DW-1:0] counter, counterNext;
  logic pwmNext;
  logic slow_clk;

  clock_divider#(
	.DIV_WIDTH(PWM_CLK_DIV)    		// Number of divider
  ) pwm_clock (
        .clk_in(CLK100MHz),				// clock in
        .div_ctrl(PWM_CLK_DIV/2),	// divider control
        .rstn(ARESETN),				// reset (active low)
        .clk_out(slow_clk),			// clock out
        .clk_out_b()		// complementary clock out
    );

  always_comb begin
    counterNext = counter + 1;

    if (counter >= duty) begin
      pwmNext = 1;
    end
    else begin
      pwmNext = 0;
    end
  end

  always_ff @(posedge slow_clk or negedge ARESETN) begin
    if (!ARESETN) begin
      counter <= 0;
      pwm     <= 0;
    end
    else begin
      counter <= counterNext;
      pwm     <= pwmNext;
    end
  end

endmodule