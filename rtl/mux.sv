// -----------------------------------------------------------------------------
// Simple multiplexer (mux)
//
// This module selects one of NUM_ELEM input words based on the binary select
// 's_i' and outputs it on 'o_o'. The operation is purely combinational.
//
// Important details:
//  - 's_i' width is computed with $clog2(NUM_ELEM) and must be at least 1 bit.
//  - If NUM_ELEM is not a power of two, some select values may be unused; the
//    select width remains the minimum required to encode NUM_ELEM values.
//  - When 's_i' indexes an element in 'i_i' out-of-range it will wrap or result
//    in X depending on simulation/synthesis tool; ensure valid selects.
// -----------------------------------------------------------------------------
module mux #(
    // Width of each input element
    parameter int ELEM_WIDTH = 8,
    // Number of input elements
    parameter int NUM_ELEM   = 6
) (
    // Binary select (log2(NUM_ELEM) bits)
    input logic [$clog2(NUM_ELEM)-1:0] s_i,

    // Input array: NUM_ELEM entries, each ELEM_WIDTH bits wide
    input logic [NUM_ELEM-1:0][ELEM_WIDTH-1:0] i_i,

    // Output: selected element from i_i based on s_i
    output logic [ELEM_WIDTH-1:0] o_o
);

  // Combinational assignment: select input word indexed by s_i
  // This is concise, synthesizable logic: output is a simple wire to the selected
  // element of the input array.
  always_comb o_o = i_i[s_i];

endmodule
