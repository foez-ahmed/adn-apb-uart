module uart_regif
  import apb_uart_pkg::*;
#(
    parameter int ADDR_WIDTH = 5,
    parameter int DATA_WIDTH = 32
)
(

    input logic                      arst_ni,   //global reset
    input logic                      clk_i,     //global clock
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


    output ctrl_reg_t          ctrl_reg_o,
    output clk_div_reg_t       clk_div_reg_o,
    output cfg_reg_t           cfg_reg_o,
    input  tx_fifo_count_reg_t tx_fifo_count_reg_i,
    input  rx_fifo_count_reg_t rx_fifo_count_reg_i,

    output tx_data_reg_t tx_data_reg_o,
    output logic         tx_data_valid_o,
    input  logic         tx_data_ready_i,

    input  rx_data_reg_t rx_data_reg_i,
    input  logic         rx_data_valid_i,
    output logic         rx_data_ready_o,

    output intr_ctrl_reg_t intr_ctrl_reg_o
);

  logic read_err;
  logic write_err;

  always_comb begin
    read_err = '1;
    mrdata_o = '0;
    rx_data_ready_o = '0;

    case (maddr_i)
      REG_CTRL_ADDR: begin
        read_err = '0;
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
          read_err = '0;
          mrdata_o = rx_data_reg_i;
          rx_data_ready_o = '1;
        end
      end

      REG_INTR_CTRL_ADDR: begin
        read_err = '0;
        mrdata_o = intr_ctrl_reg_o;
      end

      default: begin
      end
    endcase

  end

  always_comb begin
    write_err = '1;
    tx_data_valid_o = '0;
    tx_data_reg_o = mwdata_i;

    case (maddr_i)
      REG_CTRL_ADDR: begin
        write_err = '0;
      end

      REG_CLK_DIV_ADDR: begin
        if (tx_fifo_count_reg_i == '0 && rx_fifo_count_reg_i) write_err = '0;
      end

      REG_CFG_ADDR: begin
        if (tx_fifo_count_reg_i == '0 && rx_fifo_count_reg_i) write_err = '0;
      end

      REG_TX_DATA_ADDR: begin
        if (tx_data_ready_i) begin
          write_err = '0;
          tx_data_valid_o = '1;
        end
      end

      REG_INTR_CTRL_ADDR: begin
        write_err = '0;
      end

      default: begin
      end

    endcase
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      ctrl_reg_o <= '0;
      clk_div_reg_o <= 'h2580;
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
