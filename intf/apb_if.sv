interface apb_if #(
    parameter int ADDR_WIDTH = `DEFAULT_ADDR_WIDTH,
    parameter int DATA_WIDTH = `DEFAULT_DATA_WIDTH
) (
    // Global signals
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i     // Clock input
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // APB Slave Interface Signals
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic                      psel;  // Peripheral select
  logic                      penable;  // Peripheral enable
  logic [    ADDR_WIDTH-1:0] paddr;  // Peripheral address
  logic                      pwrite;  // Peripheral write enable
  logic [    DATA_WIDTH-1:0] pwdata;  // Peripheral write data
  logic [DATA_WIDTH / 8-1:0] pstrb;  // Peripheral byte strobe
  logic                      pready;  // Peripheral ready
  logic [    DATA_WIDTH-1:0] prdata;  // Peripheral read data
  logic                      pslverr;  // Peripheral slave error

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic do_transaction(input logic write, input logic [ADDR_WIDTH-1:0] address,
                                input logic [DATA_WIDTH-1:0] write_data,
                                input logic [DATA_WIDTH/8-1:0] write_strobe,
                                output logic [DATA_WIDTH-1:0] read_data);
    // Setup phase
    psel    <= 1'b1;
    penable <= 1'b0;
    paddr   <= address;
    pwrite  <= write;
    pwdata  <= write_data;
    pstrb   <= write_strobe;

    // Wait one clock cycle
    @(posedge clk_i);

    // Enable phase
    penable <= 1'b1;

    do @(posedge clk_i); while (!pready);

    // Capture read data
    read_data = prdata;

    // Deassert signals
    psel    <= 1'b0;
    penable <= 1'b0;
  endtask

  task automatic reset();
    psel    <= 1'b0;
    penable <= 1'b0;
    paddr   <= '0;
    pwrite  <= 1'b0;
    pwdata  <= '0;
    pstrb   <= '0;
  endtask

  task automatic write_32(input logic [ADDR_WIDTH-1:0] address,
                          input logic [DATA_WIDTH-1:0] write_data);
    logic [DATA_WIDTH-1:0] read_data_dummy;
    do_transaction(1'b1, address, write_data, 'h0f, read_data_dummy);
  endtask

  task automatic read_32(input logic [ADDR_WIDTH-1:0] address,
                         output logic [DATA_WIDTH-1:0] read_data);
    do_transaction(1'b0, address, '0, '0, read_data);
  endtask

  task automatic write(input logic [ADDR_WIDTH-1:0] address,
                       input logic [DATA_WIDTH-1:0] write_data);
    write_32(address, write_data);
  endtask

  task automatic read(input logic [ADDR_WIDTH-1:0] address,
                      output logic [DATA_WIDTH-1:0] read_data);
    read_32(address, read_data);
  endtask

  task automatic get_transaction(output logic direction, output logic [ADDR_WIDTH-1:0] address,
                                 output logic [DATA_WIDTH-1:0] write_data,
                                 output logic [DATA_WIDTH/8-1:0] write_strobe,
                                 output logic [DATA_WIDTH-1:0] read_data, output logic slverr);

    //Wait for setup phase
    do @(posedge clk_i); while (!(psel == 1'b1 && penable == 1'b0));

    //Wait for access phase
    do @(posedge clk_i); while (!(psel == 1'b1 && penable == 1'b1));

    //Update information as long as enable stage high
    while (psel == 1'b1 && penable == 1'b1) begin
      direction    = pwrite;
      address      = paddr;
      write_data   = pwdata;
      write_strobe = pstrb;
      read_data    = prdata;
      slverr       = pslverr;
      @(posedge clk_i);
    end

  endtask

endinterface
