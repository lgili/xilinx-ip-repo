
package definitions;

typedef enum {S_IDLE, S_HIGH, S_LOW, S_GET, S_WAIT, S_FAIL} state_t;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

parameter OPAL_TIMEOUT_WIDTH = 12;
parameter OPAL_TIMEOUT_VALUE = 1500;
endpackage

module opal_rx

/* BEGIN PARAMETERS LIST */
	#(
        parameter QTD_VARIABLES = 16,        
        parameter OPAL_INPUT_WIDTH = 16
	)
	/* END PARAMETERS LIST */ 
	
	/* BEGIN MODULE IO LIST */
	(
		input clk,
        input rst_n,

        input i_clk,
		input i_enable,		
		input [QTD_VARIABLES-1:0] i_data,
		
		// output logic [(OPAL_INPUT_WIDTH*QTD_VARIABLES)-1:0] o_data,
        output logic [OPAL_INPUT_WIDTH-1:0] var1,
        output logic [OPAL_INPUT_WIDTH-1:0] var2,
        output logic [OPAL_INPUT_WIDTH-1:0] var3,
        output logic [OPAL_INPUT_WIDTH-1:0] var4,
        output logic [OPAL_INPUT_WIDTH-1:0] var5,
        output logic [OPAL_INPUT_WIDTH-1:0] var6,
        output logic [OPAL_INPUT_WIDTH-1:0] var7,
        output logic [OPAL_INPUT_WIDTH-1:0] var8,
        output logic [OPAL_INPUT_WIDTH-1:0] var9,
        output logic [OPAL_INPUT_WIDTH-1:0] var10,
        output logic [OPAL_INPUT_WIDTH-1:0] var11,
        output logic [OPAL_INPUT_WIDTH-1:0] var12,
        output logic [OPAL_INPUT_WIDTH-1:0] var13,
        output logic [OPAL_INPUT_WIDTH-1:0] var14,
        output logic [OPAL_INPUT_WIDTH-1:0] var15,
        output logic [OPAL_INPUT_WIDTH-1:0] var16,
		output reg o_busy,
        output o_ready,
        output [3:0] state_watch
	);

import definitions::*;

localparam OPAL_DATA_CNT_WIDTH = $clog2(OPAL_INPUT_WIDTH);

state_t state, next_state;
logic [OPAL_TIMEOUT_WIDTH-1:0] tocnt;

logic error;
logic pkg_is_transmitting;


logic [OPAL_DATA_CNT_WIDTH-1:0] var_bit_cnt;
logic [QTD_VARIABLES-1:0] din;
logic [0:QTD_VARIABLES-1] dout [OPAL_INPUT_WIDTH-1:0];
initial begin
var_bit_cnt <= 0;
pkg_is_transmitting <=0;
end



function automatic logic [OPAL_INPUT_WIDTH-1:0] reverseBits(input logic [OPAL_INPUT_WIDTH-1:0] in_data);
    logic [OPAL_INPUT_WIDTH-1:0] reversed_data;
    for (int i = 0; i < OPAL_INPUT_WIDTH; i++) begin
        reversed_data[i] = in_data[(OPAL_INPUT_WIDTH-1) - i];
    end
    return reversed_data;
endfunction

assign din = i_data;
assign state_watch = state;

integer i;
always_ff@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		state <= S_IDLE;
    else if(error == TRUE)
        state <= S_FAIL;
	else
		state <= next_state;
end

// next state logic
always_comb begin : next_state_logic
	  next_state = S_IDLE;
	  case(state)
		S_IDLE: begin
            if(i_enable == TRUE) begin
                if(i_clk == FALSE) begin
                    next_state = S_LOW;
                end
                else begin
                    next_state = S_HIGH;
                end 
            end
            else 
                next_state = S_IDLE;
         end
		S_HIGH: begin            
            if(i_clk == FALSE) begin
                next_state = S_GET;
            end
            else begin
                next_state = S_HIGH;
            end 
        end
		S_LOW: begin            
             if(i_clk == TRUE) begin
                next_state = S_HIGH;
            end
            else begin
                next_state = S_LOW;
            end 
        end
		S_GET: begin            
             if(pkg_is_transmitting == TRUE) begin
                next_state = S_WAIT;
            end
            else begin
                next_state = S_LOW;
            end 
        end
        S_WAIT: begin            
             if(i_enable == FALSE) begin
                next_state = S_IDLE;
            end
            else begin
                next_state = S_WAIT;
            end 
        end
        S_FAIL: begin         
            next_state = S_IDLE;            
        end
        default : next_state = S_IDLE;
	  endcase
end

assign o_ready = (pkg_is_transmitting == TRUE) ? 1 : 0;


always_ff@(posedge clk) begin : state_logic 
    case(state)
    S_IDLE: begin
        for (i=0; i<QTD_VARIABLES; i=i+1) begin
            dout[i] <= 'b0;            
        end
        
        var_bit_cnt <= 0;
        pkg_is_transmitting <=0;
       
        
    end
    S_HIGH, S_LOW: begin
       if(var_bit_cnt == (OPAL_INPUT_WIDTH-1))
            pkg_is_transmitting = TRUE;
    end  
    S_GET: begin
        var_bit_cnt <= var_bit_cnt + 1'b1;
        for (i=0; i<QTD_VARIABLES; i=i+1) begin
            dout[i] <= {dout[i], din[i]};
        end        
    end  
    S_WAIT: begin 
        var_bit_cnt <= 0; 
        // for (i=0; i<QTD_VARIABLES; i=i+1) begin
        //     o_data[i] <= dout[i];
        // end        
        var1 <= reverseBits(dout[0]);
        var2 <= reverseBits(dout[1]);
        var3 <= reverseBits(dout[2]);
        var4 <= reverseBits(dout[3]);
        var5 <= reverseBits(dout[4]);
        var6 <= reverseBits(dout[5]);
        var7 <= reverseBits(dout[6]);
        var8 <= reverseBits(dout[7]);
        var9 <= reverseBits(dout[8]);
        var10 <= reverseBits(dout[9]);
        var11 <= reverseBits(dout[10]);
        var12 <= reverseBits(dout[11]);
        var13 <= reverseBits(dout[12]);
        var14 <= reverseBits(dout[13]);
        var15 <= reverseBits(dout[14]);
        var16 <= reverseBits(dout[15]);

        pkg_is_transmitting = FALSE;
    end
    S_FAIL: begin 
        tocnt <= 0;
        error <= 0;
    end
    endcase
end

always_ff@(posedge clk) begin : error_logic 
    casez(state)
        S_IDLE: begin 
            tocnt <= 0;
            error <= 0;
        end
        S_HIGH, S_LOW, S_GET, S_WAIT: begin
            if (tocnt < OPAL_TIMEOUT_VALUE) begin
                tocnt <= tocnt + 1;
                error <= 0;
            end
            else begin
                error <= 1;
            end
        end        
    endcase
end

endmodule 