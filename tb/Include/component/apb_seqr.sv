`ifndef __GUARD_APB_SEQR_SV__
`define __GUARD_APB_SEQR_SV__ 0


`include "object/apb_seq_item.sv"

class apb_seqr extends uvm_sequencer #(apb_seq_item);

  `uvm_component_utils(apb_seqr)

  function new(string name = "apb_seqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass

`endif
