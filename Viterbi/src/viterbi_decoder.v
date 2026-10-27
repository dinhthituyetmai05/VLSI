`timescale 1ns/1ps
`default_nettype none

// Eight-bit block decoder: K=3, rate=1/2, generators (7,5) octal.
// Each frame starts in state 00; the final state is unrestricted (no tail bits).
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
    output reg done,
    output reg [7:0] decoded_data
);
    localparam [1:0] IDLE = 2'd0, DECODE = 2'd1,
                     SELECT_FINAL_STATE = 2'd2, TRACEBACK = 2'd3;
    // Eight branches * maximum distance 2 = 16; 31 denotes infinity.
    localparam [19:0] INITIAL_METRICS = {5'd31, 5'd31, 5'd31, 5'd0};

    reg [1:0] control_state;
    reg [15:0] encoded_shift;
    reg [19:0] path_metrics;
    reg [2:0] symbol_index;
    reg [3:0] survivor_memory [0:7];
    reg [1:0] traceback_state;
    reg [2:0] traceback_index;
    reg [7:0] decoded_work;
    reg [7:0] decoded_next;

    wire [1:0] received_symbol = MSB_FIRST ? encoded_shift[15:14] : encoded_shift[1:0];
    wire [1:0] distance_00, distance_01, distance_10, distance_11;
    wire [19:0] next_metrics;
    wire [3:0] survivor_select;
    wire [1:0] best_state;
    wire predecessor_older_bit = survivor_memory[traceback_index][traceback_state];

    assign busy = (control_state != IDLE);

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

    always @* begin
        decoded_next = decoded_work;
        // A destination state's MSB is the input bit that entered that state.
        if (MSB_FIRST)
            decoded_next[3'd7 - traceback_index] = traceback_state[1];
        else
            decoded_next[traceback_index] = traceback_state[1];
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            control_state <= IDLE;
            encoded_shift <= 16'd0;
            path_metrics <= INITIAL_METRICS;
            symbol_index <= 3'd0;
            traceback_state <= 2'd0;
            traceback_index <= 3'd0;
            decoded_work <= 8'd0;
            decoded_data <= 8'd0;
            done <= 1'b0;
            // Survivor RAM needs no reset: all eight entries are overwritten
            // before any traceback read, including after an aborted frame.
        end else begin
            done <= 1'b0;
            case (control_state)
                IDLE: begin
                    // Accept one complete frame only when busy is low.
                    if (start) begin
                        encoded_shift <= encoded_data;
                        path_metrics <= INITIAL_METRICS;
                        symbol_index <= 3'd0;
                        decoded_work <= 8'd0;
                        control_state <= DECODE;
                    end
                end
                DECODE: begin
                    path_metrics <= next_metrics;
                    survivor_memory[symbol_index] <= survivor_select;
                    encoded_shift <= MSB_FIRST ? {encoded_shift[13:0], 2'b00}
                                               : {2'b00, encoded_shift[15:2]};
                    if (symbol_index == 3'd7)
                        control_state <= SELECT_FINAL_STATE;
                    else
                        symbol_index <= symbol_index + 3'd1;
                end
                SELECT_FINAL_STATE: begin
                    // Select after the eighth metric update has been registered.
                    traceback_state <= best_state;
                    traceback_index <= 3'd7;
                    control_state <= TRACEBACK;
                end
                TRACEBACK: begin
                    decoded_work <= decoded_next;
                    traceback_state <= {traceback_state[0], predecessor_older_bit};
                    if (traceback_index == 3'd0) begin
                        decoded_data <= decoded_next;
                        done <= 1'b1;
                        control_state <= IDLE;
                    end else begin
                        traceback_index <= traceback_index - 3'd1;
                    end
                end
                default: control_state <= IDLE;
            endcase
        end
    end
endmodule

`default_nettype wire
