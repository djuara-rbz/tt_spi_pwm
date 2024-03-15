# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, RisingEdge, Timer
from cocotbext.spi import SpiBus, SpiConfig, SpiMaster

freq = 10e6


def init_ports(dut):
	dut.sampled_cs.value = 1
	dut.sampled_sclk.value = 0
	dut.sampled_mosi.value = 0
	dut.clk_cs.value = 1
	dut.clk_sclk.value = 0
	dut.clk_mosi.value = 0
	dut.ena.value = 1
	dut.uio_in.value = 0
	dut.pwm_start_ext.value = 0


@cocotb.test()
async def test_spi_read_clk(dut):
  dut._log.info("Start SPI clk read test")
  
  # Initialize ports values
  init_ports(dut)

  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  # Get spi port
  #spi_bus = SpiBus.from_entity(dut)
  spi_bus = SpiBus.from_prefix(dut,"clk")
  spi_config = SpiConfig(
        word_width  = 24,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_rd = SpiMaster(spi_bus, spi_config)

  # Reset
  dut._log.info("Reset")
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Read SPI reg 0x00
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_rd.write([0x800000])
  read_bytes = await spi_master_rd.read()
  # Set the input values, wait one clock cycle, and check the output
  await ClockCycles(dut.clk, 5)
  assert int(''.join(str(i) for i in read_bytes)) == 150

@cocotb.test()
async def test_spi_write_clk(dut):
  dut._log.info("Start SPI clk write test")
  
  # Initialize ports values
  init_ports(dut)
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  # Get spi port
  spi_bus = SpiBus.from_prefix(dut,"clk")
  spi_config = SpiConfig(
        word_width  = 24,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_rd = SpiMaster(spi_bus, spi_config)
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_wr = SpiMaster(spi_bus, spi_config)
  # Reset
  dut._log.info("Reset")
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Write SPI reg 0x01 data 0xAA
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_wr.write([0x01AA])
  # Read SPI reg 0x00
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_rd.write([0x810000])
  read_bytes = await spi_master_rd.read()

  # Set the input values, wait one clock cycle, and check the output
  await ClockCycles(dut.clk, 5)

  assert int(''.join(str(i) for i in read_bytes)) == 170

@cocotb.test()
async def test_spi_reset_clk(dut):
  dut._log.info("Start SPI clk reset test")
  
  # Initialize ports values
  init_ports(dut)
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  # Get spi port
  spi_bus = SpiBus.from_prefix(dut,"clk")
  spi_config = SpiConfig(
        word_width  = 24,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_rd = SpiMaster(spi_bus, spi_config)
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_wr = SpiMaster(spi_bus, spi_config)
  # Reset
  dut._log.info("Reset")
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Write SPI reg 0x01 data 0xAA
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_wr.write([0x01AA])
  
  # Reset device
  await ClockCycles(dut.clk, 5)
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Read SPI reg 0x00
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_rd.write([0x810000])
  read_bytes = await spi_master_rd.read()

  # Set the input values, wait one clock cycle, and check the output
  await ClockCycles(dut.clk, 5)

  assert int(''.join(str(i) for i in read_bytes)) == 0

@cocotb.test()
async def test_spi_read_sampled(dut):
  dut._log.info("Start SPI Sampled read test")
  
  # Initialize ports values
  init_ports(dut)

  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  # Get spi port
  spi_bus = SpiBus.from_prefix(dut,"sampled")
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_rd = SpiMaster(spi_bus, spi_config)
  
  # Reset
  dut._log.info("Reset")
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Read SPI reg 0x00
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  dut._log.info("Going to read values")
  await spi_master_rd.write([0x8000])
  dut._log.info("Read values")
  read_bytes = await spi_master_rd.read()
  # Set the input values, wait one clock cycle, and check the output
  await ClockCycles(dut.clk, 5)
  assert int(''.join(str(i) for i in read_bytes)) == 150

@cocotb.test()
async def test_spi_write_sampled(dut):
  dut._log.info("Start SPI Sampled write test")
  
  # Initialize ports values
  init_ports(dut)
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  # Get spi port
  spi_bus = SpiBus.from_prefix(dut,"sampled")
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_rd = SpiMaster(spi_bus, spi_config)
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_wr = SpiMaster(spi_bus, spi_config)
  # Reset
  dut._log.info("Reset")
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Write SPI reg 0x01 data 0xAA
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_wr.write([0x01AA])
  # Read SPI reg 0x00
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_rd.write([0x8100])
  read_bytes = await spi_master_rd.read()

  # Set the input values, wait one clock cycle, and check the output
  await ClockCycles(dut.clk, 5)
  assert int(''.join(str(i) for i in read_bytes)) == 170


@cocotb.test()
async def test_spi_reset_sampled(dut):
  dut._log.info("Start SPI Sampled reset test")
  
  # Initialize ports values
  init_ports(dut)
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  # Get spi port
  spi_bus = SpiBus.from_prefix(dut,"sampled")
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_rd = SpiMaster(spi_bus, spi_config)
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = freq,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master_wr = SpiMaster(spi_bus, spi_config)
  
  # Reset
  dut._log.info("Reset")
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Write SPI reg 0x01 data 0xAA
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_wr.write([0x01AA])
  
  # Reset device
  await ClockCycles(dut.clk, 5)
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Read SPI reg 0x00
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master_rd.write([0x8100])
  read_bytes = await spi_master_rd.read()
  # Set the input values, wait one clock cycle, and check the output
  await ClockCycles(dut.clk, 5)

  assert int(''.join(str(i) for i in read_bytes)) == 0

@cocotb.test()
async def test_pwm(dut):
  dut._log.info("Start PWM test")
  
  # Initialize ports values
  init_ports(dut)
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
	
  dut.pwm_start_ext.value = 1
  await Timer(100,units='us')
  assert dut.pwm.value == 1
  await Timer(1000,units='us')
  assert dut.pwm.value == 0
  await Timer(1000,units='us')
  assert dut.pwm.value == 1
  await Timer(1000,units='us')
  assert dut.pwm.value == 0
  await Timer(1000,units='us')
  assert dut.pwm.value == 1
  await Timer(1000,units='us')
  assert dut.pwm.value == 0