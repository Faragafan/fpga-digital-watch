`timescale 1ns / 1ps

module up_down_counter #(
    parameter int MAX = 2,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic enable,
    input logic up,
    output logic [WIDTH-1:0] count = '0
);

  localparam logic [WIDTH-1:0] Max = WIDTH'(MAX);
  localparam logic [WIDTH-1:0] One = WIDTH'(1);

  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk)
    if (enable) count <= next_count;

  always_comb begin
    if (up) begin
      if (count == Max) next_count = '0;
      else next_count = count + One;
    end else begin
      if (count == '0) next_count = Max;
      else next_count = count - One;
    end
  end

endmodule
