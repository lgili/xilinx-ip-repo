
package definitions;

typedef enum {S_IDLE, S_HIGH, S_LOW, S_GET, S_WAIT, S_FAIL} state_t;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

parameter OPAL_TIMEOUT_WIDTH = 12;
parameter OPAL_TIMEOUT_VALUE = 1500;
endpackage

module opal_com 

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
		
		output [QTD_VARIABLES-1:0] o_data [OPAL_INPUT_WIDTH-1:0],
        output [OPAL_INPUT_WIDTH-1:0] var1,
        output [OPAL_INPUT_WIDTH-1:0] var2,
        output [OPAL_INPUT_WIDTH-1:0] var3,
        output [OPAL_INPUT_WIDTH-1:0] var4,
        output [OPAL_INPUT_WIDTH-1:0] var5,
        output [OPAL_INPUT_WIDTH-1:0] var6,
        output [OPAL_INPUT_WIDTH-1:0] var7,
        output [OPAL_INPUT_WIDTH-1:0] var8,
        output [OPAL_INPUT_WIDTH-1:0] var9,
        output [OPAL_INPUT_WIDTH-1:0] var10,
        output [OPAL_INPUT_WIDTH-1:0] var11,
        output [OPAL_INPUT_WIDTH-1:0] var12,
        output [OPAL_INPUT_WIDTH-1:0] var13,
        output [OPAL_INPUT_WIDTH-1:0] var14,
        output [OPAL_INPUT_WIDTH-1:0] var15,
        output [OPAL_INPUT_WIDTH-1:0] var16,
		output reg o_busy,
        output o_ready
	);

import definitions::*;

localparam OPAL_DATA_CNT_WIDTH = $clog2(OPAL_INPUT_WIDTH);

state_t state, next_state;
logic [4:0] sigma;
logic [4:0] delta;
logic [OPAL_TIMEOUT_WIDTH-1:0] tocnt;

logic error;
logic pkg_is_transmitting;

logic [OPAL_DATA_CNT_WIDTH-1:0] cnt;
logic [OPAL_DATA_CNT_WIDTH-1:0] var_bit_cnt;
logic [QTD_VARIABLES-1:0] din;
logic [QTD_VARIABLES-1:0] dout [OPAL_INPUT_WIDTH-1:0];
logic [OPAL_INPUT_WIDTH-1:0] data;
initial begin
cnt <= 0;
var_bit_cnt <= 0;
pkg_is_transmitting <=0;
end

function integer reverseBits;
	input integer in_data;
	begin 
	reverseBits = ({in_data[0],in_data[1],in_data[2],in_data[3],in_data[4],in_data[5],in_data[6],in_data[7],in_data[8],in_data[9],in_data[10],in_data[11],in_data[12],in_data[13],in_data[14],in_data[15]})>>1;

	end 
endfunction
assign var1 = (pkg_is_transmitting) ? reverseBits(dout[0]) : var1;
assign var2 = (pkg_is_transmitting) ? reverseBits(dout[1]) : var2;
assign var3 = (pkg_is_transmitting) ? reverseBits(dout[2]) : var3;
assign var4 = (pkg_is_transmitting) ? reverseBits(dout[3]) : var4;
assign var5 = (pkg_is_transmitting) ? reverseBits(dout[4]) : var5;
assign var6 = (pkg_is_transmitting) ? reverseBits(dout[5]) : var6;
assign var7 = (pkg_is_transmitting) ? reverseBits(dout[6]) : var7;
assign var8 = (pkg_is_transmitting) ? reverseBits(dout[7]) : var8;
assign var9 = (pkg_is_transmitting) ? reverseBits(dout[8]) : var9;
assign var10 = (pkg_is_transmitting) ? reverseBits(dout[9]) : var10;
assign var11 = (pkg_is_transmitting) ? reverseBits(dout[10]) : var11;
assign var12 = (pkg_is_transmitting) ? reverseBits(dout[11]) : var12;
assign var13 = (pkg_is_transmitting) ? reverseBits(dout[12]) : var13;
assign var14 = (pkg_is_transmitting) ? reverseBits(dout[13]) : var14;
assign var15 = (pkg_is_transmitting) ? reverseBits(dout[14]) : var15;
assign var16 = (pkg_is_transmitting) ? reverseBits(dout[15]) : var16;

assign o_data[15] = (pkg_is_transmitting) ? dout[15] : o_data[15];

assign din = i_data;
integer i;
always_ff@(posedge clk or negedge rst_n or next_state) begin
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

// assign pkg_is_transmitting = (var_bit_cnt == (OPAL_INPUT_WIDTH-1));
assign o_ready = (pkg_is_transmitting == TRUE) ? 0 : 1;

always_comb begin : state_logic 
    case(state)
    S_IDLE: begin
        for (i=0; i<QTD_VARIABLES; i=i+1) begin
            dout[i] <= 'b0;
            // o_data[i] <= 'b0;
        end
        data <= 0;
        
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
        // for (i=0; i<QTD_VARIABLES; i=i+1) begin
        //     o_data[i] <= dout[i];
        // end
                
        data <= dout[15];
    end  
    S_WAIT: begin 
        var_bit_cnt <= 0;
        pkg_is_transmitting = FALSE;
    end
    endcase
end

    always_comb begin : error_logic 
        case(state)
            S_IDLE: begin 
                tocnt <= 0;
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