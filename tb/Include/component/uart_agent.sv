`ifndef __GUARD_UART_AGENT_SV__
`define __GUARD_UART_AGENT_SV__ 0

`include "component/uart_seqr.sv"
`include "component/uart_dvr.sv"
`include "component/uart_mon.sv"
`include "object/uart_rsp_item.sv"

class uart_agent extends uvm_agent;

  `uvm_component_utils(uart_agent)

  uart_seqr seqr;
  uart_dvr  dvr;
  uart_mon  mon;

  uvm_analysis_port #(uart_rsp_item) analysis_port;

  function new(string name = "uart_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = uart_seqr::type_id::create("seqr", this);
    dvr  = uart_dvr::type_id::create("dvr", this);
    mon  = uart_mon::type_id::create("mon", this);
    analysis_port = new("analysis_port", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    dvr.seq_item_port.connect(seqr.seq_item_export);
    mon.ap.connect(analysis_port);
  endfunction : connect_phase

endclass

`endif
