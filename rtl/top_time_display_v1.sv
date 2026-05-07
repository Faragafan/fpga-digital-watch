`timescale 1ns / 1ps

module top_time_display_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic CLOCK_50,
    input logic [1:0] SW,
    output logic [6:0] HEX5,
    output logic [6:0] HEX4,
    output logic [6:0] HEX3,
    output logic [6:0] HEX2,
    output logic [6:0] HEX1,
    output logic [6:0] HEX0
);
  logic tick_1Hz;
  logic tick_25Hz;
  logic tick_1kHz;
  logic selected_tick;

  logic [4:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;

  logic [3:0] hours_tens;
  logic [3:0] hours_ones;
  logic [3:0] minutes_tens;
  logic [3:0] minutes_ones;
  logic [3:0] seconds_tens;
  logic [3:0] seconds_ones;

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_1Hz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_1Hz)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND / 25)
  ) u_25Hz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_25Hz)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND / 1000)
  ) u_1kHz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_1kHz)
  );



  hms_counter #(
      .N_HOURS  (24),
      .N_MINUTES(60),
      .N_SECONDS(60)
  ) u_hms_counter (
      .clk(CLOCK_50),
      .enable(selected_tick),
      .hours(hours),
      .minutes(minutes),
      .seconds(seconds)
  );



  binary_to_bcd u_bcd_hours (
      .bin ({2'b0, hours}),
      .tens(hours_tens),
      .ones(hours_ones)
  );

  binary_to_bcd u_bcd_minutes (
      .bin ({1'b0, minutes}),
      .tens(minutes_tens),
      .ones(minutes_ones)
  );

  binary_to_bcd u_bcd_seconds (
      .bin ({1'b0, seconds}),
      .tens(seconds_tens),
      .ones(seconds_ones)
  );

  seven_segment u_hex5 (
      .digit(hours_tens),
      .blank(1'b0),
      .segments(HEX5)
  );

  seven_segment u_hex4 (
      .digit(hours_ones),
      .blank(1'b0),
      .segments(HEX4)
  );

  seven_segment u_hex3 (
      .digit(minutes_tens),
      .blank(1'b0),
      .segments(HEX3)
  );

  seven_segment u_hex2 (
      .digit(minutes_ones),
      .blank(1'b0),
      .segments(HEX2)
  );

  seven_segment u_hex1 (
      .digit(seconds_tens),
      .blank(1'b0),
      .segments(HEX1)
  );

  seven_segment u_hex0 (
      .digit(seconds_ones),
      .blank(1'b0),
      .segments(HEX0)
  );

  always_comb begin
    unique case (SW)
      2'b00: selected_tick = tick_1Hz;
      2'b01: selected_tick = tick_25Hz;
      2'b10: selected_tick = tick_1kHz;
      2'b11: selected_tick = 1'b1;
    endcase
  end

endmodule
