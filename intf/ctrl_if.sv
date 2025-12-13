// Control interface for managing clock and reset signals in the testbench
interface ctrl_if;

  // Asynchronous reset signal, active low
  logic arst_ni;
  // Clock output signal
  logic clk_i;

  // Clock enable flag
  bit clk_en;
  // Time period for the clock
  realtime tp;

  // Task to apply reset for a specified duration
  task static apply_reset(input realtime duration);
    #duration;  // Wait for the specified duration
    arst_ni <= '0;  // Assert reset (active low)
    clk_en  <= '0;  // Disable clock
    #duration;  // Wait again
    arst_ni <= '1;  // Deassert reset
    #duration;  // Wait to stabilize
  endtask

  // Task to enable the clock with a given time period
  task static enable_clock(input realtime timeperiod);
    tp = timeperiod;  // Set the time period
    clk_en <= '1;  // Enable clock generation
  endtask

  // Task to disable the clock
  task static disable_clock();
    clk_en <= '0;  // Disable clock generation
  endtask

  // Always block to generate the clock signal when enabled
  always begin
    wait (clk_en === 1);  // Wait until clock is enabled
    clk_i <= 1'b1;  // Set clock high
    #(tp / 2);  // Wait half period
    clk_i <= 1'b0;  // Set clock low
    #(tp / 2);  // Wait half period
  end

endinterface






