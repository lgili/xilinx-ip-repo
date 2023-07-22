

module opal_com 

/* BEGIN PARAMETERS LIST */
	#(
		parameter TICKS_PER_BIT = 32,
		parameter TICKS_PER_BIT_SIZE = 6,
        parameter OPAL_CHANNEL_LENGTH = 24,
        parameter OPAL_TIMEOUT_WIDTH = 12, 
        parameter OPAL_INPUT_WIDTH = 16
	)
	/* END PARAMETERS LIST */ 
	
	/* BEGIN MODULE IO LIST */
	(
		input clk,
        input rst_n,

        input i_clk,
		input i_enable,		
		input [OPAL_CHANNEL_LENGTH-1:0] i_data,
		
		output [OPAL_CHANNEL_LENGTH-1:0] o_data,
		output reg o_busy
	);

localparam OPAL_DATA_CNT_WIDTH = $clog2(OPAL_INPUT_WIDTH);

enum int unsigned { S_IDLE = 0, S_HIGH = 2, S_GET = 4, S_LOW = 8, S_WAIT = 16, S_FAIL = 32 } state, next_state;
logic [4:0] sigma;
logic [4:0] delta;
logic [OPAL_TIMEOUT_WIDTH-1:0] tocnt;

logic [OPAL_DATA_CNT_WIDTH-1:0] cnt;
logic [OPAL_CHANNEL_LENGTH-1:0] din;
logic [0:OPAL_CHANNEL_LENGTH-1] dout [OPAL_INPUT_WIDTH-1:0];

assign delta[0] = i_enable;
assign delta[1] = i_clk;
assign din = i_data;

always_ff@(posedge clk or negedge rst_n) begin
	  if(~rst_n)
		 state <= S_IDLE;
    else if(delta[3] == 1'b1)
         state <= S_FAIL;
	  else
		 state <= next_state;
end



always_comb begin : next_state_logic
	  next_state = S_IDLE;
      sigma = 0;
	  case(state)
		S_IDLE: begin
            sigma[0] = 1;
            if(delta[0] == 1) begin
                if(delta[1] == 0) begin
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
            sigma[1] = 1;
            if(delta[1] == 0) begin
                next_state = S_GET;
            end
            else begin
                next_state = S_HIGH;
            end 
        end
		S_LOW: begin
            sigma[1] = 1;
             if(delta[1] == 1) begin
                next_state = S_HIGH;
            end
            else begin
                next_state = S_LOW;
            end 
        end
		S_GET: begin
            sigma[2] = 1;
             if(delta[2] == 1) begin
                next_state = S_WAIT;
            end
            else begin
                next_state = S_LOW;
            end 
        end;
        S_WAIT: begin
            sigma[3] = 1;
             if(delta[0] == 0) begin
                next_state = S_IDLE;
            end
            else begin
                next_state = S_WAIT;
            end 
        end;
        S_FAIL: begin
            sigma[0] = 1;            
            next_state = S_IDLE;            
        end;
	  endcase
end

    always @(posedge clk) begin 
        if(!rst_n) begin
            dout <= 0;
            cnt <= 0;
            o_dout <= 0;
            delta[2] <= 0;
        end
        else if(sigma[0] == 1) begin
            delta[2] <= 0;
            dout <= 0;
            cnt <= 0;
        end
        else if(sigma[1] == 1) begin
            if cnt == OPAL_INPUT_WIDTH-1 begin
                delta[2] <= 1;
            end
        end
        else if(sigma[2] == 1) begin
            cnt <= cnt + 1;
            // data_0_s <= {data_0_s[14:0], data_0_i};
                
            
        end
        else if(sigma[3] == 1) begin
            delta[2] <= 0;
            cnt <= 0;                
            // for i in opal.dout'range loop
            //     o_dout(i) <= resize(opal.dout(i), o_dout(i)'length);
            // end loop;
        end
    end

    always @(posedge clk) begin 

    end

endmodule 