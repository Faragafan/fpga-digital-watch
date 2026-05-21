`timescale 1ns / 1ps

module stopwatch_counter #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    input logic rst,     // Takes priority over enable
    input logic enable,
    output logic [6:0] minutes,
    output logic [5:0] seconds,
    output logic [6:0] centiseconds  // hundredths of a second
);

  localparam int CYCLES_PER_CENTISECOND = CYCLES_PER_SECOND / 100;

  logic centisecond_tick;
  logic tick_run;
  logic counter_enable;

  assign tick_run = enable && !rst;
  assign counter_enable = enable && centisecond_tick;

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_CENTISECOND)
  ) u_centisecond_rate (
      .clk(clk),
      .run(tick_run),
      .tick(centisecond_tick)
  );

  cascade_counter #(
      .N2(100),
      .N1(60),
      .N0(100),
      .W2(7),
      .W1(6),
      .W0(7)
  ) u_stopwatch_count (
      .clk(clk),
      .rst(rst),
      .enable(counter_enable),
      .count2(minutes),
      .count1(seconds),
      .count0(centiseconds)
  );

endmodule
