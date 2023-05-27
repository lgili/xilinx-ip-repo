// Copyright (C) 2019 Joshua Tyler
//
//  This Source Code Form is subject to the terms of the                                                    │
//  Open Hardware Description License, v. 1.0. If a copy                                                    │
//  of the OHDL was not distributed with this file, You                                                     │
//  can obtain one at http://juliusbaxter.net/ohdl/ohdl.txt

// Join together multiple AXIS streams
// I.e. output a packet from stream 1, then stream 2 etc.

`include "axis.vh"

module axis_joiner_tdest
#(
	parameter AXIS_BYTES = 1,
	parameter AXIS_USER_BITS = 1,
	parameter NUM_STREAMS = 1
) (
	input clk,
	input sresetn,
	input wire enable,
	input wire [8*AXIS_BYTES-1:0] words_to_send,

	`S_AXIS_MULTI_PORT_TDEST(axis_i, NUM_STREAMS, AXIS_BYTES, AXIS_USER_BITS),
	

	`M_AXIS_PORT_TDEST(axis_o, AXIS_BYTES)
);

localparam integer CTR_WIDTH = NUM_STREAMS == 1? 1 : $clog2(NUM_STREAMS);
/* verilator lint_off WIDTH */
localparam CTR_MAX = NUM_STREAMS-1;

// wire enable;
// assign enable = (mst_exec_state == FINISHED_STREAM) ? 1'b0 : enable_signal;  

reg [CTR_WIDTH-1:0] ctr;

always @(posedge clk)
begin
	if (sresetn == 0 || enable == 0)
	begin
		ctr <= 0;
	end else begin
		if (axis_o_tready && axis_o_tvalid && axis_i_tlast[ctr])
		begin
			if (ctr == CTR_MAX)
			begin
				ctr <= 0;
			end else begin
				ctr <= ctr + 1;
			end
		end
	end
end

genvar i;
generate
	for(i=0; i< NUM_STREAMS; i++)
			assign axis_i_tready[i] = (i == ctr)? axis_o_tready : 0;
endgenerate

wire [(AXIS_BYTES*8)-1:0] num_of_words; 
assign num_of_words = words_to_send * NUM_STREAMS;

assign axis_o_tvalid = axis_i_tvalid[ctr] && axis_tvalid_delay;
// assign axis_o_tlast = (ctr == CTR_MAX)? axis_i_tlast[ctr] : 0; //Only output tlast on last packet
assign axis_o_tlast = axis_tlast_delay;  // num_of_words need to be multiple of NUM_STREAMS to this work
assign axis_o_tkeep = axis_i_tkeep[(1+ctr)*(AXIS_BYTES)-1 -: AXIS_BYTES];
assign axis_o_tdata = axis_i_tdata[(1+ctr)*(AXIS_BYTES*8)-1 -: AXIS_BYTES*8];
assign axis_o_tuser = axis_i_tuser[(1+ctr)*(AXIS_USER_BITS)-1 -: AXIS_USER_BITS];
assign axis_o_tdest = axis_i_tdest[(1+ctr)*(AXIS_BYTES)-1 -: AXIS_BYTES];
/* verilator lint_on WIDTH */

// function called clogb2 that returns an integer which has the                      
// value of the ceiling of the log base 2.                                           
function integer clogb2 (input integer bit_depth);                                   
	begin                                                                              
	for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
		bit_depth = bit_depth >> 1;                                                    
	end                                                                                
endfunction                                                                         
	                                                                                     
// WAIT_COUNT_BITS is the width of the wait counter.                                 
localparam integer WAIT_COUNT_BITS = clogb2(C_M_START_COUNT-1);                      
localparam C_M_START_COUNT = 32;

// Define the states of state machine                                                
// The control state machine oversees the writing of input streaming data to the FIFO,
// and outputs the streaming data from the FIFO                                      
parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state               
																						
				INIT_COUNTER  = 2'b01, // This state initializes the counter, once   
								// the counter reaches C_M_START_COUNT count,        
								// the state machine changes state to SEND_STREAM     
				SEND_STREAM   = 2'b10, // In this state the                          
								// stream data is output through M_AXIS_TDATA   
				FINISHED_STREAM = 2'b11;				
// State variable                                                                    
reg [1:0] mst_exec_state;                                                            
// Example design FIFO read pointer                                                  
reg [8*AXIS_BYTES-1:0] read_pointer;     
reg [8*AXIS_BYTES-1:0] read_pointer_helper;                                                    

// AXI Stream internal signals
//wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
reg [8*AXIS_BYTES-1 : 0] 	count;
//streaming data valid
wire  	axis_tvalid;
//streaming data valid delayed by one clock cycle
reg  	axis_tvalid_delay;
//Last of the streaming data 
wire  	axis_tlast;
//Last of the streaming data delayed by one clock cycle
reg  	axis_tlast_delay;
//FIFO implementation signals
reg [8*AXIS_BYTES-1 : 0] 	stream_data_out;
wire  	tx_en;
//The master has issued all the streaming data stored in FIFO
reg  	tx_done;


// Control state machine implementation                             
always @(posedge clk)                                             
begin                                                                     
	if (!sresetn)                                                    
	// Synchronous reset (active low)                                       
	begin                                                                 
		mst_exec_state <= IDLE;                                             
		count    <= 0;                                                      
	end                                                                   
	else                                                                    
	case (mst_exec_state)                                                 
		IDLE:                                                               
		// The slave starts accepting tdata when                          
		// there tvalid is asserted to mark the                           
		// presence of valid streaming data                               
		//if ( count == 0 )                                                 
		//  begin                                                           
			                              
			mst_exec_state  <= INIT_COUNTER;  
		//  end                                                             
		//else                                                              
		//  begin                                                           
		//    mst_exec_state  <= IDLE;                                      
		//  end                                                             
																			
		INIT_COUNTER:                                                       
		// The slave starts accepting tdata when                          
		// there tvalid is asserted to mark the                           
		// presence of valid streaming data                               
		if ( count >= C_M_START_COUNT - 1  && enable == 1)                               
			begin                                                           
			mst_exec_state  <= SEND_STREAM;    
			                         
			end                                                             
		else                                                              
			begin                                                           
			count <= count + 1;                                           
			mst_exec_state  <= INIT_COUNTER;    
			//enable <= 1'b0;    
			                     
			end                                                             
																			
		SEND_STREAM:                                                        
		// The example design streaming master functionality starts       
		// when the master drives output tdata from the FIFO and the slave
		// has finished storing the S_AXIS_TDATA                          
		if (tx_done)                                                      
			begin                                                           
			mst_exec_state <= FINISHED_STREAM;                                       
			end                                                             
		else                                                              
			begin                                                           
			mst_exec_state <= SEND_STREAM;                                
			end  
		FINISHED_STREAM:
			if(enable == 1'b0)
				mst_exec_state <= IDLE; 
			else
				mst_exec_state <= FINISHED_STREAM;

	endcase                                                               
end                                                                       

//tvalid generation
//axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
//number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.

assign axis_tvalid = (mst_exec_state == SEND_STREAM) && enable;
																								
// AXI tlast generation                                                                        
// axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1          
// (0 to NUMBER_OF_OUTPUT_WORDS-1)  
                                                       
assign axis_tlast = (read_pointer_helper >= num_of_words -5 && read_pointer_helper <= num_of_words + 0);  // we have 2 clk delay   

// Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
// to match the latency of M_AXIS_TDATA   
reg [1:0] delay_reg;                                                     
always @(posedge clk)                                                                  
begin                                                                                          
	if (!sresetn)                                                                         
	begin                                                                                      
		axis_tvalid_delay <= 1'b0;                                                               
		axis_tlast_delay <= 1'b0; 
		delay_reg <= 1'b0;                                                                
	end                                                                                        
	else                                                                                         
	begin     

		delay_reg <= delay_reg + 1'b1;
		axis_tvalid_delay <= axis_tvalid; 
		if(delay_reg == 2 && axis_tlast )  begin                   
			axis_tlast_delay <= axis_tlast;       
		end                                                   
	end                                                                                        
end   


//read_pointer pointer
// assign tx_done = !enable;

always@(posedge clk)                                               
begin                                                                            
	if(!sresetn)                                                            
	begin                                                                        
		read_pointer <= 0;                                                         
		tx_done <= 1'b0;                                                           
	end                                                                          
	else   
	if(mst_exec_state == SEND_STREAM)  
		tx_done <= 1'b0;  

	if (read_pointer <= num_of_words -1)                             
		begin                                                                      
		if (tx_en)                                                                                                
			begin                                                                  
			read_pointer <= read_pointer + 1;                                                                                        
			end                                                                    
		end                                                                        
	else if (read_pointer == num_of_words)                             
		begin                                                                      
			read_pointer <= 1;   
			tx_done <= 1'b1;                                                    
		end                                                                        
end                                                                              

assign tx_en = axis_o_tready && axis_tvalid;                                                    
// Streaming output data is read from FIFO       
always @( posedge clk )                  
begin                                            
	if(!sresetn)                            
	begin                                        
		stream_data_out <= 32'b1;                      
	end                                          
	else if (tx_en)// && M_AXIS_TSTRB[byte_index]  
	begin
		if (read_pointer == num_of_words)
		begin                                        
			stream_data_out <= 32'b1;
		end
		else
		begin
			stream_data_out <= read_pointer + 32'b1;
		end   
	end                                          
end                                             


endmodule
