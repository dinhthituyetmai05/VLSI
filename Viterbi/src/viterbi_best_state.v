`timescale 1ns/1ps
`default_nettype none

module viterbi_best_state (
    input  wire [19:0] path_metrics,
    output wire [1:0] best_state
);
    wire select_01 = (path_metrics[9:5] < path_metrics[4:0]);
    wire select_11 = (path_metrics[19:15] < path_metrics[14:10]);
    wire [4:0] minimum_01 = select_01 ? path_metrics[9:5] : path_metrics[4:0];
    wire [4:0] minimum_23 = select_11 ? path_metrics[19:15] : path_metrics[14:10];

    // Balanced comparator tree; equal metrics select the lower state number.
    assign best_state = (minimum_23 < minimum_01)
                      ? {1'b1, select_11} : {1'b0, select_01};
endmodule

`default_nettype wire
