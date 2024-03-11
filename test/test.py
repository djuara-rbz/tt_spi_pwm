# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, RisingEdge
from cocotbext.spi import SpiBus, SpiConfig, SpiMaster

@cocotb.test()
async def test_adder(dut):
  dut._log.info("Start")
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 20, units="ns")
  cocotb.start_soon(clock.start())
  # Get spi port
  spi_bus = SpiBus.from_entity(dut)
  spi_config = SpiConfig(
        word_width  = 16,
        sclk_freq   = 10e6,
        cpol        = False,
        cpha        = True,
        msb_first   = True,
        )
  spi_master = SpiMaster(spi_bus, spi_config)
  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)

  # Out of reset
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 5)

  # Read SPI reg 0x56
  await RisingEdge(dut.clk)
  await cocotb.triggers.Timer(1,'ps')
  await spi_master.write([0x0000])
  read_bytes = await spi_master.read()
  print(read_bytes)

  # Set the input values, wait one clock cycle, and check the output
  await ClockCycles(dut.clk, 5)

  assert int(''.join(str(i) for i in read_bytes)) == 150
