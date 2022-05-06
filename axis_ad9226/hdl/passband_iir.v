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

/*
 * Passband IIR Filter
 */

module passband_iir #(
    parameter inout_width = 16,
    parameter inout_decimal_width = 15,
    parameter coefficient_width = 16,
    parameter coefficient_decimal_width = 15,
    parameter internal_width = 16,
    parameter internal_decimal_width = 15,
    /* coefficients */
    parameter signed b0 = 53,
    parameter signed b1 = 0,
    parameter signed b2 = -53,
    parameter signed a1 = -536870803,
    parameter signed a2 = 268435348
  )(
    input wire aclk,
    input wire resetn,

    input wire in_data_valid,
    input wire [inout_width-1:0] in_data,
    
    output reg out_data_valid,
    output wire [inout_width-1:0] out_data    
    
  );

  localparam inout_integer_width = inout_width - inout_decimal_width; /* compute integer width */
  localparam coefficient_integer_width = coefficient_width -coefficient_decimal_width; /* compute integer width */
  localparam internal_integer_width = internal_width - internal_decimal_width; /* compute integer width */

  wire signed [internal_width-1:0] input_int; /* input data internal size */
  wire signed [internal_width-1:0] b0_int; /* coefficient internal size */
  wire signed [internal_width-1:0] b1_int; /* coefficient internal size */
  wire signed [internal_width-1:0] b2_int; /* coefficient internal size */
  wire signed [internal_width-1:0] a1_int; /* coefficient internal size */
  wire signed [internal_width-1:0] a2_int; /* coefficient internal size */
  wire signed [internal_width-1:0] output_int; /* output internal size */

  reg signed [internal_width-1:0] input_pipe1; /* input data pipeline */
  reg signed [internal_width-1:0] input_pipe2; /* input data pipeline */
  reg signed [internal_width-1:0] output_pipe1; /* output data pipeline */
  reg signed [internal_width-1:0] output_pipe2; /* output data pipeline */

  reg signed [internal_width + internal_width-1:0] input_b0; /* product input */
  reg signed [internal_width + internal_width-1:0] input_b1; /* product input */
  reg signed [internal_width + internal_width-1:0] input_b2; /* product input */
  reg signed [internal_width + internal_width-1:0] output_a1; /* product output */
  reg signed [internal_width + internal_width-1:0] output_a2; /* product output */
  wire signed [internal_width + internal_width-1:0] output_2int; /* adder output */

 /* tvalid management */
  always @(posedge aclk)
    if (!resetn)
      out_data_valid <= 1'b0;
    else
      out_data_valid <= in_data_valid;

  /* resize signals to internal width */
  assign input_int = { {(internal_integer_width-inout_integer_width){in_data[inout_width-1]}},
                            in_data,
                            {(internal_decimal_width-inout_decimal_width){1'b0}} };
  assign b0_int = { {(internal_integer_width-coefficient_integer_width){b0[coefficient_width-1]}},
                            b0,
                            {(internal_decimal_width-coefficient_decimal_width){1'b0}} };
  assign b1_int = { {(internal_integer_width-coefficient_integer_width){b1[coefficient_width-1]}},
                            b1,
                            {(internal_decimal_width-coefficient_decimal_width){1'b0}} };
  assign b2_int = { {(internal_integer_width-coefficient_integer_width){b2[coefficient_width-1]}},
                            b2,
                            {(internal_decimal_width-coefficient_decimal_width){1'b0}} };
  assign a1_int = { {(internal_integer_width-coefficient_integer_width){a1[coefficient_width-1]}},
                            a1,
                            {(internal_decimal_width-coefficient_decimal_width){1'b0}} };
  assign a2_int = { {(internal_integer_width-coefficient_integer_width){a2[coefficient_width-1]}},
                            a2,
                            {(internal_decimal_width-coefficient_decimal_width){1'b0}} };

  /* pipeline registers */
  always @(posedge aclk)
    if (!resetn) begin
      input_pipe1 <= 0;
      input_pipe2 <= 0;
      output_pipe1 <= 0;
      output_pipe2 <= 0;
    end
    else
      if (in_data_valid) begin
        input_pipe1 <= input_int;
        input_pipe2 <= input_pipe1;
        output_pipe1 <= output_int;
        output_pipe2 <= output_pipe1;
      end

  /* registered multiplications */
  always @(posedge aclk)
    if (!resetn) begin
      input_b0 <= 0;
      input_b1 <= 0;
      input_b2 <= 0;
      output_a1 <= 0;
      output_a2 <= 0;
    end
    else begin
      input_b0 <= input_int * b0_int;
      input_b1 <= input_pipe1 * b1_int;
      input_b2 <= input_pipe2 * b2_int;
      output_a1 <= output_pipe1 * a1_int;
      output_a2 <= output_pipe2 * a2_int;    
    end
  
  assign output_2int = input_b0 + input_b1 + input_b2 - output_a1 - output_a2;
  assign output_int = output_2int >>> (internal_decimal_width);

  assign out_data = output_int >>> (internal_decimal_width-inout_decimal_width);

endmodule