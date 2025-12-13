`ifndef __GUARD_UART_DVR_SV__
`define __GUARD_UART_DVR_SV__ 0



`include "object/uart_seq_item.sv"

class uart_dvr extends uvm_driver #(uart_seq_item);

  `uvm_component_utils(uart_dvr)

  virtual uart_if vif;

  function new(string name = "uart_dvr", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(uvm_root::get(), "uart", "uart_intf", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("Virtual interface must be set for: %s", get_full_name()))
    end
  endfunction

  task run_phase(uvm_phase phase);
    uart_seq_item req;
    forever begin
      seq_item_port.get_next_item(req);
      vif.send_tx(req.data);
      seq_item_port.item_done();
    end
  endtask

endclass

`endif
