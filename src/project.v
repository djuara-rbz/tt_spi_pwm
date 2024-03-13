/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_spi_test_djuara (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire 	sclk;
  reg 	miso;
  wire	mosi;
  wire	cs;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[0]  	= {7'b0, miso};  // uo_out[0] is the miso_reg line
  assign uio_out 		= 0;
  assign uio_oe  		= 0;

  assign sclk 			= ui_in[0];  // uo_in[0] is the spi clk
  assign mosi 			= ui_in[1];  // uo_in[1] is the spi mosi
  assign cs 			= ui_in[2];  // uo_in[2] is the spi cs

  reg[1:0] spi_state;
  localparam Idle 		= 2'b00;
  localparam Get_data 	= 2'b01;
  localparam Read 		= 2'b10;
  localparam Write 		= 2'b11;
  reg[7:0] spi_data_reg;
  reg[7:0] addr_reg;
  reg[3:0] index;
  // CDC registers
  reg[7:0] data_rd;
  reg[7:0] data_rd_z1;
  reg[7:0] data_wr;
  reg[7:0] data_wr_z1;
  // Write to dev registers
  reg 		wr_en;
  // Device registers
  reg[7:0] dev_regs[3:0];

 	// Register MOSI with falling edge CPOL=0 CPHA1
	always @(negedge sclk) begin
		if(cs == 0) begin
			spi_data_reg <= {spi_data_reg[6:0],mosi};
		end
	end

	// Rising edge of SCLK, read commands (set MISO) and write commands (store data)
	/*always @(posedge sclk, negedge rst_n, posedge cs) begin*/
	always @(posedge sclk or negedge rst_n) begin
		if((rst_n == 0) || (cs == 1)) begin
			spi_state 	<= Idle;
			index 		<= 0;
			addr_reg 	<= 0;
			data_rd 	<= 0;
			data_rd_z1 	<= 0;
		end else begin
			case(spi_state)
				// Wait for a cmd to be recevied
				Idle: begin
					// Check if byte has been received
					if(index == 8) begin
						index <= 1;
						// Read command
						if(spi_data_reg[7] == 1) begin
							spi_state <= Get_data;
							addr_reg 	<= 8'h7F & spi_data_reg;
						// Write command	
						end else begin
							spi_state <= Write;
							addr_reg 	<= 8'h7F & spi_data_reg;
						end
					end else begin
						// Count the number of bits shifted into spi_data_reg
						index <= index + 1;
					end
				end
				Get_data: begin
					// sample data into SCLK clock domain
					data_rd_z1 	<=  dev_regs[addr_reg];
					data_rd 	<= data_rd_z1;
					if(index == 8) begin
						spi_state 	<= Read;
						index 		<= 7;
					end else begin
						// Count the number of bits shifted into spi_data_reg
						index <= index + 1;
					end
				end
				Read: begin
					// If byte is output, end read
					if(index == 0) begin
						spi_state <= Idle;
					end else begin
						// Decrement counter 
						index 	<= index-1;
					end
				end
				Write: begin
					if(index == 8) begin
					end else begin
						index <= index + 1;
					end				
				end
				default:;	
			endcase 
		end
	end 

	// Set outputs depending on state
	always @(*) begin
		case(spi_state)
			Idle: begin
				miso 		= 0;
				data_wr 	= 0;
				wr_en 		= 0;
			end
			Read: begin
				// Assign bit to miso output
				miso 		= data_rd[index];
				data_wr 	= 0;
				wr_en 		= 0;
			end
			Write: begin
				miso 		= 0;
				// If data is rec, enable write
				if(index == 8) begin
					data_wr 	= spi_data_reg;
					wr_en 		= 1;
				end else begin
					data_wr 	= 0;
					wr_en 		= 0;
				end
			end
			default: begin
				miso 		= 0;
				data_wr 	= 0;
				wr_en 		= 0;
			end
		endcase
	end

	// Update the registers
/*	always @(posedge clk, negedge rst_n) begin
		if(rst_n == 0) begin
			// Dev Registers assignment
			dev_regs[0] <= 8'h96;
			dev_regs[1] <= 8'h01;
			dev_regs[2] <= 8'h02;
			dev_regs[3] <= 8'h03;		
		end else begin
			// Check if register must be update
			if(wr_en == 1) begin
				data_wr_z1 			<= data_wr;
				dev_regs[addr_reg] 	<= data_wr_z1;
			end 
		end
	end
*/
endmodule
