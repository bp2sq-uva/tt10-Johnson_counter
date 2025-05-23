`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  parameter memfile = "hello_uart.hex";

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  wire spi_miso;
  wire [17:0] ram_addr;
  wire [7:0] ram_wdata;
  wire ram_we;
  wire ram_re;
  wire [7:0] ram_rdata;
  wire [7:0] rx_data;
  wire rx_valid;

  wire temp_wire;

  assign temp_wire = uo_out[3];

  // Replace tt_um_factory_test with your module name:
  tt_um_spi_serv user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  ({ui_in[7:1],spi_miso}),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  spi_slave_if
   #(.ADDRESS_WIDTH(18))
  spi_slave_if
    (//spi interface
      .spi_sck(uo_out[0]),
      .spi_cs(uo_out[1]),
      .spi_mosi(uo_out[2]),
      .spi_miso(spi_miso), 
    //ram interface  
      .sAddress(ram_addr),
      .sCSn(),
      .sOEn(ram_re),
      .sWRn(ram_we),
      .sDqDir(),
      .sDqOut(ram_wdata),
      .sDqIn(ram_rdata));

  spi_ram
   #(.memfile (memfile),
     .depth (262144))
  ram
    (// Wishbone interface
      .i_clk (clk),
      .i_addr (ram_addr),
      .i_wdata (ram_wdata),
      .i_we  (ram_we) ,
      .i_re (ram_re),
      .o_rdata (ram_rdata));

  uart_rx uart_rx_inst (
      .clk(clk),
      .reset_n(rst_n),
      .rx(uo_out[3]),
      .data(rx_data),
      .valid(rx_valid)
  );

endmodule
