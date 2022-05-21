/*
Copyright (c) 2014-2022 Luiz Carlos Gili

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// Language: Verilog 2001

`timescale 1ns / 1ps


module fifo #(
    parameter WIDTH = 4,
    parameter DEPTH = 4
)(
    input [WIDTH-1:0] data_in,
    input wire clk,
    input wire rst_n,
    input wire write,
    input wire read,
    output reg [WIDTH-1:0] data_out,
    output wire fifo_full,
    output wire fifo_empty,
    output wire fifo_not_empty,
    output wire fifo_not_full
);

    // memory will contain the FIFO data.
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    // $clog2(DEPTH+1)-2 to count from 0 to DEPTH
    reg [$clog2(DEPTH)-1:0] write_ptr;
    reg [$clog2(DEPTH)-1:0] read_ptr;
    reg [$clog2(DEPTH)-1:0] fifo_counter;

    // Initialization
    initial begin
    
        // Init both write_cnt and read_cnt to 0
        write_ptr = 0;
        read_ptr = 0;

        // Display error if WIDTH is 0 or less.
        if ( WIDTH <= 0 ) begin
            $error("%m ** Illegal condition **, you used %d WIDTH", WIDTH);
        end
        // Display error if DEPTH is 0 or less.
        if ( DEPTH <= 0) begin
            $error("%m ** Illegal condition **, you used %d DEPTH", DEPTH);
        end

    end // end initial

    assign fifo_empty   = ( write_ptr == read_ptr ) ? 1'b1 : 1'b0;
    assign fifo_full    = ( fifo_counter == (DEPTH-1) ) ? 1'b1 : 1'b0;
    assign fifo_not_empty = !fifo_empty;
    assign fifo_not_full = !fifo_full;

    always@(posedge clk) begin
        if(!rst_n) 
            fifo_counter <= 0;             
        else if((fifo_not_full && write) && (fifo_not_empty && read))
            fifo_counter <= fifo_counter;
        else if(fifo_not_full && write)   
            fifo_counter <= fifo_counter + 1;
        else if(fifo_not_empty && read)  
            fifo_counter <= fifo_counter - 1; 
        else  
            fifo_counter <= fifo_counter;     
    end

    always @ (posedge clk) begin

        if ( write && fifo_not_full) 
            memory[write_ptr] <= data_in;
        else 
            memory[write_ptr] <= memory[write_ptr];

        if ( read && fifo_not_empty) 
            data_out <= memory[read_ptr];
        else 
            data_out <= data_out;

    end

    always @ ( posedge clk ) begin
        if(!rst_n) begin
            write_ptr <= 0;
            read_ptr <= 0;
        end
        else begin 
            if ( write && fifo_not_full) 
                write_ptr <= write_ptr + 1;
            else 
                write_ptr <= write_ptr;

            if ( read && fifo_not_empty ) 
                read_ptr <= read_ptr + 1;
            else 
                read_ptr <= read_ptr;
        end 
    end

endmodule