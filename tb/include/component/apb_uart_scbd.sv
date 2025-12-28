`ifndef __GUARD_APB_UART_SCBD_SV__
`define __GUARD_APB_UART_SCBD_SV__ 0

`include "object/apb_rsp_item.sv"
`include "object/uart_rsp_item.sv"

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart)

class apb_uart_scbd extends uvm_scoreboard;

  `uvm_component_utils(apb_uart_scbd)

  uvm_analysis_imp_apb #(apb_rsp_item, apb_uart_scbd) m_analysis_imp_apb;
  uvm_analysis_imp_uart #(uart_rsp_item, apb_uart_scbd) m_analysis_imp_uart;

  protected apb_rsp_item apb_q[$];
  protected byte uart_tx_q[$];
  protected byte uart_rx_q[$];

  protected int pass_count = 0;
  protected int fail_count = 0;

  function new(string name = "apb_uart_scbd", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Create an instance of each analysis
    m_analysis_imp_apb  = new($sformatf("m_analysis_imp_apb"), this);
    m_analysis_imp_uart = new($sformatf("m_analysis_imp_uart"), this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

  function void write_apb(apb_rsp_item item);
    `uvm_info(get_type_name(), $sformatf("Received APB item: %s", item.sprint()), UVM_HIGH)
    apb_q.push_back(item);
  endfunction

  // Function: write_sum
  // Implementation for the `sum` analysis port. Called by the monitor.
  function void write_uart(uart_rsp_item item);
    `uvm_info(get_type_name(), $sformatf("Received UART item: %s", item.sprint()), UVM_HIGH)
    if (item.direction == 1) uart_tx_q.push_back(item.data);
    if (item.direction == 0) uart_rx_q.push_back(item.data);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      apb_rsp_item apb_item;
      wait (apb_q.size());
      apb_item = apb_q.pop_front();
      if (apb_item.tx_type == 1 && apb_item.addr == 4) begin
        uvm_config_db#(int)::set(uvm_root::get(), "uart", "baud_rate", (100000000 / apb_item.data));
      end else if (apb_item.tx_type == 1 && apb_item.addr == 8) begin
        void'(uvm_config_db#(bit)::get(uvm_root::get(), "uart", "parity_type", apb_item.data[1]));
        void'(uvm_config_db#(bit)::get(uvm_root::get(), "uart", "parity_enable", apb_item.data[0]));
        void'(uvm_config_db#(bit)::get(uvm_root::get(), "uart", "second_stop_bit", apb_item.data[2]));
      end else if (apb_item.tx_type == 1 && apb_item.addr == 'h14) begin
        byte data;
        wait (uart_tx_q.size());
        data = uart_tx_q.pop_front();
        if (data == apb_item.data[7:0]) begin
          pass_count++;
          `uvm_info(get_type_name(), $sformatf("TX Data Match: 0x%0h", data), UVM_LOW)
        end else begin
          fail_count++;
          `uvm_error(get_type_name(), $sformatf(
                     "TX Data Mismatch: Expected 0x%0h, Got 0x%0h", apb_item.data[7:0], data))
        end
      end else if (apb_item.tx_type == 0 && apb_item.addr == 'h18) begin
        byte data;
        wait (uart_rx_q.size());
        data = uart_rx_q.pop_front();
        if (data == apb_item.data[7:0]) begin
          pass_count++;
          `uvm_info(get_type_name(), $sformatf("TX Data Match: 0x%0h", data), UVM_LOW)
        end else begin
          fail_count++;
          `uvm_error(get_type_name(), $sformatf(
                     "TX Data Mismatch: Expected 0x%0h, Got 0x%0h", apb_item.data[7:0], data))
        end
      end
    end

  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("--- Scoreboard Summary ---"), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("Passed: %0d", pass_count), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("Failed: %0d", fail_count), UVM_NONE)
    `uvm_info(get_type_name(), "--------------------------", UVM_NONE)
    if (fail_count > 0) begin
      `uvm_error(get_type_name(), "Test FAILED")
    end else begin
      `uvm_info(get_type_name(), "Test PASSED", UVM_NONE)
    end
  endfunction

endclass

`endif
