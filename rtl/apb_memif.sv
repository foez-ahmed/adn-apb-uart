// -----------------------------------------------------------------------------
// APB to memory-interface bridge
//
// This block converts the 2-phase APB handshake (PSEL/PENABLE/PREADY) into a
// simple request/ack pair (mreq/mack). Requests are issued when PSEL and
// PENABLE are asserted and remain active until the downstream logic raises
// MACK. The read data and response coming back from the memory side are
// registered before they are returned on the APB bus so they naturally align
// with the cycle where PREADY is asserted.
// -----------------------------------------------------------------------------
module apb_memif #(
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int STRB_WIDTH  = DATA_WIDTH / 8,
    parameter int MRESP_WIDTH = 1
) (
    input  logic                    arst_ni,
    input  logic                    clk_i,

    // APB slave side
    input  logic                    psel_i,
    input  logic                    penable_i,
    input  logic [ADDR_WIDTH-1:0]   paddr_i,
    input  logic                    pwrite_i,
    input  logic [DATA_WIDTH-1:0]   pwdata_i,
    input  logic [STRB_WIDTH-1:0]   pstrb_i,

    output logic                    pready_o,
    output logic [DATA_WIDTH-1:0]   prdata_o,
    output logic                    pslverr_o,

    // Memory side
    output logic                    mreq_o,
    output logic [ADDR_WIDTH-1:0]   maddr_o,
    output logic                    mwe_o,
    output logic [DATA_WIDTH-1:0]   mwdata_o,
    output logic [STRB_WIDTH-1:0]   mstrb_o,

    input  logic                    mack_i,
    input  logic [DATA_WIDTH-1:0]   mrdata_i,
    input  logic [MRESP_WIDTH-1:0]  mresp_i
);

  // Pass-through address/control signals remain in the APB clock domain.
  assign maddr_o  = paddr_i;
  assign mwe_o    = pwrite_i;
  assign mwdata_o = pwdata_i;
  assign mstrb_o  = pstrb_i;

  // ---------------------------------------------------------------------------
  // Request / ready tracking
  // ---------------------------------------------------------------------------
  logic mreq_q;
  logic pready_q;
  logic [DATA_WIDTH-1:0]  prdata_q;
  logic [MRESP_WIDTH-1:0] mresp_q;

  logic req_fire;
  logic mreq_d;
  logic pready_d;

  // Request is issued when a new enable phase starts and no other request is
  // outstanding. It stays asserted until the downstream asserts mack_i.
  assign req_fire = psel_i & penable_i & ~mreq_q;

  always_comb begin
    mreq_d = mreq_q;
    if (mack_i) begin
      mreq_d = 1'b0;
    end else if (req_fire) begin
      mreq_d = 1'b1;
    end
  end

  // APB PREADY is held low while a request is in flight and re-asserted when
  // the memory side acknowledges. This mirrors the APB wait-state behavior.
  always_comb begin
    pready_d = pready_q;
    if (req_fire) begin
      pready_d = 1'b0;
    end
    if (mack_i) begin
      pready_d = 1'b1;
    end
  end

  // Capture read data / response on the cycle the memory acknowledges.
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      mreq_q   <= 1'b0;
      pready_q <= 1'b1;
      prdata_q <= '0;
      mresp_q  <= '0;
    end else begin
      mreq_q   <= mreq_d;
      pready_q <= pready_d;
      if (mack_i) begin
        prdata_q <= mrdata_i;
        mresp_q  <= mresp_i;
      end
    end
  end

  assign mreq_o    = mreq_q;
  assign pready_o  = pready_q;
  assign prdata_o  = prdata_q;
  assign pslverr_o = mresp_q[0];  // LSB of the downstream response flags PSLVERR.

endmodule
