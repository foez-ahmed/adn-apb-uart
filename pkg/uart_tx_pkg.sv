package uart_tx_pkg;

typedef enum logic [3:0] {
  IDLE,
  START_BIT,
  DATA_0,
  DATA_1,
  DATA_2,
  DATA_3,
  DATA_4,
  DATA_5,
  DATA_6,
  DATA_7,
  PARITY_BIT,
  STOP_BIT,
  EXTRA_STOP  
} uart_tx_state_e;

endpackage
