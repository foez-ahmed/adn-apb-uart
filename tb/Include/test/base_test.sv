`ifndef __GUARD_BASE_TEST_SV__
`define __GUARD_BASE_TEST_SV__ 0

`include "component/apb_uart_env.sv"

class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  virtual ctrl_if ctrl_intf;
  virtual uart_if uart_intf;
  apb_uart_env env;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env  = apb_uart_env::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual ctrl_if)::get(uvm_root::get(), "ctrl", "ctrl_intf", ctrl_intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface 'ctrl_intf' not found in config DB")
    end
    if (!uvm_config_db#(virtual uart_if)::get(uvm_root::get(), "uart", "uart_intf", uart_intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface 'uart_intf' not found in config DB")
    end
  endfunction

  task apply_reset(input realtime duration);
    ctrl_intf.apply_reset(duration);
  endtask

  task enable_clock(input realtime timeperiod);
    ctrl_intf.enable_clock(timeperiod);
  endtask

  task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    phase.raise_objection(this);
    apply_reset(100ns);
    phase.drop_objection(this);
  endtask

  task configure_phase(uvm_phase phase);
    super.configure_phase(phase);
    phase.raise_objection(this);
    uart_intf.BAUD_RATE = 9600;
    uart_intf.PARITY_ENABLE = 0;
    uart_intf.PARITY_TYPE = 0;
    uart_intf.SECOND_STOP_BIT = 0;
    uart_intf.DATA_BITS = 8;
    enable_clock(20ns);
    phase.drop_objection(this);
  endtask

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    uvm_top.print_topology();
    phase.drop_objection(this);
  endtask


endclass : base_test

`endif
