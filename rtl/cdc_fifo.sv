// -----------------------------------------------------------------------------
// Clock-Domain Crossing FIFO (CDC FIFO)
//
// This FIFO allows safe transfer of data from one clock domain (elem_in_clk_i)
// to another (elem_out_clk_i) using Gray-code pointer synchronization. It
// supports synchronous writes on the input side and synchronous reads on the
// output side. Pointers are passed between domains using a pair of registers
// to reduce metastability and ensure correct sampling.
//
// Key concepts implemented:
//  - Binary counters for write/read addresses are converted to Gray code for
//    cross-domain synchronization (and converted back to binary to compute
//    counts and addresses internally).
//  - Pointers use an extra MSB to indicate wrapping for full/empty detection.
//  - Handshakes hsi/hso indicate a completed write or read transaction.
//  - The memory is implemented as an array of registers (mem) for the
//    write interface (synchronous write) and a combinational mux for reads.
//
// Parameters:
//  - ELEM_WIDTH: Bit-width of the FIFO elements
//  - FIFO_SIZE: Log2 of the number of entries (depth = 2**FIFO_SIZE). If set
//    to 0, the FIFO is effectively a single register.
// -----------------------------------------------------------------------------
module cdc_fifo #(
    parameter int ELEM_WIDTH = 8,
    parameter int FIFO_SIZE  = 2
) (
    // Asynchronous active-low reset (applies to registers in both domains)
    input logic arst_ni,

    // Write interface (input domain)
    input  logic [          ELEM_WIDTH-1:0] elem_in_i,
    input  logic                            elem_in_clk_i,
    input  logic                            elem_in_valid_i,
    // Ready is asserted when there's free space in the FIFO
    output logic                            elem_in_ready_o,
    // Count of free/filled elements relative to write domain
    output logic [$clog2(2**FIFO_SIZE)-1:0] elem_in_count_o,

    // Read interface (output domain)
    output logic [          ELEM_WIDTH-1:0] elem_out_o,
    input  logic                            elem_out_clk_i,
    output logic                            elem_out_valid_o,
    input  logic                            elem_out_ready_i,
    // Count of items available relative to output domain
    output logic [$clog2(2**FIFO_SIZE)-1:0] elem_out_count_o
);

  // Gray-coded pointers (synchronized between domains). The pointers are one
  // bit wider than the address bits to detect wrap-around (full/empty).
  logic [FIFO_SIZE:0] wr_ptr_pass;  // write pointer sampled in input domain
  logic [FIFO_SIZE:0] rd_ptr_pass;  // read pointer sampled in output domain

  // Handshake signals: hsi/hso pulse when a valid/ready handshake is accepted
  // on the respective domain. These control write and read pointer increments.
  logic hsi;  // handshake input (write side): valid && ready
  logic hso;  // handshake output (read side): valid && ready

  // Binary pointers: converted from Gray-coded synced pointer values by the
  // gray_to_bin converters below. wr_addr and rd_addr are used to compute
  // addresses and counts within each domain.
  logic [FIFO_SIZE:0] wr_addr;  // write address (binary) in input domain
  logic [FIFO_SIZE:0] rd_addr;  // read address (binary) in input domain

  // The primed versions (wr_addr_ / rd_addr_) are binary pointers sampled in
  // the remote clock domain (after crossing). The suffix `_` typically
  // indicates the synchronized copy of the pointer arriving from the other
  // clock domain.
  logic [FIFO_SIZE:0] wr_addr_;  // write address observed in output domain
  logic [FIFO_SIZE:0] rd_addr_;  // read address observed in input domain

  // Next-pointer (binary) for incrementing write/read pointers prior to
  // converting to Gray code and passing to the remote domain.
  logic [FIFO_SIZE:0] wr_addr_p1;
  logic [FIFO_SIZE:0] rd_addr_p1;

  // Gray-coded next pointers to be stored into registers and synchronized to
  // the remote domain: wpgi/rpgi are Gray-coded values used to pass pointers
  // to the opposite domain (passed in the handshake registers), while wpgo/
  // rpgo are Gray-coded pointers that have been synchronized into this domain.
  logic [FIFO_SIZE:0] wpgi;  // write pointer Gray (write domain -> output domain)
  logic [FIFO_SIZE:0] rpgi;  // read pointer Gray (output domain -> input domain)

  logic [FIFO_SIZE:0] wpgo;  // write pointer Gray observed in output domain
  logic [FIFO_SIZE:0] rpgo;  // read pointer Gray observed in input domain

  // Handshakes: when both valid and ready are asserted the transfer occurs.
  assign hsi = elem_in_valid_i & elem_in_ready_o;
  assign hso = elem_out_valid_o & elem_out_ready_i;

  // Next addresses: increment current addresses for write/read pointer update
  assign wr_addr_p1 = wr_addr + 1;
  assign rd_addr_p1 = rd_addr + 1;

  // Write-side ready logic: determine if write is possible by checking for
  // full condition. The FIFO is considered full when the write binary pointer
  // equals the read pointer with the MSB inverted and the lower bits equal.
  // For FIFO_SIZE == 0 we handle single-entry FIFO special case.
  if (FIFO_SIZE > 0) begin : g_elem_in_ready_o
    assign elem_in_ready_o = arst_ni & !(
                                (wr_addr[FIFO_SIZE] != rd_addr_[FIFO_SIZE])
                                &&
                                (wr_addr[FIFO_SIZE-1:0] == rd_addr_[FIFO_SIZE-1:0])
                              );
  end else begin : g_elem_in_ready_o
    // Single-element FIFO ready when the synchronized write pointer equals read
    // pointer, meaning space is available to write.
    assign elem_in_ready_o = arst_ni & (wr_addr_ == rd_addr);
  end

  // Output valid is set when write pointer observed in output domain differs
  // from read pointer observed in output domain (there's at least one item).
  assign elem_out_valid_o = (wr_addr_ != rd_addr);

  // Approximate counts: provide visible counts in each domain using binary
  // arithmetic on the lower address bits. These are not full absolute counts
  // but valid for monitoring and simple flow control when used in the same
  // clock domain as the pointer subtraction.
  assign elem_in_count_o  = wr_addr[FIFO_SIZE-1:0] - rd_addr_[FIFO_SIZE-1:0];
  assign elem_out_count_o = wr_addr_[FIFO_SIZE-1:0] - rd_addr[FIFO_SIZE-1:0];

  // Convert synchronized Gray-coded pointers back to binary addresses for local
  // arithmetic. The data path uses the binary addresses for indexing, while
  // Gray-coded pointers are used for safe cross-domain passing.
  gray_to_bin #(
      .DATA_WIDTH(FIFO_SIZE + 1)
  ) g2b_wi (
      .data_in_i (wr_ptr_pass),
      .data_out_o(wr_addr)
  );

  gray_to_bin #(
      .DATA_WIDTH(FIFO_SIZE + 1)
  ) g2b_ri (
      .data_in_i (rpgo),
      .data_out_o(rd_addr_)
  );

  gray_to_bin #(
      .DATA_WIDTH(FIFO_SIZE + 1)
  ) g2b_wo (
      .data_in_i (wpgo),
      .data_out_o(wr_addr_)
  );

  gray_to_bin #(
      .DATA_WIDTH(FIFO_SIZE + 1)
  ) g2b_ro (
      .data_in_i (rd_ptr_pass),
      .data_out_o(rd_addr)
  );

  // Convert the next (binary) pointers to Gray code to pass across domains.
  bin_to_gray #(
      .DATA_WIDTH(FIFO_SIZE + 1)
  ) b2g_w (
      .data_in_i (wr_addr_p1),
      .data_out_o(wpgi)
  );

  bin_to_gray #(
      .DATA_WIDTH(FIFO_SIZE + 1)
  ) b2g_r (
      .data_in_i (rd_addr_p1),
      .data_out_o(rpgi)
  );

  // Register groups for pointer passing and synchronization:
  //  - wr_ptr_ic: input-domain register that captures the Gray-coded write
  //    pointer when a write handshake occurs and passes it onward (wr_ptr_pass)
  register #(
      .ELEM_WIDTH (FIFO_SIZE + 1),
      .RESET_VALUE('0)
  ) wr_ptr_ic (
      .clk_i  (elem_in_clk_i),
      .arst_ni(arst_ni),
      .en_i   (hsi),
      .d_i    (wpgi),
      .q_o    (wr_ptr_pass)
  );

  //  - rd_ptr_ic: input-domain synchronized version of the read pointer that
  //    has arrived from the output domain; here we use a dual-flop register to
  //    reduce metastability risk (sample on inverted/normal edges to shift
  //    timing if needed).
  register_dual_flop #(
      .ELEM_WIDTH(FIFO_SIZE + 1),
      .RESET_VALUE('0),
      .FIRST_FF_EDGE_POSEDGED(0),
      .LAST_FF_EDGE_POSEDGED(1)
  ) rd_ptr_ic (
      .clk_i  (elem_in_clk_i),
      .arst_ni(arst_ni),
      .en_i   ('1),
      .d_i    (rd_ptr_pass),
      .q_o    (rpgo)
  );

  //  - wr_ptr_oc: output-domain synchronized write pointer (used to detect
  //    whether there's data available). We synchronize the write pointer into
  //    the output domain using the dual-flop register.
  register_dual_flop #(
      .ELEM_WIDTH(FIFO_SIZE + 1),
      .RESET_VALUE('0),
      .FIRST_FF_EDGE_POSEDGED(0),
      .LAST_FF_EDGE_POSEDGED(1)
  ) wr_ptr_oc (
      .clk_i  (elem_out_clk_i),
      .arst_ni(arst_ni),
      .en_i   ('1),
      .d_i    (wr_ptr_pass),
      .q_o    (wpgo)
  );

  //  - rd_ptr_oc: output-domain register that captures the Gray-coded read
  //    pointer when a read handshake occurs, passing it to the input domain.
  register #(
      .ELEM_WIDTH (FIFO_SIZE + 1),
      .RESET_VALUE('0)
  ) rd_ptr_oc (
      .clk_i  (elem_out_clk_i),
      .arst_ni(arst_ni),
      .en_i   (hso),
      .d_i    (rpgi),
      .q_o    (rd_ptr_pass)
  );

  // Memory or single-register fall-back. If FIFO_SIZE > 0, instantiate mem as
  // an array of registers with depth = 2**FIFO_SIZE. Otherwise the FIFO is a
  // single register (DEPTH=1) and we just use a register instance.
  if (FIFO_SIZE > 0) begin : g_mem
    mem #(
        .ELEM_WIDTH(ELEM_WIDTH),
        .DEPTH(2 ** FIFO_SIZE)
    ) u_mem (
        .clk_i  (elem_in_clk_i),
        .arst_ni(arst_ni),
        .we_i   (hsi),
        .waddr_i(wr_addr[FIFO_SIZE-1:0]),
        .wdata_i(elem_in_i),
        .raddr_i(rd_addr[FIFO_SIZE-1:0]),
        .rdata_o(elem_out_o)
    );
  end else begin : g_mem
    register #(
        .ELEM_WIDTH (ELEM_WIDTH),
        .RESET_VALUE('0)
    ) u_mem (
        .clk_i  (elem_in_clk_i),
        .arst_ni(arst_ni),
        .en_i   (hsi),
        .d_i    (elem_in_i),
        .q_o    (elem_out_o)
    );
  end

endmodule
