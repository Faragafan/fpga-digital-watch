`timescale 1ns / 1ps

module rising_edge_detector (
    input  logic clk,
    input  logic sig_in,
    output logic rise
);

  logic sig_in_d;

  always_ff @(posedge clk) begin
    sig_in_d <= sig_in;
  end

  assign rise = sig_in && !sig_in_d;
endmodule
