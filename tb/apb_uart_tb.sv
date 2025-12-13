import uvm_pkg::*;

`include "uvm_macros.svh"
`include "/test/base_test.sv"

module apb_uart_tb;

  parameter int ADDR_WIDTH = 32;
  parameter int DATA_WIDTH = 32;

  ctrl_if ctrl_intf ();
  uart_if uart_intf ();
  apb_if apb_intf (
      .arst_ni(ctrl_intf.arst_ni),
      .clk_i  (ctrl_intf.clk_i)
  );

  initial begin
    string test_name;
    if (!$value$plusargs("test=%s", test_name)) begin
      test_name = "base_test";
    end

    uvm_config_db#(int)::set(uvm_root::get(), "parameter", "ADDR_WIDTH", ADDR_WIDTH);
    uvm_config_db#(int)::set(uvm_root::get(), "parameter", "DATA_WIDTH", DATA_WIDTH);

    uvm_config_db#(virtual ctrl_if)::set(uvm_root::get(), "ctrl", "ctrl_intf", ctrl_intf);
    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "uart", "uart_intf", uart_intf);
    uvm_config_db#(virtual apb_if)::set(uvm_root::get(), "apb", "apb_intf", apb_intf);

    run_test(test_name);
  end


endmodule
