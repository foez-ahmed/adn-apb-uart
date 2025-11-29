module apb_memif #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    // Global signals
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // Clock input

    // APB Slave Interface Inputs
    input logic                        psel_i,     // Peripheral select
    input logic                        penable_i,  // Peripheral enable
    input logic [      ADDR_WIDTH-1:0] paddr_i,    // Peripheral address
    input logic                        pwrite_i,   // Peripheral write enable
    input logic [      DATA_WIDTH-1:0] pwdata_i,   // Peripheral write data
    input logic [(DATA_WIDTH / 8)-1:0] pstrb_i,    // Peripheral byte strobe

    // APB Slave Interface Outputs
    output logic                  pready_o,  // Peripheral ready
    output logic [DATA_WIDTH-1:0] prdata_o,  // Peripheral read data
    output logic                  pslverr_o, // Peripheral slave error

    // Memory Interface Outputs
    output logic                      mreq_o,    // Memory request
    output logic [    ADDR_WIDTH-1:0] maddr_o,   // Memory address
    output logic                      mwe_o,     // Memory write enable
    output logic [    DATA_WIDTH-1:0] mwdata_o,  // Memory write data
    output logic [(DATA_WIDTH/8)-1:0] mstrb_o,   // Memory byte strobe

    // Memory Interface Inputs
    input logic                  mack_i,    // Memory acknowledge
    input logic [DATA_WIDTH-1:0] mrdata_i,  // Memory read data
    input logic                  mresp_i    // Memory response (error indicator)
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Signals
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic                  penable_q;  // Register to track previous penable state.
  logic                  pout_update;  // Signal to indicate when to update output signals.
  logic                  pready_q;  // Register to hold pready output
  logic [DATA_WIDTH-1:0] prdata_q;  // Register to hold prdata output
  logic                  pslverr_q;  // Register to hold pslverr output

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Combinational Logic
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign mreq_o = penable_i & psel_i & ~penable_q;

  assign maddr_o  = paddr_i;
  assign mwe_o    = pwrite_i;
  assign mwdata_o = pwdata_i;
  assign mstrb_o  = pstrb_i;

  assign pout_update = mack_i | mreq_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Sequential Logic
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      penable_q <= 1'b0;
    end else begin
      penable_q <= penable_i;
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      pready_q <= 1'b0;
    end else if (pout_update) begin
      pready_q <= mack_i;
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      prdata_q <= '0;
    end else if (pout_update) begin
      prdata_q <= mrdata_i;
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      pslverr_q <= 1'b0;
    end else if (pout_update) begin
      pslverr_q <= mresp_i;
    end
  end

  assign pready_o  = pout_update ? mack_i : pready_q;
  assign prdata_o  = pout_update ? mrdata_i : prdata_q;
  assign pslverr_o = pout_update ? mresp_i : pslverr_q;

endmodule
