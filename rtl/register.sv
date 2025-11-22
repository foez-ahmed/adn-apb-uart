// -----------------------------------------------------------------------------
// Simple synchronous load-enable register with asynchronous active-low reset
//
// This register captures the data input `d_i` into `q_o` on the rising edge
// of `clk_i` when `en_i` is asserted. On deassertion of the asynchronous
// reset `arst_ni` (active-low), the register is set to `RESET_VALUE`.
//
// Parameters:
//  - ELEM_WIDTH: Width of the register (default 32)
//  - RESET_VALUE: Reset value for the register (wide-constant, defaults to 0)
//
// Ports:
//  - clk_i: synchronous clock
//  - arst_ni: asynchronous active-low reset
//  - en_i: synchronous load enable
//  - d_i: input data to be captured on load
//  - q_o: registered output
//
// This implementation follows the common pattern for an async-reset flip-flop
// with synchronous enable. The reset is active-low and asynchronous, meaning
// it immediately drives `q_o` to `RESET_VALUE` when asserted low.
// -----------------------------------------------------------------------------
module register #(
    // Width of the stored data
    parameter int                  ELEM_WIDTH  = 32,
    // Reset value used when arst_ni is asserted (active-low)
    parameter bit [ELEM_WIDTH-1:0] RESET_VALUE = '0
) (
    // Clock input
    input logic clk_i,
    // Asynchronous active-low reset
    input logic arst_ni,

    // Synchronous enable: when high, data is captured on rising edge of clk
    input logic en_i,
    // Data input to capture
    input logic [ELEM_WIDTH-1:0] d_i,

    // Registered output
    output logic [ELEM_WIDTH-1:0] q_o
);

  // Asynchronous active-low reset with synchronous enable on rising edge of
  // the clock: if arst_ni is low, load RESET_VALUE immediately. Otherwise on
  // the rising edge of clk_i, when en_i is asserted, capture d_i into q_o.
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      q_o <= RESET_VALUE;
    end else if (en_i) begin
      q_o <= d_i;
    end
  end

endmodule
