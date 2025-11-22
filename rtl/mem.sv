// -----------------------------------------------------------------------------
// Simple register-based memory (synchronous write, combinational read)
//
// This module implements a small memory using an array of registers. Writes are
// synchronous and gated by the write-enable `we_i`; the address `waddr_i` is
// decoded with a `demux` to choose which register is written. Reads are
// performed combinationally via a `mux` that selects the registered output at
// `raddr_i` and presents it on `rdata_o`.
//
// Behavior summary:
//  - Write: when `we_i` is asserted at a clock edge, the selected register is
//    updated with `wdata_i` on the rising edge of `clk_i`.
//  - Read: `rdata_o` is the registered value stored at address `raddr_i` and is
//    available combinationally. Note: if a write to the same address occurs in
//    the same cycle, `rdata_o` will reflect the stored value before the write
//    (read returns the previous value), since writes update on the clock edge.
//
// Parameters:
//  - ELEM_WIDTH: width of each memory element
//  - DEPTH: number of elements in the memory array
//
// Limitations / notes:
//  - DEPTH should be > 0. If a read or write idx exceeds the address width,
//    behavior depends on the select width and should be avoided.
//  - This is a simple implementation suitable for small memories or register
//    file emulation; for larger memories prefer vendor RAM primitives.
// -----------------------------------------------------------------------------
module mem #(
    // Width of each memory element
    parameter int ELEM_WIDTH = 8,
    // Depth (number of elements). Must be > 0.
    parameter int DEPTH      = 7
) (
    // Clock and asynchronous active-low reset (resets registers to 0)
    input logic clk_i,
    input logic arst_ni,

    // Write port: when we_i is high at the rising edge of clk_i, wdata_i is
    // stored at address waddr_i.
    input logic                     we_i,
    input logic [$clog2(DEPTH)-1:0] waddr_i,
    input logic [   ELEM_WIDTH-1:0] wdata_i,

    // Read port: combinationally selects and outputs the data stored at raddr_i
    input  logic [$clog2(DEPTH)-1:0] raddr_i,
    output logic [   ELEM_WIDTH-1:0] rdata_o
);

  // One-hot write enable for each register produced by the demux
  logic [DEPTH-1:0] demux_we;
  // Inputs to the read mux coming from each register instance
  logic [DEPTH-1:0][ELEM_WIDTH-1:0] reg_mux_in;

  // Decode write address into a one-hot vector; the demux instance converts
  // the binary address (waddr_i) into an enable vector `demux_we` for the
  // register array. ELEM_WIDTH=1 in the demux instance because we only need
  // one bit per element (a write enable), not a full-word demux.
  demux #(
      .NUM_ELEM  (DEPTH),
      .ELEM_WIDTH(1)
  ) u_demux (
      .s_i(waddr_i),
      .i_i(we_i),
      .o_o(demux_we)
  );

  // Memory array implemented as a bank of registers. Each register is gated by
  // its demuxed enable bit and captures the provided write data on the clock
  // edge. The array is indexed by the generate index `i`.
  for (genvar i = 0; i < DEPTH; i++) begin : g_reg_array
    register #(
        .ELEM_WIDTH (ELEM_WIDTH),
        .RESET_VALUE('0)
    ) register_dut (
        .clk_i  (clk_i),
        .arst_ni(arst_ni),
        .en_i   (demux_we[i]),
        .d_i    (wdata_i),
        .q_o    (reg_mux_in[i])
    );
  end

  // Read mux: a combinational mux routes the register outputs to the read data
  // port. The mux selects the `raddr_i` row from `reg_mux_in` to drive rdata_o.
  mux #(
      .ELEM_WIDTH(ELEM_WIDTH),
      .NUM_ELEM  (DEPTH)
  ) u_mux (
      .s_i(raddr_i),
      .i_i(reg_mux_in),
      .o_o(rdata_o)
  );

endmodule
