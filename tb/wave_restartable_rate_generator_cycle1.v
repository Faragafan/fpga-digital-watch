`timescale 1ns / 1ps

module wave_restartable_rate_generator_cycle1;
  reg  clk = 0;
  reg  run = 0;
  wire tick;

  restartable_rate_generator #(
      .CYCLE_COUNT(1)
  ) dut (
      .clk (clk),
      .run (run),
      .tick(tick)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("wave_restartable_rate_generator_cycle1.vcd");
    $dumpvars(0, wave_restartable_rate_generator_cycle1);

    // Initially disabled: tick should remain low
    #30;
    run = 1;

    // Since CYCLE_COUNT = 1, tick should be high every clock cycle while running
    #60;

    // Disable: tick should return low
    run = 0;
    #30;

    // Re-enable: tick should become high again while running
    run = 1;
    #50;

    run = 0;
    #20 $finish;
  end
endmodule