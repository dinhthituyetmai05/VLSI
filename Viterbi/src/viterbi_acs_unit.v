`timescale 1ns/1ps
`default_nettype none

// Fixed K=3, generators (7,5) octal. State = {newest_bit, older_bit}.
// Packed metric order from MSB to LSB is {state_11, state_10, state_01, state_00}.
module viterbi_acs_unit (
    input  wire [19:0] current_metrics,
    input  wire [1:0] distance_00,
    input  wire [1:0] distance_01,
    input  wire [1:0] distance_10,
    input  wire [1:0] distance_11,
    output wire [19:0] next_metrics,
    output wire [3:0] survivor_select
);
    // For destination {u,a}, predecessor candidates are {a,0} and {a,1}.
    // survivor_select therefore records the older bit of the predecessor.
    viterbi_acs state_00 (
        .predecessor_metric_0(current_metrics[4:0]),
        .predecessor_metric_1(current_metrics[9:5]),
        .branch_metric_0(distance_00), .branch_metric_1(distance_11),
        .survivor_metric(next_metrics[4:0]), .survivor_select(survivor_select[0])
    );
    viterbi_acs state_01 (
        .predecessor_metric_0(current_metrics[14:10]),
        .predecessor_metric_1(current_metrics[19:15]),
        .branch_metric_0(distance_10), .branch_metric_1(distance_01),
        .survivor_metric(next_metrics[9:5]), .survivor_select(survivor_select[1])
    );
    viterbi_acs state_10 (
        .predecessor_metric_0(current_metrics[4:0]),
        .predecessor_metric_1(current_metrics[9:5]),
        .branch_metric_0(distance_11), .branch_metric_1(distance_00),
        .survivor_metric(next_metrics[14:10]), .survivor_select(survivor_select[2])
    );
    viterbi_acs state_11 (
        .predecessor_metric_0(current_metrics[14:10]),
        .predecessor_metric_1(current_metrics[19:15]),
        .branch_metric_0(distance_01), .branch_metric_1(distance_10),
        .survivor_metric(next_metrics[19:15]), .survivor_select(survivor_select[3])
    );
endmodule

`default_nettype wire
