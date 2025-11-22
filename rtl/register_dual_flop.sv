// -----------------------------------------------------------------------------
// Dual-flop register (metastability-hardened load-enabled register)
//
// This module consists of two cascaded flip-flops to provide a simple two-stage
// register for improved timing/metastability handling in crossing clock domains
// or when an additional stage of register is desired. The design captures an
// enable and data value into an intermediate register first, then optionally
// transfers the intermediate value into the final output register at a later
// clock edge.
//
// Parameters:
//  - ELEM_WIDTH: width of register data (default 32)
//  - RESET_VALUE: reset value for both flops
//  - FIRST_FF_EDGE_POSEDGED: if 1, the first flop samples on posedge; if 0 the
//    first flop effectively samples on negedge by inverting the clock signal.
//  - LAST_FF_EDGE_POSEDGED: similar to FIRST_FF_EDGE_POSEDGED for the last flop.
//
// Ports:
//  - clk_i: base clock input. The actual sampling edges of each flop can be
//    inverted using the parameters above; this allows shifting the sample phase
//    without additional clocking resources.
//  - arst_ni: asynchronous active-low reset. Resets both the intermediate and
//    final registers to RESET_VALUE.
//  - en_i: synchronous enable input; captured into `en_intermediate` by the
//    first flop so the final flop respects the sampled-enable.
//  - d_i: input data bus to be captured.
//  - q_o: registered output (final stage)
//
// Implementation notes:
//  - The first flop captures `d_i` and `en_i` concurrently into
//    `q_intermediate` and `en_intermediate` respectively.
//  - The second flop uses `en_intermediate` when deciding whether to update the
//    final output `q_o`, ensuring the enable used by the final stage matches
//    the data it will accept. This ordering avoids a data/enable mismatch.
//  - Both flops are cleared asynchronously on `arst_ni` active low.
//  - By inverting the clock (via parameter) we can make each flop sample on
//    either the positive or negative edge of `clk_i`. This is useful for
//    adjusting timing (e.g., for phase shift) without adding extra clocks.
// -----------------------------------------------------------------------------
module register_dual_flop #(
    // Width of the stored data
    parameter int                  ELEM_WIDTH             = 32,
    // Reset value for both flops
    parameter bit [ELEM_WIDTH-1:0] RESET_VALUE            = '0,
    // If 1 sample the first flop on posedge; if 0 sample on negedge
    parameter bit                  FIRST_FF_EDGE_POSEDGED = 1,
    // If 1 sample the last flop on posedge; if 0 sample on negedge
    parameter bit                  LAST_FF_EDGE_POSEDGED  = 0
) (
    // Base clock input. Note: exact sampling edges can be inverted by
    // parameters for phase adjustments.
    input logic clk_i,
    // Asynchronous active-low reset
    input logic arst_ni,

    // Synchronous enable for loads; captured by the first flop and used for
    // the second stage transfer
    input logic en_i,
    // Data input for the register
    input logic [ELEM_WIDTH-1:0] d_i,

    // Registered output
    output logic [ELEM_WIDTH-1:0] q_o
);

  // Internal stage captures
  logic [ELEM_WIDTH-1:0] q_intermediate;
  // Match enable to the intermediate data sample so enable is synchronous with
  // the data path and the final stage can update atomically with the sampled
  // enable state.
  logic en_intermediate;

  // Internal clock signals for the first and last flops. These may be inverted
  // versions of clk_i depending on the sample-edge parameters.
  logic first_clk_in;
  logic last_clk_in;

  // Choose between posedge or negedge sampling for each flop by optionally
  // inverting the provided clock. This flips the sampled edge without adding
  // another clock source.
  assign first_clk_in = FIRST_FF_EDGE_POSEDGED ? clk_i : ~clk_i;
  assign last_clk_in  = LAST_FF_EDGE_POSEDGED ? clk_i : ~clk_i;

  // First stage flip-flop: captures the data and enable. This stage uses an
  // asynchronous active-low reset so it is immediately set to RESET_VALUE when
  // arst_ni is asserted low.
  always_ff @(posedge first_clk_in or negedge arst_ni) begin
    if (~arst_ni) begin
      q_intermediate  <= RESET_VALUE;
      en_intermediate <= '0;
    end else begin
      q_intermediate  <= d_i;
      en_intermediate <= en_i;
    end
  end

  // Second stage flip-flop: optionally latches the intermediate data to q_o if
  // the sampled enable is asserted. This provides a gated transfer driven by the
  // previously sampled enable state, ensuring data/enable coherency.
  always_ff @(posedge last_clk_in or negedge arst_ni) begin
    if (~arst_ni) begin
      q_o <= RESET_VALUE;
    end else begin
      if (en_intermediate) q_o <= q_intermediate;
    end
  end

endmodule
