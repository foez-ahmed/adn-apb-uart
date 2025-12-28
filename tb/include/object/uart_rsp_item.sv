`ifndef __GUARD_UART_RSP_ITEM_SV__
`define __GUARD_UART_RSP_ITEM_SV__ 0

`include "object/uart_seq_item.sv"

class uart_rsp_item extends uart_seq_item;

  `uvm_object_utils(uart_rsp_item)

  bit direction; // 0 for RX, 1 for TX

  function new(string name = "uart_rsp_item");
    super.new(name);
  endfunction : new

endclass

`endif
