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
  logic               [               7:0] uart_tx_data;

  rx_data_reg_t                            uart_rx_data_reg;
  logic                                    uart_rx_data_valid;
  logic                                    uart_rx_data_ready;

  ////////////////////////////////////////////////
  // MISCELLANEOUS
  ////////////////////////////////////////////////

  intr_ctrl_reg_t                          intr_ctrl_reg;

  logic                                    divided_clk_n;
  logic                                    divided_clk_8n;

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

  cdc_fifo #(
      .ELEM_WIDTH(8),
      .FIFO_SIZE (8)
  ) u_tx_fifo (
      .elem_in_i(regif_tx_data_reg.TX_DATA),
      .elem_in_clk_i(clk_i),
      .elem_in_valid_i(regif_tx_data_valid),
      .elem_in_ready_o(regif_tx_data_ready),
      .elem_in_count_o(tx_fifo_count_reg),
      .elem_out_o(uart_tx_data),
      .elem_out_clk_i(divided_clk_8n),
      .elem_out_valid_o(uart_tx_data_valid),
      .elem_out_ready_i(uart_tx_data_ready),
      .elem_out_count_o()
  );

  ////////////////////////////////////////////////
  // RX FIFO
  ////////////////////////////////////////////////

  cdc_fifo #(
      .ELEM_WIDTH(8),
      .FIFO_SIZE (2)
  ) u_rx_fifo (
      .arst_ni(arst_ni),
      .elem_in_i(uart_rx_data_reg),
      .elem_in_clk_i(divided_clk_n),
      .elem_in_valid_i(uart_rx_data_valid),
      .elem_in_ready_o(uart_rx_data_ready),
      .elem_in_count_o(),
      .elem_out_o(regif_tx_data_reg),
      .elem_out_clk_i(clk_i),
      .elem_out_valid_o(uart_rx_data_valid),
      .elem_out_ready_i(regif_rx_data_ready),
      .elem_out_count_o(rx_fifo_count_reg)
  );


  ////////////////////////////////////////////////
  // CLK DIV n
  ////////////////////////////////////////////////

  clk_div #(
      .DIV_WIDTH(32)
  ) u_clk_div (

      .arst_ni(arst_ni),
      .clk_i  (clk_i),
      .div_i  (clk_div_reg),
      .clk_o  (divided_clk_n)
  );

  ////////////////////////////////////////////////
  // CLK DIV 8
  ////////////////////////////////////////////////

  clk_div #(
      .DIV_WIDTH(4)
  ) u_clk_div_8n (
      .arst_ni(arst_ni),
      .clk_i  (divided_clk_n),
      .div_i  (8),
      .clk_o  (divided_clk_8n)
  );


  ////////////////////////////////////////////////
  // UART TX
  ////////////////////////////////////////////////
  uart_tx u_tx (
      .arst_ni(arst_ni),
      .clk_i  (divided_clk_8n),

      .data_i(tx_data_reg_o),
      .data_valid_i(tx_data_valid_o),
      .data_ready_o(tx_data_ready_i),

      .parity_en_i (cfg_reg.PARITY_EN),
      .extra_stop_i(cfg_reg.EXTRA_STOP_BITS),

      .tx_o(tx_o)
  );

  ////////////////////////////////////////////////
  // UART RX
  ////////////////////////////////////////////////

  uart_rx u_rx (
      .arst_ni(arst_ni),
      .clk_i  (clk_i),

      .rx_i(rx_i),

      .parity_en_i  (cfg_reg.PARITY_EN),
      .parity_type_i(cfg_reg.PARITY_TYPE),

      .data_o(uart_rx_data_reg),
      .data_valid_o(uart_rx_data_valid)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Interrupt Signals
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign irq_tx_almost_full  = intr_ctrl_reg.TX_ALMOST_FULL ? tx_fifo_count_reg_i > 200 : '0;
  assign irq_rx_almost_full  = intr_ctrl_reg.RX_ALMOST_FULL ? rx_fifo_count_reg_i > 200 : '0;
  assign irq_rx_parity_error = intr_ctrl_reg.RX_PARITY_ERROR ? '0 : '0; // TODO LATER
  assign irq_rx_valid        = intr_ctrl_reg.RX_VALID ? regif_rx_data_valid : '0;

endmodule
