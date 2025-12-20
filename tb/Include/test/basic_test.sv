`ifndef __GUARD_BASIC_TEST_SV__
`define __GUARD_BASIC_TEST_SV__ 0

`include "test/base_test.sv"
`include "sequence/random_apb_wdata_seq.sv"

class basic_test extends base_test;

  `uvm_component_utils(basic_test)
  function new(string name = "basic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  task main_phase(uvm_phase phase);
    uvm_config_db#(int)::set(uvm_root::get(), "parameter", "RANDOM_APB_WDATA_SEQ_LENGTH", 25);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Basic test started", UVM_LOW)
    begin
      random_apb_wdata_seq my_seq;
      my_seq = random_apb_wdata_seq::type_id::create("my_seq");
      my_seq.start(env.apb.seqr);
      fork
        apb_intf.wait_till_idle();
        uart_intf.wait_till_idle();
      join
    end
    `uvm_info(get_type_name(), "Basic test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask : main_phase

endclass : basic_test

`endif
