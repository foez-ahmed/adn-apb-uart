module uart_tx_fsm
  import uart_tx_pkg::*;
(
    input logic arst_ni,
    input logic clk_i,

    input  logic data_valid_i,
    output logic data_ready_o,

    input logic parity_en_i,
    input logic extra_stop_i,

    output uart_tx_state_e mux_sel_o
);

  uart_tx_state_e mux_sel_next;

  always_comb begin : blockName
    mux_sel_next = mux_sel_o;
    case (mux_sel_o)
      IDLE: begin
        if (data_valid_i) begin
          mux_sel_next = START_BIT;
        end
      end

      START_BIT: begin
        mux_sel_next = DATA_0;
      end

      DATA_0: begin
        mux_sel_next = DATA_1;
      end

      DATA_1: begin
        mux_sel_next = DATA_2;
      end

      DATA_2: begin
        mux_sel_next = DATA_3;
      end

      DATA_3: begin
        mux_sel_next = DATA_4;
      end

      DATA_4: begin
        mux_sel_next = DATA_5;
      end

      DATA_5: begin
        mux_sel_next = DATA_6;
      end

      DATA_6: begin
        mux_sel_next = DATA_7;
      end

      DATA_7: begin
        if (parity_en_i) begin
          mux_sel_next = PARITY_BIT;
        end else begin
          mux_sel_next = STOP_BIT;
        end
      end

      PARITY_BIT: begin
        mux_sel_next = STOP_BIT;
      end

      STOP_BIT: begin
        if (extra_stop_i) begin
          mux_sel_next = EXTRA_STOP;
        end else begin
          mux_sel_next = IDLE;
        end
      end

      EXTRA_STOP: begin
        mux_sel_next = IDLE;
      end

      default: begin
        mux_sel_next = IDLE;
      end
    endcase
  end

  always_comb begin
    data_ready_o = (mux_sel_o == STOP_BIT);
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      mux_sel_o <= 4'd0;
    end else begin
      mux_sel_o <= mux_sel_next;
    end
  end

endmodule
