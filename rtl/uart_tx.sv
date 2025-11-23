module uart_tx
  import uart_tx_pkg::*;
(
    input logic arst_ni,
    input logic clk_i,

    input  logic [7:0] data_i,
    input  logic       data_valid_i,
    output logic       data_ready_o,

    input logic parity_en_i,
    // input logic     parity_type_i,   // REMOVE if not needed
    input logic extra_stop_i,

    output logic tx_o
);

  // -----------------------------
  // FSM
  // -----------------------------
  uart_tx_state_e mux_sel;

  uart_tx_fsm u_fsm (
      .arst_ni(arst_ni),
      .clk_i  (clk_i),

      .data_valid_i(data_valid_i),
      .data_ready_o(data_ready_o),

      .parity_en_i (parity_en_i),
      .extra_stop_i(extra_stop_i),

      .mux_sel_o(mux_sel)
  );

  // --------------------------------
  // Bit Bank (from diagram)
  // --------------------------------
  logic start_bit;
  logic stop_bit;
  logic extra_stop_bit;
  logic parity_bit;

  logic [7:0] data_reg;

  // Load the data and compute parity once
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_reg   <= 8'h00;
      parity_bit <= 1'b0;
    end else begin
      if (mux_sel == IDLE && data_valid_i) begin
        data_reg   <= data_i;

        // Even parity by default
        parity_bit <= ^data_i;  // You can remove parity_type if not needed
      end
    end
  end

  assign start_bit      = 1'b0;
  assign stop_bit       = 1'b1;
  assign extra_stop_bit = 1'b1;

  // -----------------------------
  // MUX Controlled by FSM
  // -----------------------------
  always_comb begin
    unique case (mux_sel)
      START_BIT: tx_o = start_bit;

      DATA_0: tx_o = data_reg[0];
      DATA_1: tx_o = data_reg[1];
      DATA_2: tx_o = data_reg[2];
      DATA_3: tx_o = data_reg[3];
      DATA_4: tx_o = data_reg[4];
      DATA_5: tx_o = data_reg[5];
      DATA_6: tx_o = data_reg[6];
      DATA_7: tx_o = data_reg[7];

      PARITY_BIT: tx_o = parity_en_i ? parity_bit : 1'b1;

      STOP_BIT:   tx_o = stop_bit;
      EXTRA_STOP: tx_o = extra_stop_bit;

      default: tx_o = 1'b1;  // idle
    endcase
  end

endmodule
