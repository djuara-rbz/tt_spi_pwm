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

  wire 	sclk_clk;
  wire 	miso_clk;
  wire	mosi_clk;
  wire	cs_clk;
  wire 	sclk_sampled;
  wire 	miso_sampled;
  wire	mosi_sampled;
  wire	cs_sampled;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  		= {6'b0, miso_sampled, miso_clk};  // uo_out[0] is the miso_reg line
  assign uio_out 		= 0;
  assign uio_oe  		= 0;

  assign sclk_clk 			= ui_in[0];  // uo_in[0] is the spi clk
  assign mosi_clk 			= ui_in[1];  // uo_in[1] is the spi mosi
  assign cs_clk 			= ui_in[2];  // uo_in[2] is the spi cs
  assign sclk_sampled		= ui_in[3];  // uo_in[0] is the spi clk
  assign mosi_sampled		= ui_in[4];  // uo_in[1] is the spi mosi
  assign cs_sampled			= ui_in[5];  // uo_in[2] is the spi cs

  // Address from SPI bus
  wire[1:0] addr_reg_clk;
  wire[1:0] addr_reg_sampled;
  // CDC registers
  wire[7:0] data_rd_clk;
  wire[7:0] data_rd_sampled;
  wire[7:0] data_wr_clk;
  wire[7:0] data_wr_sampled;
  reg[7:0] data_wr_z1;
  // Write to dev registers
  wire 		wr_en_clk;
  wire 		wr_en_sampled;
  // Device registers
  reg[7:0] dev_regs[3:0];

	// SPI driven with its own clock
	spi_own_clock spi_own_clock_ins (
		sclk_clk,   	// SPI input clk
		mosi_clk,   	// SPI input data mosi
		miso_clk,   	// SPI output data miso
		cs_clk,  		// SPI input cs
		rst_n,  		// reset_n - low to reset
		addr_reg_clk,	// reg address to be accessed
		data_wr_clk,	// data to be written to register
		data_rd_clk,	// data to read from register
		wr_en_clk		// write data to register
	);

	// SPI driven with system clock
	spi_sampled spi_sampled_ins (
		clk,				// System clk
		sclk_sampled,   	// SPI input clk
		mosi_sampled,   	// SPI input data mosi
		miso_sampled,   	// SPI output data miso
		cs_sampled,  		// SPI input cs
		rst_n,  			// reset_n - low to reset
		addr_reg_sampled,	// reg address to be accessed
		data_wr_sampled,	// data to be written to register
		data_rd_sampled,	// data to read from register
		wr_en_sampled		// write data to register
	);
	// Assign value of the register accessed
	assign data_rd_clk = dev_regs[addr_reg_clk];
	assign data_rd_sampled = dev_regs[addr_reg_sampled];

	// Update the registers
	always @(posedge clk, negedge rst_n) begin
		if(rst_n == 0) begin
			// Dev Registers assignment
			dev_regs[0] <= 8'h96;
			dev_regs[1] <= 8'h01;
			dev_regs[2] <= 8'h02;
			dev_regs[3] <= 8'h03;		
		end else begin
			// Check if register must be update
			if(wr_en_clk == 1) begin
				data_wr_z1 			<= data_wr_clk;
				dev_regs[addr_reg_clk] 	<= data_wr_z1;
			end else if(wr_en_sampled == 1) begin
				dev_regs[addr_reg_sampled] 	<= data_wr_sampled;
			end
		end
	end

endmodule
