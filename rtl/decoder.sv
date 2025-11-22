// -----------------------------------------------------------------------------
// Simple binary-to-one-hot decoder
//
// This module decodes a binary address 'a_i' into a one-hot encoded output
// vector 'd_o' of width NUM_WIRE. The output for an index 'i' is asserted when
// 'a_i' equals 'i' and the input 'a_valid_i' is asserted.
//
// Key behavior:
//  - If a_valid_i is 0 then all outputs are 0.
//  - For each index i in [0..NUM_WIRE-1], d_o[i] is 1 when (a_i == i) && a_valid_i.
//
// Implementation notes:
//  - The design constructs a small per-index array of comparison bits and then
//    reduces them with an AND to drive the one-hot output for each index.
//  - `a_i_n` contains the bitwise inversion of `a_i` to allow matching to 0
//    using a simple multiplexer expression (i[j] ? a_i[j] : a_i_n[j]).
// -----------------------------------------------------------------------------
module decoder #(
    // Number of output wires (must be power-of-two for simple binary address width)
    parameter int NUM_WIRE = 4
) (
    // Binary address input. Width is log2(NUM_WIRE).
    input logic [$clog2(NUM_WIRE)-1:0] a_i,
    // Valid signal: only assert outputs when address is valid
    input logic                        a_valid_i,

    // One-hot outputs: 'd_o[i]' is high if (a_i == i) && a_valid_i
    output logic [NUM_WIRE-1:0] d_o
);


  // Inverted address bits; used to check when a_i bit is 0 without extra logic
  logic [$clog2(NUM_WIRE)-1:0] a_i_n;

  // Per-output partial-match vector: each entry is ($clog2(NUM_WIRE)+1) bits
  // The lower $clog2(NUM_WIRE) bits are the per-bit equality checks for the
  // address, and the MSB (index $clog2(NUM_WIRE)) contains a_valid_i.
  logic [  $clog2(NUM_WIRE):0] output_and_red[NUM_WIRE];

  // Invert incoming address bits for simpler matching to '0' bit of index i
  always_comb a_i_n = ~a_i;

  // Build per-index match bits. For each index 'i' (0..NUM_WIRE-1):
  //   - For each address bit j, create bit = (i[j] == a_i[j])
  //     which is implemented as (i[j] ? a_i[j] : a_i_n[j]).
  //   - The final element of the array is a_valid_i to gate outputs when not valid.
  always_comb begin
    for (bit [$clog2(NUM_WIRE):0] i = 0; i < NUM_WIRE; i++) begin
      for (int j = 0; j < $clog2(NUM_WIRE); j++) begin
        // Compare the j-th bit of index 'i' and input address 'a_i'
        // If i[j] == 1 then output_and_red[i][j] = a_i[j]
        // else (i[j] == 0) output_and_red[i][j] = !a_i[j]
        output_and_red[i][j] = i[j] ? a_i[j] : a_i_n[j];
      end
      // MSB holds the valid signal so that final reduction will include it
      output_and_red[i][$clog2(NUM_WIRE)] = a_valid_i;
    end
  end

  // Reduce the per-index vector with an AND into the one-hot output bit.
  for (genvar i = 0; i < NUM_WIRE; i++) begin : g_output_and_red
    // Only true if all bits match and a_valid_i is true
    always_comb d_o[i] = &output_and_red[i];
  end

endmodule
