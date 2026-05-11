`timescale 1ns / 1ps

module key_synchroniser (
    input logic clk,
    input logic [3:0] key_n,  // active -low , asynchronous
    output logic [3:0] key_sync = 'b0000  // active -high , synchronised
);

logic [3:0] key_stage1 = 'b0000;  // First stage of synchronisation

always_ff @(posedge clk) begin
    key_stage1 <= ~key_n;  // Invert and synchronise the key inputs
    key_sync <= key_stage1;  // Second stage of synchronisation to prevent metastability
end
endmodule
