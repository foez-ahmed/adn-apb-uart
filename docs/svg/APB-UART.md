# APB-UART Register Map and Configuration

This document describes the register map and configuration options for the APB-UART (Advanced Peripheral Bus - Universal Asynchronous Receiver/Transmitter) peripheral. The UART implements a standard serial communication interface with configurable baud rate, parity, and stop bits, along with transmit and receive FIFOs.

## Register Summary

| Register | Access | Address | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| CTRL | RW | 0x00 | 0x0 | Control register for clock enable and FIFO flush operations |
| CLK\_DIV | RW | 0x04 | 0x2580 | Clock divider register for baud rate generation |
| CONFIG | RW | 0x08 | 0x0 | UART configuration register for parity and stop bits |
| TX\_FIFO\_COUNT | RO | 0x0C | 0x0 | Transmit FIFO data count (read-only) |
| RX\_FIFO\_COUNT | RO | 0x10 | 0x0 | Receive FIFO data count (read-only) |
| TX\_DATA | WO | 0x14 | 0x0 | Transmit data register (write-only) |
| RX\_DATA | RO | 0x18 | 0x0 | Receive data register (read-only) |
| INTR\_CTRL | RW | 0x1C | 0x0 | Interrupt control register |

## Register Details

### CTRL (0x00) - Control Register

Controls the basic operation of the UART peripheral, including clock enable and FIFO management.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| CLK\_EN | RW | 0 | 0x0 | Clock Enable: 1 = Enable UART clock, 0 = Disable UART clock |
| TX\_FLUSH | RW | 1 | 0x0 | Transmit FIFO Flush: Write 1 to clear TX FIFO (self-clearing) |
| RX\_FLUSH | RW | 2 | 0x0 | Receive FIFO Flush: Write 1 to clear RX FIFO (self-clearing) |
| RESERVED | \- | 31:3 | 0x0 | Reserved for future use |

### CLK\_DIV (0x04) - Clock Divider Register

Configures the baud rate by dividing the input clock. The baud rate is calculated as: `Baud Rate = APB_Clock / (DIVIDER + 1)`.

Default value of 0x2580 (9600) provides a baud rate of 9600 when using a 100 MHz APB clock.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| DIVIDER | RW | 31:0 | 0x2580 | Clock divider value for baud rate generation |

### CONFIG (0x08) - Configuration Register

Configures UART frame format including parity and stop bit settings.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| PARITY\_EN | RW | 0 | 0x0 | Parity Enable: 1 = Enable parity bit, 0 = Disable parity |
| PARITY\_TYPE | RW | 1 | 0x0 | Parity Type: 1 = Odd parity, 0 = Even parity (only valid when PARITY\_EN = 1) |
| EXTRA\_STOP | RW | 2 | 0x0 | Stop Bits: 1 = Two stop bits, 0 = One stop bit |
| RESERVED | \- | 31:3 | 0x0 | Reserved for future use |

### TX\_FIFO\_COUNT (0x0C) - Transmit FIFO Count Register

Read-only register that indicates the number of bytes currently in the transmit FIFO.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| COUNT | RO | 31:0 | 0x0 | Number of bytes currently stored in the transmit FIFO |

### RX\_FIFO\_COUNT (0x10) - Receive FIFO Count Register

Read-only register that indicates the number of bytes currently in the receive FIFO.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| COUNT | RO | 31:0 | 0x0 | Number of bytes currently stored in the receive FIFO |

### TX\_DATA (0x14) - Transmit Data Register

Write-only register for transmitting data. Writing a byte to this register adds it to the transmit FIFO. Software should check TX\_FIFO\_COUNT or interrupt status before writing to avoid overflow.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| DATA | WO | 7:0 | \- | Data byte to transmit (8 bits) |
| RESERVED | \- | 31:8 | \- | Reserved, writes ignored |

### RX\_DATA (0x18) - Receive Data Register

Read-only register for receiving data. Reading from this register removes the oldest byte from the receive FIFO. Software should check RX\_FIFO\_COUNT or interrupt status before reading to ensure data is available.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| DATA | RO | 7:0 | 0x0 | Received data byte (8 bits) |
| RESERVED | \- | 31:8 | 0x0 | Reserved, always reads 0 |

### INTR\_CTRL (0x1C) - Interrupt Control Register

Controls interrupt enables and provides status flags for various UART conditions. Writing 1 to a status bit clears the interrupt flag.

| Bit Field | Access | Index | Reset Value | Description |
| :---- | :---- | :---- | :---- | :---- |
| RX\_VALID | RW | 0 | 0x0 | Receive Data Valid: Set when data is available in RX FIFO, write 1 to clear |
| RX\_PARITY\_ERROR | RW | 1 | 0x0 | Receive Parity Error: Set when parity error detected, write 1 to clear |
| RX\_ALMOST\_FULL | RW | 2 | 0x0 | Receive FIFO Almost Full: Set when RX FIFO reaches threshold, write 1 to clear |
| TX\_ALMOST\_EMPTY | RW | 3 | 0x0 | Transmit FIFO Almost Empty: Set when TX FIFO falls below threshold, write 1 to clear |
| RESERVED | \- | 31:4 | 0x0 | Reserved for future use |
