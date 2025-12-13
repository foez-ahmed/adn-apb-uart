module uart_regif
  import apb_uart_pkg::*;
#(
    parameter int ADDR_WIDTH = 5,
    parameter int DATA_WIDTH = 32
) (
    // Global signals
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // Clock Inputs

    // Memory Interface Outputs
    input logic                      mreq_i,    // Memory request
    input logic [    ADDR_WIDTH-1:0] maddr_i,   // Memory address
    input logic                      mwe_i,     // Memory write enable
    input logic [    DATA_WIDTH-1:0] mwdata_i,  // Memory write data
    input logic [(DATA_WIDTH/8)-1:0] mstrb_i,   // Memory byte strobe

    // Memory Interface Inputs
    output logic                  mack_o,    // Memory acknowledge
    output logic [DATA_WIDTH-1:0] mrdata_o,  // Memory read data
    output logic                  mresp_o,   // Memory response (error indicator)

    // Register outputs to UART core
    output ctrl_reg_t          ctrl_reg_o,
    output clk_div_reg_t       clk_div_reg_o,
    output cfg_reg_t           cfg_reg_o,
    input  tx_fifo_count_reg_t tx_fifo_count_reg_i,
    input  rx_fifo_count_reg_t rx_fifo_count_reg_i,

    // TX data interface
    output tx_data_reg_t tx_data_reg_o,
    output logic         tx_data_valid_o,
    input  logic         tx_data_ready_i,

    // RX data interface
    input  rx_data_reg_t rx_data_reg_i,
    input  logic         rx_data_valid_i,
    output logic         rx_data_ready_o,

    // Interrupt control register output
    output intr_ctrl_reg_t intr_ctrl_reg_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Signals
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic read_err;  // Flag indicating read error (invalid address or condition)
  logic write_err;  // Flag indicating write error (invalid address or condition)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Read Logic
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational logic to handle register reads based on address
  always_comb begin
    read_err = '1;  // Default to error
    mrdata_o = '0;  // Default read data
    rx_data_ready_o = '0;  // Default RX ready low

    if (mreq_i && ~mwe_i) begin
      case (maddr_i)
        REG_CTRL_ADDR: begin
          read_err = '0;  // Valid read
          mrdata_o = ctrl_reg_o;
        end

        REG_CLK_DIV_ADDR: begin
          read_err = '0;
          mrdata_o = clk_div_reg_o;
        end

        REG_CFG_ADDR: begin
          read_err = '0;
          mrdata_o = cfg_reg_o;
        end

        REG_TX_FIFO_COUNT_ADDR: begin
          read_err = '0;
          mrdata_o = tx_fifo_count_reg_i;
        end

        REG_RX_FIFO_COUNT_ADDR: begin
          read_err = '0;
          mrdata_o = rx_fifo_count_reg_i;
        end

        REG_RX_DATA_ADDR: begin
          if (rx_data_valid_i) begin
            read_err = '0;  // Valid only if data available
            mrdata_o = rx_data_reg_i;
            rx_data_ready_o = '1;  // Acknowledge read
          end
        end

        REG_INTR_CTRL_ADDR: begin
          read_err = '0;
          mrdata_o = intr_ctrl_reg_o;
        end

        default: begin
          // Invalid address, keep defaults
        end
      endcase
    end
  end

  assign mack_o  = mreq_i;
  assign mresp_o = mreq_i ? (mwe_i ? write_err : read_err) : '0;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Write Logic
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Combinational logic to handle register writes based on address and conditions
  always_comb begin
    write_err = '1;  // Default to error
    tx_data_valid_o = '0;  // Default TX valid low
    tx_data_reg_o = mwdata_i;  // Pass write data to TX register

    if (mreq_i && mwe_i) begin
      case (maddr_i)
        REG_CTRL_ADDR: begin
          write_err = '0;  // Always writable
        end

        REG_CLK_DIV_ADDR: begin
          if (tx_fifo_count_reg_i == '0 && rx_fifo_count_reg_i == '0)
            write_err = '0;  // Only when FIFOs empty
        end

        REG_CFG_ADDR: begin
          if (tx_fifo_count_reg_i == '0 && rx_fifo_count_reg_i == '0)
            write_err = '0;  // Only when FIFOs empty
        end

        REG_TX_DATA_ADDR: begin
          if (tx_data_ready_i) begin
            write_err = '0;  // Valid if TX ready
            tx_data_valid_o = '1;  // Signal valid data
          end
        end

        REG_INTR_CTRL_ADDR: begin
          write_err = '0;  // Always writable
        end

        default: begin
          // Invalid address, keep defaults
        end

      endcase
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      ctrl_reg_o <= '0;
      clk_div_reg_o <= 'h28B0;
      cfg_reg_o <= '0;
      intr_ctrl_reg_o <= '0;

    end else if (~write_err && mwe_i) begin

      case (maddr_i)
        REG_CTRL_ADDR: begin
          ctrl_reg_o <= mwdata_i;
        end

        REG_CLK_DIV_ADDR: begin
          clk_div_reg_o <= mwdata_i;
        end

        REG_CFG_ADDR: begin
          cfg_reg_o <= mwdata_i;
        end

        REG_INTR_CTRL_ADDR: begin
          intr_ctrl_reg_o <= mwdata_i;
        end

        default: begin
        end

      endcase

    end
  end

endmodule
