`ifndef __GUARD_APB_AGENT_SV__
`define __GUARD_APB_AGENT_SV__ 0

`include "component/apb_seqr.sv"
`include "component/apb_dvr.sv"
`include "component/apb_mon.sv"
`include "object/apb_rsp_item.sv"

class apb_agent extends uvm_agent;

  `uvm_component_utils(apb_agent)

  apb_seqr seqr;
  apb_dvr  dvr;
  apb_mon  mon;

  uvm_analysis_port #(apb_rsp_item) analysis_port;

  function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = apb_seqr::type_id::create("seqr", this);
    dvr  = apb_dvr::type_id::create("dvr", this);
    mon  = apb_mon::type_id::create("mon", this);
    analysis_port = new("analysis_port", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    dvr.seq_item_port.connect(seqr.seq_item_export);
    mon.ap.connect(analysis_port);
  endfunction : connect_phase

endclass

`endif
