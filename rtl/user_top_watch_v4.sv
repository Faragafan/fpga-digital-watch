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

module user_top_watch_v4 #(
    /* verilator lint_off UNUSEDPARAM */
    parameter int CYCLES_PER_SECOND = 50_000_000
    /* verilator lint_on UNUSEDPARAM */
) (
    input logic clk,
    /* verilator lint_off UNUSED */
    input logic [3:0] button,
    input logic [9:0] sw,
    /* verilator lint_on UNUSED */
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);

  // ------------------
  // Core Functionality
  // ------------------

  logic [5:0] seconds;
  // Seconds
  logic seconds_tick;
  logic seconds_edit;
  logic seconds_inc;
  logic seconds_dec;
  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .tick(seconds_tick),
      .edit_mode(seconds_edit),
      .inc(seconds_inc),
      .dec(seconds_dec),
      .count(seconds)
  );

  logic [5:0] minutes;
  // minutes
  logic minutes_tick;
  logic minutes_edit;
  logic minutes_inc;
  logic minutes_dec;
  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .tick(minutes_tick),
      .edit_mode(minutes_edit),
      .inc(minutes_inc),
      .dec(minutes_dec),
      .count(minutes)
  );

  logic [4:0] hours;
  // hours
  logic hours_tick;
  logic hours_edit;
  logic hours_inc;
  logic hours_dec;
  editable_counter #(
      .N(24),
      .WIDTH(5)
  ) u_hours (
      .clk(clk),
      .tick(hours_tick),
      .edit_mode(hours_edit),
      .inc(hours_inc),
      .dec(hours_dec),
      .count(hours)
  );


  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_divider_1Hz (
      .clk (clk),
      .run (seconds_timer_run),
      .tick(seconds_tick)
  );

  assign seconds_edit = mode_enable[0];
  assign minutes_edit = mode_enable[1];
  assign hours_edit = mode_enable[2];

  assign seconds_inc = inc_pulse;
  assign seconds_dec = dec_pulse;

  assign minutes_inc = inc_pulse;
  assign minutes_dec = dec_pulse;

  assign hours_inc = inc_pulse;
  assign hours_dec = dec_pulse;

  assign minutes_tick = seconds_tick && (seconds_disp == 7'd59);
  assign hours_tick = minutes_tick && (minutes_disp == 7'd59);



  // Zero - extend counter values to display outputs
  assign hours_disp = {2'b0, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

  // Unused
  assign led = 10'b0;
  assign blank_hours = mode_enable[2] && !pwm_out;
  assign blank_minutes = mode_enable[1] && !pwm_out;
  assign blank_seconds = mode_enable[0] && !pwm_out;



  // --------------
  // Mode Selection
  // --------------
  logic [2:0] mode_enable;

  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)  // Fill in , based on CYCLES_PER_SECOND
  ) u_mode_selector (
      .clk(clk),
      .button(button[3]),
      .mode_enable(mode_enable)
  );


  logic pwm_out;

  localparam int FLASHPERIODCYCLES = CYCLES_PER_SECOND / 2;
  localparam int FLASHDUTYCYCLES = (FLASHPERIODCYCLES * 8) / 10;

  pwm_generator #(
      .PERIOD_CYCLES(FLASHPERIODCYCLES),
      .DUTY_CYCLES  (FLASHDUTYCYCLES)
  ) u_flash_pwm (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  // ------------------
  // Edit Logic
  // ------------------


  logic inc_pulse;
  logic dec_pulse;

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_inc_button (
      .clk(clk),
      .button(button[1]),
      .pulse(inc_pulse)
  );

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_dec_button (
      .clk(clk),
      .button(button[0]),
      .pulse(dec_pulse)
  );

  // ------------------
  // V4 Accurate Time Setting
  // ------------------
  logic [2:0] mode_enable_prev;

  always_ff @(posedge clk) begin
    mode_enable_prev <= mode_enable;
  end

  logic realign_seconds_tick;

  assign realign_seconds_tick = (mode_enable_prev == 3'b001) && (mode_enable == 3'b010);
  logic seconds_timer_run;
  assign seconds_timer_run = !realign_seconds_tick;

endmodule
