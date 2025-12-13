`ifndef __GUARD_UART_SEQR_SV__
`define __GUARD_UART_SEQR_SV__ 0


`include "object/uart_seq_item.sv"


class uart_seqr extends uvm_sequencer #(uart_seq_item);

  `uvm_component_utils(uart_seqr)

  function new(string name = "uart_seqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass

`endif
