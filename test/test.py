# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
from cocotbext.spi import SpiBus, SpiConfig, SpiMaster

freq = 10e6

# Init SPIs
spi_config_24 = SpiConfig(
	word_width  = 24,
	sclk_freq   = freq,
	cpol        = False,
	cpha        = True,
	msb_first   = True,
	)
spi_config_16 = SpiConfig(
	word_width  = 16,
	sclk_freq   = freq,
	cpol        = False,
	cpha        = True,
	msb_first   = True,
	)

def init_ports(dut):
	dut.sampled_cs.value = 1
	dut.sampled_sclk.value = 0
	dut.sampled_mosi.value = 0
	dut.clk_cs.value = 1
	dut.clk_sclk.value = 0
	dut.clk_mosi.value = 0
	dut.spare_in.value = 0
	dut.ena.value = 1
	dut.uio_in.value = 0
	dut.pwm_start_ext.value = 0
  	# Our example module doesn't use clock and reset, but we show how to use them here anyway.
	clock = Clock(dut.clk, 20, units="ns")
	cocotb.start_soon(clock.start())

async def reset(dut):
	# Reset
	dut._log.info("Reset")
	dut.rst_n.value = 0
	await ClockCycles(dut.clk, 10)
	# Out of reset
	dut.rst_n.value = 1
	await ClockCycles(dut.clk, 5)

async def spi_read(dut, reg, spi_master):
	await RisingEdge(dut.clk)
	await cocotb.triggers.Timer(1,'ps')
	await spi_master.write([reg])
	read_bytes = await spi_master.read()

	return read_bytes

async def spi_write(dut, reg, spi_master):
	await RisingEdge(dut.clk)
	await cocotb.triggers.Timer(1,'ps')
	await spi_master.write([reg])

@cocotb.test()
async def test_spi_read_clk(dut):
	dut._log.info("Start SPI clk read test")
	# Initialize ports values
	init_ports(dut)
	#Init SPI
	spi_bus = SpiBus.from_prefix(dut,"clk")
	spi_master= SpiMaster(spi_bus, spi_config_24)
	# Reset device
	await reset(dut)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x800000, spi_master)
	# Set the input values, wait one clock cycle, and check the output
	assert int(''.join(str(i) for i in read_bytes)) == 150

@cocotb.test()
async def test_spi_write_clk(dut):
	dut._log.info("Start SPI clk write test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"clk")
	spi_master_rd = SpiMaster(spi_bus, spi_config_24)
	spi_master_wr = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	dut.spare_in.value = 1
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x012A, spi_master_wr)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x810000, spi_master_rd)
	assert int(''.join(str(i) for i in read_bytes)) == 170

@cocotb.test()
async def test_spi_write_read_only_clk(dut):
	dut._log.info("Start SPI clk write read only test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"clk")
	spi_master_rd = SpiMaster(spi_bus, spi_config_24)
	spi_master_wr = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x00AA, spi_master_wr)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x800000, spi_master_rd)
	assert int(''.join(str(i) for i in read_bytes)) == 150

@cocotb.test()
async def test_spi_reset_clk(dut):
	dut._log.info("Start SPI clk reset test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"clk")
	spi_master_rd = SpiMaster(spi_bus, spi_config_24)
	spi_master_wr = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	# Set bit of register 0x01
	dut.spare_in.value = 0
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x01AA, spi_master_wr)
	# Reset device
	await reset(dut)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x810000, spi_master_rd)
	assert int(''.join(str(i) for i in read_bytes)) == 0

@cocotb.test()
async def test_spi_reset_in_clk(dut):
	dut._log.info("Start SPI clk write while reset test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"clk")
	spi_master_rd = SpiMaster(spi_bus, spi_config_24)
	spi_master_wr = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	dut.rst_n.value = 0
	# Set bit of register 0x01
	dut.spare_in.value = 0
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x01AA, spi_master_wr)
	# Get back from reset
	dut.rst_n.value = 1
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x810000, spi_master_rd)
	assert int(''.join(str(i) for i in read_bytes)) == 0

@cocotb.test()
async def test_spi_read_out_clk(dut):
	dut._log.info("Start SPI clk read out of registers test")
	# Initialize ports values
	init_ports(dut)
	#Init SPI
	spi_bus = SpiBus.from_prefix(dut,"clk")
	spi_master= SpiMaster(spi_bus, spi_config_24)
	# Reset device
	await reset(dut)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0xA00000, spi_master)
	# Set the input values, wait one clock cycle, and check the output
	assert int(''.join(str(i) for i in read_bytes)) == 150

@cocotb.test()
async def test_spi_read_sampled(dut):
	dut._log.info("Start SPI Sampled read test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x8000, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 150

@cocotb.test()
async def test_spi_write_sampled(dut):
	dut._log.info("Start SPI Sampled write test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	dut.spare_in.value = 1
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x012A, spi_master)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x8100, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 170

@cocotb.test()
async def test_spi_write_read_only_sampled(dut):
	dut._log.info("Start SPI Sampled write read only test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x00AA, spi_master)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x8000, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 150

@cocotb.test()
async def test_spi_reset_sampled(dut):
	dut._log.info("Start SPI Sampled reset test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	# Set bit of register 0x01
	dut.spare_in.value = 0
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x01AA, spi_master)
	# Reset device
	await reset(dut)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x8100, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 0

@cocotb.test()
async def test_spi_reset_in_sampled(dut):
	dut._log.info("Start SPI sampled write while reset test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	dut.rst_n.value = 0
	# Set bit of register 0x01
	dut.spare_in.value = 0
	# Write SPI reg 0x01 data 0xAA
	await spi_write(dut, 0x01AA, spi_master)
	# Get back from reset
	dut.rst_n.value = 1
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x8100, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 0

@cocotb.test()
async def test_spi_read_out_sampled(dut):
	dut._log.info("Start SPI sampled read out of registers test")
	# Initialize ports values
	init_ports(dut)
	# Get spi port
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Reset device
	await reset(dut)
	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0xC000, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 150


async def config_pwm(dut, time_on, time_cycle):
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Write SPI time on
	data_sent = 0x0200 + (time_on & 0x00FF)
	await spi_write(dut, data_sent, spi_master)
	data_sent = 0x0300 + ((time_on & 0xFF00) >> 8)
	await spi_write(dut, data_sent, spi_master)
	# Write SPI cycle time
	data_sent = 0x0400 + (time_cycle & 0x00FF)
	await spi_write(dut, data_sent, spi_master)
	data_sent = 0x0500 + ((time_cycle & 0xFF00) >> 8)
	await spi_write(dut, data_sent, spi_master)


@cocotb.test()
async def test_pwm(dut):
	dut._log.info("Start PWM test")
  
	# Initialize ports values
	init_ports(dut)
	# Reset device
	await reset(dut)
	
	sys_freq = 50000000
	freq_pwm = 5000
	duty	 = 0.666

	time_cycle 	= (int)(sys_freq/freq_pwm)
	time_on 	= (int)(time_cycle*duty)
	
	await config_pwm(dut, time_on, time_cycle)

	dut.pwm_start_ext.value = 1
	# Delay a little bit to assert value of pwm
	await ClockCycles(dut.clk, 5)
	for i in range(10):
		assert dut.pwm.value == 1
		await ClockCycles(dut.clk, time_on+1)
		assert dut.pwm.value == 0
		await ClockCycles(dut.clk, time_cycle-time_on+1)
	dut.pwm_start_ext.value = 0
  
@cocotb.test()
async def test_pwm_reset(dut):
	dut._log.info("Start PWM reset test")
  
	# Initialize ports values
	init_ports(dut)
	# Reset device
	await reset(dut)
	
	sys_freq = 50000000
	freq_pwm = 5000
	duty	 = 0.666

	time_cycle 	= (int)(sys_freq/freq_pwm)
	time_on 	= (int)(time_cycle*duty)

	# Configure PWM
	await config_pwm(dut, time_on, time_cycle)
	# Reset device
	await reset(dut)
	# Set back the default config
	sys_freq = 50000000
	freq_pwm = 1000
	duty	 = 0.666

	time_cycle 	= (int)(sys_freq/freq_pwm)
	time_on 	= (int)(time_cycle*duty)

	dut.pwm_start_ext.value = 1
	# Delay a little bit to assert value of pwm
	await ClockCycles(dut.clk, 5)
	for i in range(10):
		assert dut.pwm.value == 1
		await ClockCycles(dut.clk, time_on+1)
		assert dut.pwm.value == 0
		await ClockCycles(dut.clk, time_cycle-time_on+1)
	dut.pwm_start_ext.value = 0
  
@cocotb.test()
async def test_pwm_reg(dut):
	dut._log.info("Start PWM reg test")
  
	# Initialize ports values
	init_ports(dut)
	# Reset device
	await reset(dut)
	# Init SPI
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	
	sys_freq = 50000000
	freq_pwm = 5000
	duty	 = 0.666

	time_cycle 	= (int)(sys_freq/freq_pwm)
	time_on 	= (int)(time_cycle*duty)
	
	await config_pwm(dut, time_on, time_cycle)
	# Start PWM by reg
	await spi_write(dut, 0x0101, spi_master)
	# Delay a little bit to assert value of pwm
	await ClockCycles(dut.clk, 5)
	for i in range(10):
		assert dut.pwm.value == 1
		await ClockCycles(dut.clk, time_on+1)
		assert dut.pwm.value == 0
		await ClockCycles(dut.clk, time_cycle-time_on+1)
	# Start PWM by reg
	await spi_write(dut, 0x0100, spi_master)

@cocotb.test()
async def test_pwm_change_on(dut):
	dut._log.info("Start PWM change while on test")
  
	# Initialize ports values
	init_ports(dut)
	# Reset device
	await reset(dut)
	# Init SPI
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	
	sys_freq = 50000000
	freq_pwm = 5000
	duty	 = 0.666

	time_cycle 	= (int)(sys_freq/freq_pwm)
	time_on 	= (int)(time_cycle*duty)
	
	# Config PWM while it is on
	dut.pwm_start_ext.value = 1
	await ClockCycles(dut.clk, 10)
	await config_pwm(dut, time_on, time_cycle)
	
	sys_freq = 50000000
	freq_pwm = 1000
	duty	 = 0.666

	time_cycle 	= (int)(sys_freq/freq_pwm)
	time_on 	= (int)(time_cycle*duty)

	# Read SPI reg 0x00
	read_bytes = await spi_read(dut, 0x8200, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == time_on & 0x00FF
	read_bytes = await spi_read(dut, 0x8300, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == ((time_on & 0xFF00)>>8)
	read_bytes = await spi_read(dut, 0x8400, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == time_cycle & 0x00FF
	read_bytes = await spi_read(dut, 0x8500, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == ((time_cycle & 0xFF00)>>8)

@cocotb.test()
async def test_io_read(dut):
	dut._log.info("Test IO inputs")
  
	# Initialize ports values
	init_ports(dut)
	# Reset device
	await reset(dut)
	# Init SPI
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Set inputs
	dut.uio_in.value = 0xAA
	await ClockCycles(dut.clk, 10)
	# Check outputs are 0 and all io are inputs
	assert dut.uio_out.value 	== 0x00
	assert dut.uio_oe.value 	== 0x00
	# Read SPI io in reg
	read_bytes = await spi_read(dut, 0x8700, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 170
	# Set inputs
	dut.uio_in.value = 0x55
	await ClockCycles(dut.clk, 10)
	# Read SPI io in reg
	read_bytes = await spi_read(dut, 0x8700, spi_master)
	assert int(''.join(str(i) for i in read_bytes)) == 85

@cocotb.test()
async def test_io_write(dut):
	dut._log.info("Test IO outputs and IO output enable")
  
	# Initialize ports values
	init_ports(dut)
	# Reset device
	await reset(dut)
	# Init SPI
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Set outputs
	await spi_write(dut, 0x07AA, spi_master)
	await spi_write(dut, 0x06AA, spi_master)
	await ClockCycles(dut.clk, 10)
	# Check output values controlled by registers
	assert dut.uio_out.value 	== 0xAA
	assert dut.uio_oe.value 	== 0xAA

@cocotb.test()
async def test_io_write_pwm_on(dut):
	dut._log.info("Test IO outputs and IO output enable when PWM is on")
  
	# Initialize ports values
	init_ports(dut)
	# Reset device
	await reset(dut)
	# Init PWM
	dut.pwm_start_ext.value = 1
	await ClockCycles(dut.clk, 10)
	assert dut.uio_out.value 	== 0x00
	assert dut.uio_oe.value 	== 0x00
	# Init SPI
	spi_bus = SpiBus.from_prefix(dut,"sampled")
	spi_master = SpiMaster(spi_bus, spi_config_16)
	# Set outputs
	await spi_write(dut, 0x07AA, spi_master)
	await spi_write(dut, 0x06AA, spi_master)
	await ClockCycles(dut.clk, 10)
	# Check output values controlled by registers
	assert dut.uio_out.value 	== 0xAA
	assert dut.uio_oe.value 	== 0xAA