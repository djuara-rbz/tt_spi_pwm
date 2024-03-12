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

  reg[7:0] spi_data;
  reg[1:0] spi_state;
  localparam Idle = 2'b00;
  localparam Read = 2'b01;

  reg[7:0] data_out;
  reg[3:0] index;

  wire pos_edge;
  wire neg_edge;

	always @(posedge clk) begin
		if(rst_n == 0) begin
			spi_state 	<= Idle;
			spi_data 	<= 0;
			index 		<= 0;
		end else begin
			// Check if chip is selected
			if(cs == 0) begin
				case(spi_state)
					// Wait for a cmd to be recevied
					Idle: begin
						// Wait for a falling edge on sclk (cpol=0, cpha=1)
						if(neg_edge == 1) begin
							// Register new bit received
							spi_data <= {spi_data[6:0],mosi};
							// If all bits has been received
							if(index < 8) begin
								index <= index+1;
							end
						end
						if(index == 8) begin
							if(pos_edge == 1) begin
								index <= 7;
								spi_state <= Read;
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
					default:;	
				endcase 
			// If CS is not active, disable all outputs 
			end else begin
				spi_state 	<= Idle;
				spi_data 	<= 0;
				index 		<= 0;
			end
		end
	end 

	always @(*) begin
		case(spi_state)
			Idle: begin
				data_out 	<= 0;
				miso 		<= 0;
			end
			Read: begin
				// Assign response value
				if(spi_data == 8'h56) begin
					data_out 	<= 8'h96;
				end else begin
					data_out 	<= 8'hAA;
				end
				// Assign bit to miso output
				miso 	<= data_out[index];
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
