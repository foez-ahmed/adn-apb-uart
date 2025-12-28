`ifndef __GUARD_UART_MON_SV__
`define __GUARD_UART_MON_SV__ 0


`include "object/uart_rsp_item.sv"

class uart_mon extends uvm_monitor;

  `uvm_component_utils(uart_mon)

  int baud_rate;
  bit parity_enable;
  bit parity_type;
  bit second_stop_bit;
  int data_bits;

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
        @(negedge vif.tx);
        set_config();
        vif.recv_tx(rsp_tx.data);
        rsp_tx.direction = 1;
        ap.write(rsp_tx);
      end
      forever begin
        rsp_rx = uart_rsp_item::type_id::create("rsp_rx");
        @(negedge vif.rx);
        set_config();
        vif.recv_rx(rsp_rx.data);
        rsp_rx.direction = 0;
        ap.write(rsp_rx);
      end
    join
  endtask

  task set_config();
    void'(uvm_config_db#(int)::get(uvm_root::get(), "uart", "baud_rate", baud_rate));
    void'(uvm_config_db#(bit)::get(uvm_root::get(), "uart", "parity_enable", parity_enable));
    void'(uvm_config_db#(bit)::get(uvm_root::get(), "uart", "parity_type", parity_type));
    void'(uvm_config_db#(bit)::get(uvm_root::get(), "uart", "second_stop_bit", second_stop_bit));
    void'(uvm_config_db#(int)::get(uvm_root::get(), "uart", "data_bits", data_bits));
  endtask

endclass

`endif
