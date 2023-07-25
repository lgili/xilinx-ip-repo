


module opal_tx(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic enable,
    output logic [7:0] tx,
    output valid
);

assign valid = clk;
    // Transmit logic
  always_ff @(posedge clk)
    if (!rst_n)
      tx <= '0;
    else begin
      tx <= data_in;      
    end
    

endmodule
