/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_spi_pwm_djuara(
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
  wire 	start_pwm_ext;		
  wire 	spare_in;		

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  		= {5'b0, pwm, miso_sampled, miso_clk};  // uo_out[0] is the miso_reg line

  assign sclk_clk 			= ui_in[0];  // uo_in[0] is the spi clk
  assign mosi_clk 			= ui_in[1];  // uo_in[1] is the spi mosi
  assign cs_clk 			= ui_in[2];  // uo_in[2] is the spi cs
  assign sclk_sampled		= ui_in[3];  // uo_in[0] is the spi clk
  assign mosi_sampled		= ui_in[4];  // uo_in[1] is the spi mosi
  assign cs_sampled			= ui_in[5];  // uo_in[2] is the spi cs
  assign start_pwm_ext		= ui_in[6];	 // uo_in[6] is the external start of pwm
  assign spare_in			= ui_in[7] & ena;	 // ui_in[7] & ena is a spare input bit
	
  localparam ADDR_REG_LEN = 3;
  localparam ADDR_ID 			= 0;
  localparam ADDR_PWM_CTRL 		= 1;
  localparam ADDR_CYCLES_HIGH0 	= 2;
  localparam ADDR_CYCLES_HIGH1 	= 3;
  localparam ADDR_CYCLES_FREQ0 	= 4;
  localparam ADDR_CYCLES_FREQ1 	= 5;
  localparam ADDR_IODIR 		= 6;
  localparam ADDR_IOVALUE 		= 7;

  // Address from SPI bus
  wire[2:0] addr_reg_clk;
  wire[2:0] addr_reg_sampled;
  // CDC registers
  reg[7:0] data_rd_clk;
  reg[7:0] data_rd_sampled;
  wire[7:0] data_wr_clk;
  wire[7:0] data_wr_sampled;
  reg[7:0] data_wr_z1;
  // Write to dev registers
  wire 		wr_en_clk;
  wire 		wr_en_sampled;
  // Device registers
  reg [7:0] 	dev_regs [(2**ADDR_REG_LEN)-1:0];
  wire 			start_pwm;		
  wire[15:0]	cycles_high; 		
  wire[15:0]	cycles_freq;		
  wire 		pwm;		

	// SPI driven with its own clock
	spi_own_clock #(ADDR_REG_LEN) spi_own_clock_ins (
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
	spi_sampled #(ADDR_REG_LEN) spi_sampled_ins (
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
	pwm_generator  pwm_inst (
		clk,			// System CLK
	 	rst_n,			// Reset
	 	start_pwm,		// Start PWM generation
	 	cycles_high,	// Cycles of CLK that PWM is high
	 	cycles_freq,	// Cycles of CLK of PWM freq
		pwm				// PWM output
	);

	// Assign value of the register accessed
	always @* begin
		if(addr_reg_clk == ADDR_IOVALUE) begin
			data_rd_clk 		= uio_in;
		end else begin
			data_rd_clk 		= dev_regs[addr_reg_clk];
		end 
		if(addr_reg_sampled == ADDR_IOVALUE) begin
			data_rd_sampled 		= uio_in;
		end else begin
			data_rd_sampled 		= dev_regs[addr_reg_sampled];
		end 
	end
	// Assign io signals from registers
	assign uio_out 			= dev_regs[ADDR_IOVALUE];
	assign uio_oe 			= dev_regs[ADDR_IODIR];
	// Assign parameters for PWM from registers
	assign start_pwm		= dev_regs[ADDR_PWM_CTRL][0] || start_pwm_ext;
	assign cycles_high 		= {dev_regs[ADDR_CYCLES_HIGH1],dev_regs[ADDR_CYCLES_HIGH0]};
	assign cycles_freq 		= {dev_regs[ADDR_CYCLES_FREQ1],dev_regs[ADDR_CYCLES_FREQ0]};

	// Update the registers
	always @(posedge clk, negedge rst_n) begin
		if(rst_n == 0) begin
			// Dev Registers assignment
			dev_regs[ADDR_ID] 			<= 8'h96;	// ID Register
			dev_regs[ADDR_PWM_CTRL]		<= 8'h00;	// Ctrl Register
			dev_regs[ADDR_CYCLES_HIGH0] <= 8'h14;	// Cycles_high LSB
			dev_regs[ADDR_CYCLES_HIGH1] <= 8'h82;	// Cycles_high
			dev_regs[ADDR_CYCLES_FREQ0] <= 8'h50;	// Cycles_freq LSB
			dev_regs[ADDR_CYCLES_FREQ1] <= 8'hC3;	// Cycles_freq
			dev_regs[ADDR_IODIR] 		<= 8'h00;	// IO Output Enable (0-input)
			dev_regs[ADDR_IOVALUE] 		<= 8'h00;	// IO Output Value
		end else begin
			// Check if register must be update (only if reg accessed is writable)
			dev_regs[ADDR_PWM_CTRL]		<= {spare_in,dev_regs[ADDR_PWM_CTRL][6:0]};	// Ctrl Register
			if(wr_en_clk == 1 && addr_reg_clk != 0) begin
				// If PWM is active, only allow access to ctrl reg
				if(start_pwm == 0 || addr_reg_clk == ADDR_PWM_CTRL || addr_reg_clk > ADDR_CYCLES_FREQ1) begin
					data_wr_z1 			<= data_wr_clk;
					dev_regs[addr_reg_clk] 	<= data_wr_z1;
				end
			// Check if register must be update (only if reg accessed is writable)
			end else if(wr_en_sampled == 1 && addr_reg_sampled != 0) begin
				// If PWM is active, only allow access to ctrl reg
				if(start_pwm == 0 || addr_reg_sampled == ADDR_PWM_CTRL || addr_reg_sampled > ADDR_CYCLES_FREQ1) begin
					dev_regs[addr_reg_sampled] 	<= data_wr_sampled;
				end
			end
		end
	end

endmodule
