`timescale 1ns / 1ps

module cascade_counter #(
    parameter int N2 = 3,
    parameter int N1 = 4,
    parameter int N0 = 5,

    // Output port widths
    parameter int W2 = 2,
    parameter int W1 = 2,
    parameter int W0 = 3
) (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [W2-1:0] count2,
    output logic [W1-1:0] count1,
    output logic [W0-1:0] count0
);

  localparam logic [W0-1:0] Max0 = W0'(N0 - 1);
  localparam logic [W1-1:0] Max1 = W1'(N1 - 1);

  logic enable0;
  logic enable1;
  logic enable2;

  assign enable0 = enable;
  assign enable1 = enable && (count0 == Max0);
  assign enable2 = enable && (count0 == Max0) && (count1 == Max1);

  mod_n_counter #(
      .N(N0),
      .WIDTH(W0)
  ) u_count0 (
      .clk(clk),
      .rst(rst),
      .enable(enable0),
      .count(count0)
  );

  mod_n_counter #(
      .N(N1),
      .WIDTH(W1)
  ) u_count1 (
      .clk(clk),
      .rst(rst),
      .enable(enable1),
      .count(count1)
  );

  mod_n_counter #(
      .N(N2),
      .WIDTH(W2)
  ) u_count2 (
      .clk(clk),
      .rst(rst),
      .enable(enable2),
      .count(count2)
  );

endmodule
