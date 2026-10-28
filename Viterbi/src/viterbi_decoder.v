`timescale 1ns/1ps
`default_nettype none

// Structural top: K=3, rate=1/2, generators (7,5) octal.
// All state, storage and frame sequencing are owned by viterbi_control.
module viterbi_decoder #(
    // 0 matches the PDF example: first symbol is encoded_data[1:0],
    // and the first recovered information bit becomes decoded_data[0].
    // 1 processes encoded_data[15:14] first and writes decoded_data[7] first.
    parameter MSB_FIRST = 0
) (
    input  wire clk,
    input  wire reset,
    input  wire start,
    input  wire [15:0] encoded_data,
    output wire busy,
    output wire done,
    output wire [7:0] decoded_data
);
    wire [1:0] received_symbol;
    wire [19:0] path_metrics;
    wire [1:0] distance_00, distance_01, distance_10, distance_11;
    wire [19:0] next_metrics;
    wire [3:0] survivor_select;
    wire [1:0] best_state;

    viterbi_control #(.MSB_FIRST(MSB_FIRST)) control (
        .clk(clk), .reset(reset), .start(start), .encoded_data(encoded_data),
        .next_metrics(next_metrics), .survivor_select(survivor_select),
        .best_state(best_state), .received_symbol(received_symbol),
        .path_metrics(path_metrics), .busy(busy), .done(done),
        .decoded_data(decoded_data)
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
