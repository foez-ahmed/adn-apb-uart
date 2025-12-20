import uvm_pkg::*;

`include "uvm_macros.svh"
`include "test/base_test.sv"
`include "test/basic_test.sv"

module apb_uart_tb;

  parameter int ADDR_WIDTH = 32;
  parameter int DATA_WIDTH = 32;

  ctrl_if ctrl_intf ();
  uart_if uart_intf ();
  apb_if apb_intf (
      .arst_ni(ctrl_intf.arst_ni),
      .clk_i  (ctrl_intf.clk_i)
  );

  logic irq_tx_almost_full;
  logic irq_rx_almost_full;
  logic irq_rx_parity_error;
  logic irq_rx_valid;

  import apb_uart_pkg::*;
  uart_top #(
      .ADDR_WIDTH(SYS_ADDR_WIDTH),
      .DATA_WIDTH(SYS_DATA_WIDTH)
  ) udut (
      .arst_ni(ctrl_intf.arst_ni),
      .clk_i(ctrl_intf.clk_i),
      .psel_i(apb_intf.psel),
      .penable_i(apb_intf.penable),
      .paddr_i(apb_intf.paddr),
      .pwrite_i(apb_intf.pwrite),
      .pwdata_i(apb_intf.pwdata),
      .pstrb_i(apb_intf.pstrb),
      .pready_o(apb_intf.pready),
      .prdata_o(apb_intf.prdata),
      .pslverr_o(apb_intf.pslverr),
      .rx_i(uart_intf.tx),
      .tx_o(uart_intf.rx),
      .irq_tx_almost_full(irq_tx_almost_full),
      .irq_rx_almost_full(irq_rx_almost_full),
      .irq_rx_parity_error(irq_rx_parity_error),
      .irq_rx_valid(irq_rx_valid)

  );

  initial begin
    string test_name;
    if (!$value$plusargs("test=%s", test_name)) begin
      test_name = "base_test";
    end

    $timeformat(-6, 2, "us");

    $dumpfile("apb_uart_tb.vcd");
    $dumpvars(0, apb_uart_tb);

    uvm_config_db#(int)::set(uvm_root::get(), "parameter", "ADDR_WIDTH", ADDR_WIDTH);
    uvm_config_db#(int)::set(uvm_root::get(), "parameter", "DATA_WIDTH", DATA_WIDTH);

    uvm_config_db#(virtual ctrl_if)::set(uvm_root::get(), "ctrl", "ctrl_intf", ctrl_intf);
    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "uart", "uart_intf", uart_intf);
    uvm_config_db#(virtual apb_if)::set(uvm_root::get(), "apb", "apb_intf", apb_intf);

    run_test(test_name);
  end


endmodule
