 module uart_rx
  import uart_rx_pkg::*;
(
  input  logic       arst_ni,
  input  logic       clk_i,

  input  logic       rx_i,

  input  logic       parity_en_i,
  input  logic       parity_type_i,

  output logic [7:0] data_o,
  output logic       data_valid_o
);

  // --------------------------------------------------------------------------
  // Parameters: BitTicks sets number of clk cycles per data bit.
  // HalfBitTicks used to sample mid of start bit.
  // --------------------------------------------------------------------------
  parameter int BitTicks      = 16; // clock cycles per bit
  localparam int HalfBitTicks = BitTicks/2;
  localparam int TickCntWidth = (BitTicks > 1) ? $clog2(BitTicks) : 1;

  // --------------------------------------------------------------------------
  // Signals
  // --------------------------------------------------------------------------
  uart_rx_state_e state;
  logic edge_found;
  logic [TickCntWidth-1:0] tick_cnt;
  logic rx_q;
  logic [7:0] data_shift;
  logic parity_bit_sampled;
  logic parity_ok;
  logic data_parity;

  // Parity calculation (XOR of all data bits)
  assign data_parity = ^data_shift;

  // Output assignments
  assign data_o = data_shift;

  // --------------------------------------------------------------------------
  // Synchronize / register rx for edge detection
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      rx_q <= 1'b1; // idle line high
    end else begin
      rx_q <= rx_i;
    end
  end

  // Falling edge detect for start bit (high -> low)
  wire start_edge = rx_q && !rx_i;

  // --------------------------------------------------------------------------
  // Bit timing generator producing edge_found pulses.
  // - In IDLE: wait for falling edge to start.
  // - In START_BIT: generate single pulse after HALF_BIT_TICKS.
  // - In other states: pulse every BIT_TICKS.
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      tick_cnt <= '0;
    end else begin
      if (state == IDLE) begin
        tick_cnt <= '0;
      end else begin
        if (edge_found) begin
          tick_cnt <= '0;
        end else begin
          tick_cnt <= tick_cnt + 1'b1;
        end
      end
    end
  end

  always_comb begin
    if (state == IDLE) begin
      edge_found = start_edge; // initiate on start edge
    end else begin
      edge_found = (tick_cnt == ((state == START_BIT) ? HalfBitTicks : BitTicks) - 1);
    end
  end

  // --------------------------------------------------------------------------
  // FSM instantiation
  // --------------------------------------------------------------------------
  uart_rx_fsm u_fsm (
    .arst_ni      (arst_ni),
    .clk_i        (clk_i),
    .edge_found   (edge_found),
    .parity_en_i  (parity_en_i),
    .dmux_sel_o   (state)
  );

  // --------------------------------------------------------------------------
  // Data bit capture on sampling edge
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_shift <= '0;
    end else begin
      if (edge_found) begin
        case (state)
          DATA_0: data_shift[0] <= rx_i;
          DATA_1: data_shift[1] <= rx_i;
          DATA_2: data_shift[2] <= rx_i;
          DATA_3: data_shift[3] <= rx_i;
          DATA_4: data_shift[4] <= rx_i;
          DATA_5: data_shift[5] <= rx_i;
          DATA_6: data_shift[6] <= rx_i;
          DATA_7: data_shift[7] <= rx_i;
          default: ;
        endcase
      end
    end
  end

  // --------------------------------------------------------------------------
  // Parity sampling and check
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      parity_bit_sampled <= 1'b0;
      parity_ok <= 1'b1; // treat as OK on reset
    end else begin
      if (parity_en_i && edge_found && state == PARITY_BIT) begin
        parity_bit_sampled <= rx_i;
        // parity_type_i: 0 = even, 1 = odd
        parity_ok <= parity_type_i ? (rx_i == ~data_parity) : (rx_i == data_parity);
      end
      // No else clause: do not update parity_ok when parity is disabled
    end
  end

  // --------------------------------------------------------------------------
  // Data valid generation: pulse when STOP_BIT sampled correctly.
  // Requires stop bit high and parity OK (or parity disabled).
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_valid_o <= 1'b0;
    end else begin
      if (edge_found && state == STOP_BIT) begin
        if (rx_i && (parity_en_i ? parity_ok : 1'b1)) begin
          data_valid_o <= 1'b1;
        end else begin
          data_valid_o <= 1'b0;
        end
      end else begin
        data_valid_o <= 1'b0; // one-cycle pulse
      end
    end
  end

endmodule

