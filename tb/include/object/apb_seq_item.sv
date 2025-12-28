`ifndef __GUARD_APB_SEQ_ITEM_SV__
`define __GUARD_APB_SEQ_ITEM_SV__ 0


class apb_seq_item extends uvm_sequence_item;

  rand bit tx_type; // 0: Read, 1: Write
  rand bit [31:0] addr; // 32-bit address
  rand bit [31:0] data; // 32-bit write data

  `uvm_object_utils_begin(apb_seq_item)
    `uvm_field_int(tx_type, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction : new

endclass

`endif
