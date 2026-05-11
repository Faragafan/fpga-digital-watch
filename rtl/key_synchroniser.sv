`timescale 1ns / 1ps

module key_synchroniser (
    input logic clk,
    input logic [3:0] key_n,  // active -low , asynchronous
    output logic [3:0] key_sync  // active -high , synchronised
);
endmodule
