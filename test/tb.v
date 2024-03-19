`default_nettype none `timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Wire for cocotb testing
  wire clk_sclk;
  wire clk_mosi;
  wire clk_miso;
  wire clk_cs;
  wire sampled_sclk;
  wire sampled_mosi;
  wire sampled_miso;
  wire sampled_cs;
  wire pwm;
  wire pwm_start_ext;
  wire spare_in;

  assign clk_miso 		= uo_out[0];
  assign sampled_miso 	= uo_out[1];
  assign pwm 			= uo_out[2];
  assign ui_in[0] 		= clk_sclk;
  assign ui_in[1] 		= clk_mosi;
  assign ui_in[2] 		= clk_cs;
  assign ui_in[3] 		= sampled_sclk;
  assign ui_in[4] 		= sampled_mosi;
  assign ui_in[5] 		= sampled_cs;
  assign ui_in[6] 		= pwm_start_ext;
  assign ui_in[7] 		= spare_in;

  // Replace tt_um_example with your module name:
  tt_um_spi_pwm_djuara user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule
