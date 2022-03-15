


module pid #
(
    parameter DATA_WIDTH=32
) // bit width – 1
(
    input wire Clk,
    input wire Resetn,

    output signed [DATA_WIDTH:0] u_out, // output
    input signed [DATA_WIDTH:0] e_in // input
    
);

//k1= kp + ki + kd;
//k2=-kp – 2*kd;
//k3= kd;
parameter KP = 0.8 * (2 ** DATA_WIDTH);
parameter KI = 1.2 * (2 ** DATA_WIDTH);
parameter KD = 0;
parameter k1= KP +KI + KD; // change these values to suit your system
parameter k2 = -KP - 2*(KD) ;
parameter k3 = KD;

reg signed [DATA_WIDTH:0] u_prev;
reg signed [DATA_WIDTH:0] e_prev[1:2];

assign u_out = u_prev + k1*e_in - k2*e_prev[1] + k3*e_prev[2];

always @ (posedge Clk)
if (Resetn == 0) begin
    u_prev <= 0;
    e_prev[1] <= 0;
    e_prev[2] <= 0;
end
else begin
    e_prev[2] <= e_prev[1];
    e_prev[1] <= e_in;
    u_prev <= u_out;
end
endmodule