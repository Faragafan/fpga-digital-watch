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

module user_top_brightness_wrapper #(
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
  // Wrapped user design
  // ------------------

  logic app_blank_hours;
  logic app_blank_minutes;
  logic app_blank_seconds;

  user_top #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_user_top (
      .clk(clk),
      .button(button),
      .sw(sw),
      .led(led),
      .hours_disp(hours_disp),
      .minutes_disp(minutes_disp),
      .seconds_disp(seconds_disp),
      .blank_hours(app_blank_hours),
      .blank_minutes(app_blank_minutes),
      .blank_seconds(app_blank_seconds)
  );

  // ------------------
  // Brightness PWM
  // ------------------

  localparam int PWM_PERIOD_CYCLES = CYCLES_PER_SECOND / 1000;
  localparam int PWM_WIDTH = $clog2(PWM_PERIOD_CYCLES);

  logic [PWM_WIDTH-1:0] pwm_count;

  mod_n_counter #(
      .N(PWM_PERIOD_CYCLES),
      .WIDTH(PWM_WIDTH)
  ) u_pwm_counter (
      .clk(clk),
      .rst(1'b0),
      .enable(1'b1),
      .count(pwm_count)
  );

  logic [PWM_WIDTH-1:0] duty_limit;
  logic brightness_on;

logic [1:0] brightness_sel;

assign brightness_sel = sw[9:8];

always_comb begin
  case (brightness_sel)
    2'b00: duty_limit = PWM_WIDTH'(PWM_PERIOD_CYCLES / 8);
    2'b01: duty_limit = PWM_WIDTH'(PWM_PERIOD_CYCLES / 4);
    2'b11: duty_limit = PWM_WIDTH'(PWM_PERIOD_CYCLES / 2);
    2'b10: duty_limit = '0;
  endcase
end

assign brightness_on = (brightness_sel == 2'b10) || (pwm_count < duty_limit);

  // ------------------
  // Intercept blanking
  // ------------------

  assign blank_hours   = app_blank_hours   || !brightness_on;
  assign blank_minutes = app_blank_minutes || !brightness_on;
  assign blank_seconds = app_blank_seconds || !brightness_on;

endmodule
