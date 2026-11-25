`timescale 1ns/1ps
`default_nettype none

// Structural top: K=3, rate=1/2, generators (7,5) octal.
// All state, storage and frame sequencing are owned by viterbi_control.
// Symbols are read from input_data[15:14] down to input_data[1:0].
// The first recovered information bit is stored in output_data[7].
module viterbi_top (
    input  wire clk,
    input  wire rstn,
    input  wire viterbi_enable,
    input  wire [15:0] input_data,
    output wire [7:0] output_data,
    output wire output_done
);
    wire [1:0] received_symbol;
    wire [19:0] path_metrics;
    wire [1:0] distance_00, distance_01, distance_10, distance_11;
    wire [19:0] next_metrics;
    wire [3:0] survivor_select;
    wire [1:0] best_state;

    viterbi_control control (
        .clk(clk), .rstn(rstn), .viterbi_enable(viterbi_enable), .input_data(input_data),
        .next_metrics(next_metrics), .survivor_select(survivor_select),
        .best_state(best_state), .received_symbol(received_symbol),
        .path_metrics(path_metrics), .output_done(output_done),
        .output_data(output_data)
    );

    viterbi_branch_metrics branch_metrics (
        .received_symbol(received_symbol),
        .distance_00(distance_00), .distance_01(distance_01),
        .distance_10(distance_10), .distance_11(distance_11)
    );
    viterbi_acs_unit acs_unit (
        .current_metrics(path_metrics),
        .distance_00(distance_00), .distance_01(distance_01),
        .distance_10(distance_10), .distance_11(distance_11),
        .next_metrics(next_metrics), .survivor_select(survivor_select)
    );
    viterbi_best_state final_state_selector (
        .path_metrics(path_metrics), .best_state(best_state)
    );

endmodule

`default_nettype wire
