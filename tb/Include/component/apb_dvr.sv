`ifndef __GUARD_APB_DVR_SV__
`define __GUARD_APB_DVR_SV__ 0


`include "object/apb_seq_item.sv"

class apb_dvr extends uvm_driver #(apb_seq_item);

  `uvm_component_utils(apb_dvr)

  virtual apb_if vif;

  function new(string name = "apb_dvr", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(uvm_root::get(), "apb", "apb_intf", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("Virtual interface must be set for: %s", get_full_name()))
    end
  endfunction

  task run_phase(uvm_phase phase);
    apb_seq_item req;
    forever begin
      seq_item_port.get_next_item(req);
      if(req.tx_type == 0) begin
        int read_data;
        vif.read(req.addr, read_data);
      end else if(req.tx_type == 1) begin
        vif.write(req.addr, req.data);
      end
      seq_item_port.item_done();
    end
  endtask

endclass

`endif
