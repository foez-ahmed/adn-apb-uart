`ifndef __GUARD_UART_SEQ_ITEM_SV__
`define __GUARD_UART_SEQ_ITEM_SV__ 0


class uart_seq_item extends uvm_sequence_item;

  rand bit [7:0] data;  // 8-bit data


  `uvm_object_utils_begin(uart_seq_item)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end

  //TODO: Define sequence item fields

  function new(string name = "uart_seq_item");
    super.new(name);
  endfunction : new

endclass

`endif
