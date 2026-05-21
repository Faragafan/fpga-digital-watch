`timescale 1ns / 1ps

module user_top_timer_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
`ifdef FORMAL
    output logic probe_running,
    output logic [2:0] probe_mode_enable,
`endif
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

  logic rise_start_pause;

  rising_edge_detector u_start_pause_edge (
      .clk(clk),
      .sig_in(button[0]),
      .rise(rise_start_pause)
  );

  // --------------
  // Mode Selection
  // --------------

  logic [2:0] mode_enable;
  logic in_set_mode;
  logic edit_button;

  assign in_set_mode = |mode_enable;

  // Set mode cannot be newly entered while the timer is already running.
  assign edit_button = button[3] && !running;

  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)
  ) u_mode_selector (
      .clk(clk),
      .button(edit_button),
      .mode_enable(mode_enable)
  );

  // ------------------
  // Running FSM
  // ------------------

  logic running = 1'b0;
  logic is_zero;

  always_ff @(posedge clk) begin
    if (in_set_mode) begin
      running <= 1'b0;
    end else if (is_zero) begin
      running <= 1'b0;
    end else if (rise_start_pause) begin
      running <= !running;
    end
  end

  // ------------------
  // Tick generation
  // ------------------

  logic one_hz_tick;
  logic timer_tick;

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_one_hz (
      .clk(clk),
      .run(running && !is_zero),
      .tick(one_hz_tick)
  );

  assign timer_tick = running && !is_zero && one_hz_tick;

  // ------------------
  // Edit buttons
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
  // Countdown counters
  // ------------------

  logic [5:0] timer_seconds;
  logic [5:0] timer_minutes;
  logic [4:0] timer_hours;

  logic seconds_borrow;
  logic minutes_borrow;
  logic hours_borrow;

  assign is_zero = (timer_hours == 5'd0) && (timer_minutes == 6'd0) && (timer_seconds == 6'd0);

  editable_countdown #(
      .MAX(59),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .clr(1'b0),
      .tick(timer_tick),
      .edit_mode(mode_enable[0]),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(timer_seconds),
      .borrow_out(seconds_borrow)
  );

  editable_countdown #(
      .MAX(59),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .clr(1'b0),
      .tick(seconds_borrow),
      .edit_mode(mode_enable[1]),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(timer_minutes),
      .borrow_out(minutes_borrow)
  );

  editable_countdown #(
      .MAX(23),
      .WIDTH(5)
  ) u_hours (
      .clk(clk),
      .clr(1'b0),
      .tick(minutes_borrow),
      .edit_mode(mode_enable[2]),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(timer_hours),
      .borrow_out(hours_borrow)
  );

  // ------------------
  // Display flashing
  // ------------------

  logic pwm_out;

  localparam int FLASH_PERIOD_CYCLES = CYCLES_PER_SECOND / 2;
  localparam int FLASH_DUTY_CYCLES = (FLASH_PERIOD_CYCLES * 8) / 10;

  pwm_generator #(
      .PERIOD_CYCLES(FLASH_PERIOD_CYCLES),
      .DUTY_CYCLES  (FLASH_DUTY_CYCLES)
  ) u_flash_pwm (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  assign blank_seconds = mode_enable[0] && !pwm_out;
  assign blank_minutes = mode_enable[1] && !pwm_out;
  assign blank_hours   = mode_enable[2] && !pwm_out;

  // ------------------
  // Display outputs
  // ------------------

  assign hours_disp   = {2'b0, timer_hours};
  assign minutes_disp = {1'b0, timer_minutes};
  assign seconds_disp = {1'b0, timer_seconds};

  // ------------------
  // Unused outputs/inputs
  // ------------------

  assign led = 10'b0;

  logic unused_inputs;
  assign unused_inputs = button[2] | |sw | hours_borrow;

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule
