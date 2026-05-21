`timescale 1ns / 1ps

module stopwatch_control (
    input logic clk,
    input logic rise_start_stop,
    input logic rise_lap,
    output logic counter_rst = 1'b0,
    output logic counter_enable = 1'b0,
    output logic lap_hold = 1'b0
);

  logic next_counter_rst;
  logic next_counter_enable;
  logic next_lap_hold;

  logic both_pressed;
  assign both_pressed = rise_start_stop && rise_lap;

  // Reset pulse is generated only when stopped, live, and lap is pressed.
  assign next_counter_rst =
      (!both_pressed && rise_lap && !counter_enable && !lap_hold);

  // Start/stop toggles running state, unless both buttons are pressed.
  assign next_counter_enable =
      (!both_pressed && rise_start_stop) ? !counter_enable : counter_enable;

  // Lap/freeze logic.
  always_comb begin
    next_lap_hold = lap_hold;

    if (both_pressed) begin
      next_lap_hold = lap_hold;
    end else if (rise_lap) begin
      if (counter_enable) begin
        // Running: lap toggles live/frozen display.
        next_lap_hold = !lap_hold;
      end else begin
        // Stopped:
        // frozen -> live
        // live -> reset, still live
        next_lap_hold = 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    counter_rst    <= next_counter_rst;
    counter_enable <= next_counter_enable;
    lap_hold       <= next_lap_hold;
  end

endmodule
