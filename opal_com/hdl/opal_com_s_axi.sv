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

// Addresses used : 
// base address + 0x00 : EnableSampleGeneration 	
// base address + 0x04 : PacketSize			
// base address + 0x08 : PacketRate		
// base address + 0x0c : DataAdc3Adc4 
// base address + 0x10 : DataAdc5Adc6 
// base address + 0x14 : DataAdc7Adc8
// base address + 0x18 : DataAdc9Adc10 
// base address + 0x1c : DataAdc11Adc12
// base address + 0x20 : DataAdc13Adc14
// base address + 0x24 : DataAdc15Adc16
// base address + 0x28 :DataAdc15Adc16
// base address + 0x2c :TriggerOffset

`timescale 1 ns / 1 ps
`include "axis.vh"
module opal_com_s_axi #
(
	// Users to add parameters here

	// User parameters ends
	// Do not modify the parameters beyond this line

	// Width of s_axi data bus
	parameter AXI_BYTES = 4,
	// Width of s_axi address bus
	parameter integer C_S_AXI_ADDR_WIDTH	= 6
)
(
	// Users to add ports here
	/*
     * Config from ARM
     */

	input wire [(AXI_BYTES*8)-1:0] from_var1,
	input wire  [(AXI_BYTES*8)-1:0] from_var2,
	input wire  [(AXI_BYTES*8)-1:0] from_var3,
	input wire  [(AXI_BYTES*8)-1:0] from_var4,
	input wire  [(AXI_BYTES*8)-1:0] from_var5,
	input wire  [(AXI_BYTES*8)-1:0] from_var6,
	input wire  [(AXI_BYTES*8)-1:0] from_var7,
	input wire  [(AXI_BYTES*8)-1:0] from_var8,
	output wire  [(AXI_BYTES*8)-1:0] to_var1,
	output wire  [(AXI_BYTES*8)-1:0] to_var2,
	output wire  [(AXI_BYTES*8)-1:0] to_var3,
	output wire  [(AXI_BYTES*8)-1:0] to_var4,
	
	/*
     * Status to ARM
     */


	// User ports ends
	// Do not modify the ports beyond this line

	/*
     * AXI interface
     */
	// Global Clock Signal
	input wire  s_axi_aclk,
	// Global Reset Signal. This Signal is Active LOW
	input wire  s_axi_aresetn,

	`S_AXI_PORT(s_axi, AXI_BYTES,C_S_AXI_ADDR_WIDTH)
);
	

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [(AXI_BYTES*8)-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit (AXI_BYTES*8)
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = ((AXI_BYTES*8)/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 8
	reg [(AXI_BYTES*8)-1:0]	slv_reg0;
	reg [(AXI_BYTES*8)-1:0]	slv_reg1;
	reg [(AXI_BYTES*8)-1:0]	slv_reg2;
	reg [(AXI_BYTES*8)-1:0]	slv_reg3;
	reg [(AXI_BYTES*8)-1:0]	slv_reg4;
	reg [(AXI_BYTES*8)-1:0]	slv_reg5;
	reg [(AXI_BYTES*8)-1:0]	slv_reg6;
	reg [(AXI_BYTES*8)-1:0]	slv_reg7;
	reg [(AXI_BYTES*8)-1:0]	slv_reg8;
	reg [(AXI_BYTES*8)-1:0]	slv_reg9;
	reg [(AXI_BYTES*8)-1:0]	slv_reg10;
	reg [(AXI_BYTES*8)-1:0]	slv_reg11;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [(AXI_BYTES*8)-1:0]	 reg_data_out;
	integer	 byte_index;

	// I/O Connections assignments

	assign s_axi_awready= axi_awready;
	assign s_axi_wready	= axi_wready;
	assign s_axi_bresp	= axi_bresp;
	assign s_axi_bvalid	= axi_bvalid;
	assign s_axi_arready= axi_arready;
	assign s_axi_rdata	= axi_rdata;
	assign s_axi_rresp	= axi_rresp;
	assign s_axi_rvalid = axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one s_axi_aclk clock cycle when both
	// s_axi_awvalid and s_axi_wvalid are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && s_axi_awvalid && s_axi_wvalid)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	        end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// s_axi_awvalid and s_axi_wvalid are valid. 

	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && s_axi_awvalid && s_axi_wvalid)
	        begin
	          // Write Address latching 
	          axi_awaddr <= s_axi_awaddr;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one s_axi_aclk clock cycle when both
	// s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && s_axi_awvalid && s_axi_wvalid)
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid;

	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	      slv_reg8 <= 0;
	      slv_reg9 <= 0;
	      slv_reg10 <= 0;
	      slv_reg11 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          4'h0:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h1:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h2:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h3:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h4:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                slv_reg4[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h5:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                slv_reg5[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h6:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 6
	                slv_reg6[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h7:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 7
	                slv_reg7[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h8:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 8
	                slv_reg8[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'h9:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 9
	                slv_reg9[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'hA:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 10
	                slv_reg10[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          4'hB:
	            for ( byte_index = 0; byte_index <= ((AXI_BYTES*8)/8)-1; byte_index = byte_index+1 )
	              if ( s_axi_wstrb[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 11
	                slv_reg11[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                      slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                      slv_reg8 <= slv_reg8;
	                      slv_reg9 <= slv_reg9;
	                      slv_reg10 <= slv_reg10;
	                      slv_reg11 <= slv_reg11;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && s_axi_awvalid && ~axi_bvalid && axi_wready && s_axi_wvalid)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (s_axi_bready && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one s_axi_aclk clock cycle when
	// s_axi_arvalid is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when s_axi_arvalid is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && s_axi_arvalid)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= s_axi_araddr;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one s_axi_aclk clock cycle when both 
	// s_axi_arvalid and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && s_axi_arvalid && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && s_axi_rready)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & s_axi_arvalid & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        4'h0   : reg_data_out <= from_var1;
	        4'h1   : reg_data_out <= from_var2;
	        4'h2   : reg_data_out <= from_var3;
	        4'h3   : reg_data_out <= from_var4;
	        4'h4   : reg_data_out <= from_var5; 	
	        4'h5   : reg_data_out <= from_var6; 	
	        4'h6   : reg_data_out <= from_var7; 	
	        4'h7   : reg_data_out <= from_var8; 	
	        4'h8   : reg_data_out <= slv_reg8; 
	        4'h9   : reg_data_out <= slv_reg9;
	        4'hA   : reg_data_out <= slv_reg10;
	        4'hB   : reg_data_out <= slv_reg11;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge s_axi_aclk )
	begin
	  if ( s_axi_aresetn == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (s_axi_arvalid) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
	assign to_var1 = slv_reg8;
	assign to_var2 = slv_reg9;
	assign to_var3 = slv_reg10;
	assign to_var4 = slv_reg11;

	
	
	// User logic ends

	endmodule
