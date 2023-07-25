


module opal_tx(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic enable,
    output logic [7:0] tx,
    output logic valid
);


    // Transmit logic
  always_ff @(posedge clk)
    if (!rst_n)
      tx <= '0;
    else if (enable) begin
      tx <= data_in;
      valid <= 1;
    end
    else begin
      tx <= '0;
      valid <= 0;
    end

endmodule
