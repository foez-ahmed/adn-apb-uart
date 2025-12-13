`ifndef __GUARD_UART_MON_SV__
`define __GUARD_UART_MON_SV__ 0


`include "object/uart_rsp_item.sv"

class uart_mon extends uvm_monitor;

  `uvm_component_utils(uart_mon)

  virtual uart_if vif;
  uvm_analysis_port #(uart_rsp_item) ap;

  function new(string name = "uart_mon", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction : build_phase


  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(uvm_root::get(), "uart", "uart_intf", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("Virtual interface must be set for: %s", get_full_name()))
    end
  endfunction

  task run_phase(uvm_phase phase);
    uart_rsp_item rsp_tx;
    uart_rsp_item rsp_rx;
    fork
      forever begin
        rsp_tx = uart_rsp_item::type_id::create("rsp_tx");
        vif.recv_tx(rsp_tx.data);
        rsp_tx.direction = 1;
        ap.write(rsp_tx);
      end
      forever begin
        rsp_rx = uart_rsp_item::type_id::create("rsp_rx");
        vif.recv_rx(rsp_rx.data);
        rsp_rx.direction = 0;
        ap.write(rsp_rx);
      end
    join
    
  endtask

endclass

`endif
