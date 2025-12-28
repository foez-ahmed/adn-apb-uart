`ifndef __GUARD_APB_MON_SV__
`define __GUARD_APB_MON_SV__ 0

`include "object/apb_rsp_item.sv"

class apb_mon extends uvm_monitor;

  `uvm_component_utils(apb_mon)

  virtual apb_if vif;
  uvm_analysis_port #(apb_rsp_item) ap;

  function new(string name = "apb_mon", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction : build_phase


  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(uvm_root::get(), "apb", "apb_intf", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("Virtual interface must be set for: %s", get_full_name()))
    end
  endfunction

  task run_phase(uvm_phase phase);
    apb_rsp_item rsp;
    int direction;
    int address;
    int write_data;
    int write_strobe;
    int read_data;
    int slverr;

    forever begin
      vif.get_transaction(direction, address, write_data, write_strobe, read_data, slverr);
      rsp = apb_rsp_item::type_id::create("rsp");
      rsp.tx_type = direction;
      rsp.addr    = address;
      rsp.data    = (direction == 0) ? read_data : write_data;
      ap.write(rsp);
    end
  endtask

endclass

`endif
