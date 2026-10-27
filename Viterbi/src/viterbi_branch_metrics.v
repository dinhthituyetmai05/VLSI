`timescale 1ns/1ps
`default_nettype none

// Hard-decision Hamming distances, shared by all eight trellis branches.
module viterbi_branch_metrics (
    input  wire [1:0] received_symbol,
    output wire [1:0] distance_00,
    output wire [1:0] distance_01,
    output wire [1:0] distance_10,
    output wire [1:0] distance_11
);
    // Extend before addition: a two-bit symbol can have distance 2.
    assign distance_00 = {1'b0, received_symbol[1]} + {1'b0, received_symbol[0]};
    assign distance_01 = {1'b0, received_symbol[1]} + {1'b0, ~received_symbol[0]};
    assign distance_10 = {1'b0, ~received_symbol[1]} + {1'b0, received_symbol[0]};
    assign distance_11 = {1'b0, ~received_symbol[1]} + {1'b0, ~received_symbol[0]};
endmodule

`default_nettype wire
