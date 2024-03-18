/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module spi_sampled 
	#(parameter ADDR_REG_LEN=3)
	(
	input 	wire 	clk,	// System clk
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
  localparam Read 		= 2'b01;
  localparam Write 		= 2'b10;
  reg[7:0] spi_data_reg;
  reg[3:0] index;

  wire pos_edge;
  wire neg_edge;

  initial begin
	spi_state 	= Idle;
	index 		= 0;
	miso 		= 0;
  end

 	// Register MOSI with falling edge CPOL=0 CPHA1
	always @(posedge clk or posedge cs) begin
		if(cs == 1) begin
			spi_data_reg <= 0;
		end else begin
			if(neg_edge == 1) begin
				spi_data_reg <= {spi_data_reg[6:0],mosi};
			end
		end
	end

	// Rising edge of SCLK, read commands (set MISO) and write commands (store data)
	always @(posedge clk or negedge rst_n or posedge cs) begin
		if(rst_n == 0) begin
			spi_state 		<= Idle;
			index 			<= 0;
			addr_reg 		<= 0;
		// If CS is not active, disable all outputs 
		end else if(cs == 1) begin
			spi_state 		<= Idle;
			index 			<= 0;
			addr_reg 		<= 0;
		end else begin
			case(spi_state)
				// Wait for a cmd to be recevied
				Idle: begin
					// Wait for a falling edge on sclk (cpol=0, cpha=1)
					if(neg_edge == 1) begin
						// If all bits has been received
						if(index < 8) begin
							index <= index+1;
						end
					end
					if(index == 8) begin
						if(pos_edge == 1) begin
							addr_reg 	<= spi_data_reg[ADDR_REG_LEN-1:0];
							//Read command
							if(spi_data_reg[7] == 1) begin
								index <= 7;
								spi_state <= Read;
							end else begin
								index <= 1;
								spi_state <= Write;
							end
						end
					end 
				end
				Read: begin
					if(pos_edge == 1) begin
						// If byte is output, end read
						if(index == 0) begin
							spi_state <= Idle;
						end else begin
							// Decrement counter 
							index 	<= index-1;
						end
					end
				end
				Write: begin
					if(pos_edge == 1) begin
						if(index == 8) begin
						end else begin
							index <= index + 1;
						end				
					end
				end 
				default:;	
			endcase 
		end
	end 

	// Set outputs depending on state
	always @(spi_state or data_rd_i or index or spi_data_reg) begin
		case(spi_state)
			Idle: begin
				miso 		= 0;
				data_wr 	= 0;
				wr_en 		= 0;
			end
			Read: begin
				// Assign bit to miso output
				miso 		= data_rd_i[index[2:0]];
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

	edge_detector #(0) pos_edge_det(
		.clk(clk),
		.rst_n(rst_n),
		.signal(sclk),
		.edge_detected(pos_edge));

	edge_detector #(1) neg_edge_det(
		.clk(clk),
		.rst_n(rst_n),
		.signal(sclk),
		.edge_detected(neg_edge));

endmodule
