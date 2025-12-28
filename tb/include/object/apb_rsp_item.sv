`ifndef __GUARD_APB_RSP_ITEM_SV__
`define __GUARD_APB_RSP_ITEM_SV__ 0

`include "object/apb_seq_item.sv"

class apb_rsp_item extends apb_seq_item;

  `uvm_object_utils(apb_rsp_item)

  //TODO: Define sequence item fields

  function new(string name = "apb_rsp_item");
    super.new(name);
  endfunction : new

endclass

`endif
