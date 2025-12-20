`ifndef __GUARD_UART_EN_APB_SEQ_SV__
`define __GUARD_UART_EN_APB_SEQ_SV__ 0

`include "object/apb_seq_item.sv"

class uart_en_apb_seq extends uvm_sequence #(apb_seq_item);

  `uvm_object_utils(uart_en_apb_seq)

  function new(string name = "uart_en_apb_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_do_with(req, {req.tx_type == 1; req.addr == 'h00; req.data == 'b110;})  // FLUSH FIFO
    `uvm_do_with(req, {req.tx_type == 1; req.addr == 'h00; req.data == 'b000;})  // DISABLE FLUSH
    `uvm_do_with(req, {req.tx_type == 1; req.addr == 'h04; req.data == 'd16;})  // SET CLK DIVIDER
    `uvm_do_with(req, {req.tx_type == 1; req.addr == 'h00; req.data == 'b001;})  // ENABLE UART
  endtask : body

endclass

`endif
