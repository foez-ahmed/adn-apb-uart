`ifndef __GUARD_APB_UART_ENV_SV__
`define __GUARD_APB_UART_ENV_SV__ 0

`include "component/apb_uart_scbd.sv"
`include "component/apb_agent.sv"
`include "component/uart_agent.sv"


class apb_uart_env extends uvm_env;

  `uvm_component_utils(apb_uart_env)
    //TODO: Connect scoreboard analysis ports to monitors analysis exports

  apb_agent apb;
  uart_agent uart;
  apb_uart_scbd scbd;

  function new(string name = "apb_uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb  = apb_agent::type_id::create("apb", this);
    uart = uart_agent::type_id::create("uart", this);
    scbd = apb_uart_scbd::type_id::create("scbd", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase
endclass

`endif
