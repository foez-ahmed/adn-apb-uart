module uart_top
  import apb_uart_pkg::*;
#(
    parameter int ADDR_WIDTH = 5,
    parameter int DATA_WIDTH = 32
) (
    input logic arst_ni,
    input logic clk_i,

    input logic psel_i,
    input logic penable_i,
    input logic [ADDR_WIDTH-1:0] paddr_i,
    input logic pwrite_i,
    input logic [DATA_WIDTH-1:0] pwdata_i,

    output logic pready_o,
    output logic [DATA_WIDTH-1:0] prdata_o,
    output logic pslverr_o,

    input  logic rx_i,
    output logic tx_o,

    output logic irq_tx_almost_full,
    output logic irq_rx_almost_full,
    output logic irq_rx_parity_error,
    output logic irq_rx_valid

);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Signals
  //////////////////////////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////
  // APB-MEMIF
  ////////////////////////////////////////////////

  logic                                    mreq;
  logic               [    ADDR_WIDTH-1:0] maddr;
  logic                                    mwe;
  logic               [    DATA_WIDTH-1:0] mwdata;
  logic               [(DATA_WIDTH/8)-1:0] mstrb;
  logic                                    mack;
  logic               [    DATA_WIDTH-1:0] mrdata;
  logic                                    mresp;

  ////////////////////////////////////////////////
  // MEMIF-REGIF
  ////////////////////////////////////////////////

  ctrl_reg_t                               ctrl_reg;
  clk_div_reg_t                            clk_div_reg;
  cfg_reg_t                                cfg_reg;

  ////////////////////////////////////////////////
  // REGIF-FIFO
  ////////////////////////////////////////////////

  tx_fifo_count_reg_t                      tx_fifo_count_reg;
  rx_fifo_count_reg_t                      rx_fifo_count_reg;

  tx_data_reg_t                            regif_tx_data_reg;
  logic                                    regif_tx_data_valid;
  logic                                    regif_tx_data_ready;

  rx_data_reg_t                            regif_rx_data_reg;
  logic                                    regif_rx_data_valid;
  logic                                    regif_rx_data_ready;

  ////////////////////////////////////////////////
  // FIFO-TX/RX
  ////////////////////////////////////////////////

  tx_data_reg_t                            uart_tx_data_reg;
  logic                                    uart_tx_data_valid;
  logic                                    uart_tx_data_ready;

  rx_data_reg_t                            uart_rx_data_reg;
  logic                                    uart_rx_data_valid;
  logic                                    uart_rx_data_ready;

  ////////////////////////////////////////////////
  // MISCELLANEOUS
  ////////////////////////////////////////////////

  intr_ctrl_reg_t                          intr_ctrl_reg;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Submodule Instantiations
  //////////////////////////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////
  // APB Memory Interface
  ////////////////////////////////////////////////

  apb_memif#(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) (
      .arst_ni(arst_ni),
      .clk_i(clk_i),
      .psel_i(psel_i),
      .penable_i(penable_i),
      .paddr_i(paddr_i),
      .pwrite_i(pwrite_i),
      .pwdata_i(pwdata_i),
      .pstrb_i(pstrb_i),
      .pready_o(pready_o),
      .prdata_o(prdata_o),
      .pslverr_o(pslverr_o),
      .mreq_o(mreq),
      .maddr_o(maddr),
      .mwe_o(mwe),
      .mwdata_o(mwdata),
      .mstrb_o(mstrb),
      .mack_i(mack),
      .mrdata_i(mrdata),
      .mresp_i(mresp)
  );

  ////////////////////////////////////////////////
  // UART Register Interface
  ////////////////////////////////////////////////

  uart_regif #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) u_uart_regif (
      .arst_ni(arst_ni),
      .clk_i(clk_i),
      .mreq_i(mreq_i),
      .maddr_i(maddr),
      .mwe_i(mwe),
      .mwdata_i(mwdata),
      .mstrb_i(mstrb),
      .mack_o(mack),
      .mrdata_o(mrdata),
      .mresp_o(mresp),
      .ctrl_reg_o(ctrl_reg),
      .clk_div_reg_o(clk_div_reg),
      .cfg_reg_o(cfg_reg),
      .tx_fifo_count_reg_i(tx_fifo_count_reg),
      .rx_fifo_count_reg_i(rx_fifo_count_reg),
      .tx_data_reg_o(regif_tx_data_reg),
      .tx_data_valid_o(regif_tx_data_valid),
      .tx_data_ready_i(regif_tx_data_ready),
      .rx_data_reg_i(regif_rx_data_reg),
      .rx_data_valid_i(regif_rx_data_valid),
      .rx_data_ready_o(regif_rx_data_ready),
      .intr_ctrl_reg_o(intr_ctrl_reg)
  );

  ////////////////////////////////////////////////
  // TX FIFO
  ////////////////////////////////////////////////
  
  // TODO LABIB

  ////////////////////////////////////////////////
  // RX FIFO
  ////////////////////////////////////////////////

  // TODO FARHAN

  ////////////////////////////////////////////////
  // CLK DIV n
  ////////////////////////////////////////////////
  
  // TODO LABIB

  ////////////////////////////////////////////////
  // CLK DIV 8
  ////////////////////////////////////////////////

  // TODO FARHAN

  ////////////////////////////////////////////////
  // UART TX
  ////////////////////////////////////////////////
  
  // TODO LABIB

  ////////////////////////////////////////////////
  // UART RX
  ////////////////////////////////////////////////

  // TODO FARHAN

endmodule
