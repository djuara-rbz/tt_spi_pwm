/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module spi_own_clock 
	#(parameter ADDR_REG_LEN=3)
	(
    input  	wire 	sclk,   // SPI input clk
    input  	wire 	mosi,   // SPI input data mosi
    output 	reg 	miso,   // SPI output data miso
    input  	wire 	cs,  	// SPI input cs
    input  	wire     rst_n,  // reset_n - low to reset
	output 	reg[ADDR_REG_LEN-1:0] addr_reg,	// reg address to be accessed
	output 	reg[7:0] data_wr,	// data to be written to register
	input  	wire[7:0] data_rd_i,	// data to read from register
	output 	reg 	wr_en	// write data to register
);

  reg[1:0] spi_state;
  localparam Idle 		= 2'b00;
  localparam Get_data 	= 2'b01;
  localparam Read 		= 2'b10;
  localparam Write 		= 2'b11;
  reg[7:0] spi_data_reg;
  reg[3:0] index;
  // CDC registers
  reg[7:0] data_rd;
  reg[7:0] data_rd_z1;

 	// Register MOSI with falling edge CPOL=0 CPHA1
	always @(negedge sclk or posedge cs) begin
		if(cs == 1) begin
			spi_data_reg <= 0;
		end else begin
			spi_data_reg <= {spi_data_reg[6:0],mosi};
		end
	end

	// Rising edge of SCLK, read commands (set MISO) and write commands (store data)
	always @(posedge sclk or negedge rst_n or posedge cs) begin
		if(rst_n == 0)  begin
			spi_state 	<= Idle;
			index 		<= 0;
			addr_reg 	<= 0;
			data_rd 	<= 0;
			data_rd_z1 	<= 0;
		// Avoid Yosys synthesis bug
		end else if(cs == 1) begin
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
						addr_reg 	<= spi_data_reg[ADDR_REG_LEN-1:0];
						// Read command
						if(spi_data_reg[7] == 1) begin
							spi_state <= Get_data;
						// Write command	
						end else begin
							spi_state <= Write;
						end
					end else begin
						// Count the number of bits shifted into spi_data_reg
						index <= index + 1;
					end
				end
				Get_data: begin
					// sample data into SCLK clock domain
					data_rd_z1 	<=  data_rd_i;
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
				miso 		= data_rd[index[2:0]];
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

endmodule
