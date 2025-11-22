module uart_tx (
  input  logic       arst_ni,
  input  logic       clk_i,

  input  logic [7:0] data_i,
  input  logic       data_valid_i,
  output logic       data_ready_o,

  input  logic       parity_en_i,
  input  logic       parity_type_i,
  input  logic       extra_stop_i,

  output logic       tx_o
);





endmodule