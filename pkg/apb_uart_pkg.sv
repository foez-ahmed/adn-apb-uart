package apb_uart_pkg;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTANTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // System/address/data widths used by the APB interface logic
  localparam int SYS_ADDR_WIDTH = 5;  // System Address Width (allows addressing 32 bytes)
  localparam int SYS_DATA_WIDTH = 32; // System Data Width (32-bit registers)

  // Defaults for UART configuration (matches documentation)
  // DEFAULT_BAUD_RATE: reset divider value (0x2580) -> 9600 baud @ 100 MHz APB clock
  localparam int DEFAULT_BAUD_RATE = 'h2580;  // 9600
  localparam bit DEFAULT_PARITY_EN = 1'b0;    // Parity disabled by default
  localparam bit DEFAULT_PARITY_TYPE = 1'b0;  // Default parity = even (0 = even, 1 = odd)
  localparam bit DEFAULT_EXTRA_STOP_BITS = 1'b0; // Default = 1 stop bit

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REGISTER ADDRESSES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Register addresses (byte offsets) exposed over the APB bus
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_CTRL_ADDR = 'h00;           // Control Register (CTRL)
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_CLK_DIV_ADDR = 'h04;        // Clock Divider (CLK_DIV)
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_CFG_ADDR = 'h08;            // Configuration (CFG)
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_TX_FIFO_COUNT_ADDR = 'h0C; // TX FIFO count (RO)
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_RX_FIFO_COUNT_ADDR = 'h10; // RX FIFO count (RO)
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_TX_DATA_ADDR = 'h14;       // TX data (WO)
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_RX_DATA_ADDR = 'h18;       // RX data (RO)
  localparam logic [SYS_ADDR_WIDTH-1:0] REG_INTR_CTRL_ADDR = 'h1C;     // Interrupt control/status

  ///////////////////////////////////////////////////////////////////////////////////////////////////
  // REGISTER TYPE DEFINITIONS
  ///////////////////////////////////////////////////////////////////////////////////////////////////

  // CTRL register (0x00)
  // Bit mapping (MSB -> LSB): [31:3] RESERVED, [2] RX_FLUSH, [1] TX_FLUSH, [0] CLK_EN
  // Resets: all zeros. Writing '1' to TX_FLUSH/RX_FLUSH should clear respective FIFOs (self-clearing).
  typedef struct packed {
    logic [28:0] RESERVED; // bits [31:3]
    logic        RX_FLUSH; // bit 2: write 1 to flush RX FIFO (self-clearing)
    logic        TX_FLUSH; // bit 1: write 1 to flush TX FIFO (self-clearing)
    logic        CLK_EN;   // bit 0: enable UART clock
  } ctrl_reg_t;

  // CLK_DIV register (0x04)
  // 32-bit divider value: Baud Rate = APB_Clock / (DIVIDER + 1)
  typedef struct packed { logic [31:0] CLK_DIV; } clk_div_reg_t; // bits [31:0]

  // CFG register (0x08)
  // Bit mapping: [31:3] RESERVED, [2] EXTRA_STOP_BITS, [1] PARITY_TYPE, [0] PARITY_EN
  // PARITY_EN = 1 enables parity; PARITY_TYPE = 0 => even, 1 => odd
  typedef struct packed {
    logic [28:0] RESERVED;       // bits [31:3]
    logic        EXTRA_STOP_BITS; // bit 2: 0 = 1 stop bit, 1 = 2 stop bits
    logic        PARITY_TYPE;     // bit 1: 0 = even, 1 = odd (when PARITY_EN=1)
    logic        PARITY_EN;       // bit 0: parity enable
  } cfg_reg_t;

  // TX_FIFO_COUNT (0x0C) - Read-only count of bytes in TX FIFO
  typedef struct packed { logic [31:0] TX_FIFO_COUNT; } tx_fifo_count_reg_t; // bits [31:0]

  // RX_FIFO_COUNT (0x10) - Read-only count of bytes in RX FIFO
  typedef struct packed { logic [31:0] RX_FIFO_COUNT; } rx_fifo_count_reg_t; // bits [31:0]

  // TX_DATA (0x14) - Write-only: enqueue a byte to TX FIFO
  // Mapping: [31:8] RESERVED, [7:0] TX_DATA
  typedef struct packed {
    logic [23:0] RESERVED; // bits [31:8]
    logic [7:0]  TX_DATA;  // bits [7:0] - write the byte to transmit
  } tx_data_reg_t;

  // RX_DATA (0x18) - Read-only: dequeue oldest byte from RX FIFO
  // Mapping: [31:8] RESERVED, [7:0] RX_DATA
  typedef struct packed {
    logic [23:0] RESERVED; // bits [31:8]
    logic [7:0]  RX_DATA;  // bits [7:0] - read received byte
  } rx_data_reg_t;

  // INTR_CTRL (0x1C) - Interrupt control/status
  // Bit mapping: [31:4] RESERVED, [3] TX_ALMOST_EMPTY, [2] RX_ALMOST_FULL, [1] RX_PARITY_ERROR, [0] RX_VALID
  // Writing '1' to status bits clears them.
  typedef struct packed {
    logic [27:0] RESERVED;         // bits [31:4]
    logic        TX_ALMOST_EMPTY;  // bit 3: TX FIFO almost empty (interrupt/status)
    logic        RX_ALMOST_FULL;   // bit 2: RX FIFO almost full (interrupt/status)
    logic        RX_PARITY_ERROR;  // bit 1: parity error detected on received byte
    logic        RX_VALID;         // bit 0: data available in RX FIFO
  } intr_ctrl_reg_t;

endpackage
