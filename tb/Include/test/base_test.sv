`ifndef __GUARD_BASE_TEST_SV__
`define __GUARD_BASE_TEST_SV__ 0

`include "component/apb_uart_env.sv"
`include "sequence/uart_en_apb_seq.sv"

class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  virtual ctrl_if ctrl_intf;
  virtual apb_if apb_intf;
  virtual uart_if uart_intf;
  apb_uart_env env;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_uart_env::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual ctrl_if)::get(
            uvm_root::get(), "ctrl", "ctrl_intf", ctrl_intf
        )) begin
      `uvm_fatal("NOVIF", "Virtual interface 'ctrl_intf' not found in config DB")
    end
    if (!uvm_config_db#(virtual apb_if)::get(uvm_root::get(), "apb", "apb_intf", apb_intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface 'apb_intf' not found in config DB")
    end
    if (!uvm_config_db#(virtual uart_if)::get(
            uvm_root::get(), "uart", "uart_intf", uart_intf
        )) begin
      `uvm_fatal("NOVIF", "Virtual interface 'uart_intf' not found in config DB")
    end
  endfunction

  task apply_reset(input realtime duration);
    apb_intf.reset();
    uart_intf.reset();
    ctrl_intf.apply_reset(duration);
  endtask

  task enable_clock(input realtime timeperiod);
    ctrl_intf.enable_clock(timeperiod);
  endtask

  virtual task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    phase.raise_objection(this);
    apply_reset(100ns);
    phase.drop_objection(this);
  endtask

  virtual task configure_phase(uvm_phase phase);
    super.configure_phase(phase);
    phase.raise_objection(this);
    uart_intf.BAUD_RATE = 6_250_000;
    uart_intf.PARITY_ENABLE = 0;
    uart_intf.PARITY_TYPE = 0;
    uart_intf.SECOND_STOP_BIT = 0;
    uart_intf.DATA_BITS = 8;
    enable_clock(10ns);
    begin
      uart_en_apb_seq my_seq;
      my_seq = uart_en_apb_seq::type_id::create("my_seq");
      my_seq.start(env.apb.seqr);
      apb_intf.wait_till_idle();
    end
    phase.drop_objection(this);
  endtask

  virtual task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Nothing to do in base test", UVM_LOW)
    phase.drop_objection(this);
  endtask : main_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    uvm_top.print_topology();
    phase.drop_objection(this);
  endtask


endclass : base_test

`endif
