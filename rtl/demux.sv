// -----------------------------------------------------------------------------
// Simple demultiplexer (demux)
//
// This module receives a single input word 'i_i' of width ELEM_WIDTH and routes
// it to one of NUM_ELEM outputs, selected by 's_i'. The outputs are one-hot
// gated copies of the input word: only the selected output will present the
// input bits; all other outputs will be 0.
//
// Notes:
//  - The module uses a 'decoder' instance to produce a one-hot valid vector
//    'valid_out' from the select signal 's_i'. The decoder is tied to always
//    assert (a_valid_i='1), so the selected output is always enabled.
//  - The per-bit outputs are created by ANDing each input bit with the
//    corresponding valid_out bit for that element. This keeps dataflow simple
//    and synthesizable.
//  - If needed, a_valid_i can be exposed as an input to gate when outputs
//    should be disabled (e.g., tri-state behavior).
// -----------------------------------------------------------------------------
module demux #(
    // Number of demultiplexed elements (rows). NUM_ELEM should be > 0.
    parameter int NUM_ELEM   = 6,
    // Width of each element (bits per row)
    parameter int ELEM_WIDTH = 8
) (
    // Select index (binary). Width is ceil(log2(NUM_ELEM)).
    input logic [$clog2(NUM_ELEM)-1:0] s_i,
    // Input word to be routed to one of the outputs
    input logic [ELEM_WIDTH-1:0] i_i,

    // Matrix of outputs: each row is ELEM_WIDTH wide, only one row is valid
    output logic [NUM_ELEM-1:0][ELEM_WIDTH-1:0] o_o
);

  // One-hot valid vector produced by the decoder; valid_out[i] == 1 indicates
  // 'i_o' should appear on 'o_o[i]'. The decoder instance drives this signal.
  logic [NUM_ELEM-1:0] valid_out;

  // Build the output matrix by gating each input bit with the per-element
  // valid bit. The inner loop assigns each bit of o_o[i] = i_i[j] AND valid_out[i].
  // This produces zero for non-selected rows, and i_i for the selected row.
  for (genvar i = 0; i < NUM_ELEM; i++) begin : g_elem
    for (genvar j = 0; j < ELEM_WIDTH; j++) begin : g_bits
      // Bit j of output row i = bit j of input word AND select bit i
      always_comb o_o[i][j] = i_i[j] & valid_out[i];
    end
  end

  // Instantiate decoder: convert binary select into one-hot vector.
  // We tie 'a_valid_i' to 1 to always enable the selected line.
  decoder #(
      .NUM_WIRE(NUM_ELEM)
  ) u_decoder (
      .a_i(s_i),
      .a_valid_i('1),
      .d_o(valid_out)
  );

endmodule
