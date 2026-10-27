`timescale 1ns/1ps
`default_nettype none

module viterbi_acs #(
    parameter METRIC_WIDTH = 5
) (
    input  wire [METRIC_WIDTH-1:0] predecessor_metric_0,
    input  wire [METRIC_WIDTH-1:0] predecessor_metric_1,
    input  wire [1:0] branch_metric_0,
    input  wire [1:0] branch_metric_1,
    output wire [METRIC_WIDTH-1:0] survivor_metric,
    output wire survivor_select
);
    localparam [METRIC_WIDTH-1:0] INFINITY = {METRIC_WIDTH{1'b1}};
    wire [METRIC_WIDTH:0] sum_0;
    wire [METRIC_WIDTH:0] sum_1;
    wire [METRIC_WIDTH-1:0] candidate_0;
    wire [METRIC_WIDTH-1:0] candidate_1;

    assign sum_0 = {1'b0, predecessor_metric_0} + branch_metric_0;
    assign sum_1 = {1'b0, predecessor_metric_1} + branch_metric_1;
    // Saturation preserves unreachable states and prevents metric wraparound.
    assign candidate_0 = (sum_0 >= {1'b0, INFINITY}) ? INFINITY : sum_0[METRIC_WIDTH-1:0];
    assign candidate_1 = (sum_1 >= {1'b0, INFINITY}) ? INFINITY : sum_1[METRIC_WIDTH-1:0];
    // A tie always selects predecessor 0, making simulation reproducible.
    assign survivor_select = (candidate_1 < candidate_0);
    assign survivor_metric = survivor_select ? candidate_1 : candidate_0;
endmodule

`default_nettype wire
