// ------------------------------------------------------------------
// WARNING: This file is used by the automated test suite. Do not
// modify it.
//
// This file also serves as a template for your own designs. To use
// it:
//   1. Copy the entire contents into a new file with a descriptive
//      name.
//   2. Delete the test logic below and replace it with your own
//      code.
//   3. In top_de1_soc, change the module name from user_top to your
//      new module name.
//
//   The board wrapper sets CYCLES_PER_SECOND; use this parameter in
//   your design wherever timing is needed.
// ------------------------------------------------------------------
`timescale 1ns / 1ps

module user_top_stopwatch_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    input logic [3:0] button,
    input logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);

  // ------------------
  // Button edge detect
  // ------------------

  logic rise_start_stop;
  logic rise_lap;

  rising_edge_detector u_start_stop_edge (
      .clk(clk),
      .sig_in(button[0]),
      .rise(rise_start_stop)
  );

  rising_edge_detector u_lap_edge (
      .clk(clk),
      .sig_in(button[1]),
      .rise(rise_lap)
  );

  // ------------------
  // Stopwatch control
  // ------------------

  logic counter_rst;
  logic counter_enable;
  logic lap_hold;

  stopwatch_control u_control (
      .clk(clk),
      .rise_start_stop(rise_start_stop),
      .rise_lap(rise_lap),
      .counter_rst(counter_rst),
      .counter_enable(counter_enable),
      .lap_hold(lap_hold)
  );

  // ------------------
  // Stopwatch counter
  // ------------------

  logic [6:0] live_minutes;
  logic [5:0] live_seconds;
  logic [6:0] live_centiseconds;

  stopwatch_counter #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_counter (
      .clk(clk),
      .rst(counter_rst),
      .enable(counter_enable),
      .minutes(live_minutes),
      .seconds(live_seconds),
      .centiseconds(live_centiseconds)
  );

  // ------------------
  // Snapshot multiplexers
  // ------------------

  logic [6:0] display_minutes;
  logic [5:0] display_seconds;
  logic [6:0] display_centiseconds;

  snapshot_mux #(
      .WIDTH(7)
  ) u_minutes_snapshot (
      .clk(clk),
      .hold(lap_hold),
      .d(live_minutes),
      .q(display_minutes)
  );

  snapshot_mux #(
      .WIDTH(6)
  ) u_seconds_snapshot (
      .clk(clk),
      .hold(lap_hold),
      .d(live_seconds),
      .q(display_seconds)
  );

  snapshot_mux #(
      .WIDTH(7)
  ) u_centiseconds_snapshot (
      .clk(clk),
      .hold(lap_hold),
      .d(live_centiseconds),
      .q(display_centiseconds)
  );

  // ------------------
  // Display outputs
  // ------------------

  assign hours_disp   = display_minutes;
  assign minutes_disp = {1'b0, display_seconds};
  assign seconds_disp = display_centiseconds;

  assign blank_hours   = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

  // ------------------
  // Unused outputs/inputs
  // ------------------

  assign led = 10'b0;

  logic unused_inputs;
  assign unused_inputs = |button[3:2] | |sw;

endmodule
