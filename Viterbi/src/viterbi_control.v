`timescale 1ns/1ps
`default_nettype none

// Frame controller, metric/survivor storage and traceback for the K=3 decoder.
// The BMU, ACS unit and final-state selector remain combinational child modules
// of the structural top. This block supplies their inputs and stores results.
module viterbi_control #(
    parameter MSB_FIRST = 0
) (
    input  wire clk,
    input  wire rstn,
    input  wire viterbi_enable,
    input  wire [15:0] input_data,
    input  wire [19:0] next_metrics,
    input  wire [3:0] survivor_select,
    input  wire [1:0] best_state,
    output wire [1:0] received_symbol,
    output reg [19:0] path_metrics,
    output reg output_done,
    output reg [7:0] output_data
);
    localparam [1:0] IDLE = 2'd0, DECODE = 2'd1,
                     SELECT_FINAL_STATE = 2'd2, TRACEBACK = 2'd3;
    // Each frame starts in state 00; there are no mandatory tail bits.
    // Packed order is {PM11, PM10, PM01, PM00}; 31 denotes infinity.
    localparam [19:0] INITIAL_METRICS = {5'd31, 5'd31, 5'd31, 5'd0};

    reg [1:0] control_state;
    reg [15:0] encoded_shift;
    reg [2:0] symbol_index;
    reg [3:0] survivor_memory [0:7];
    reg [1:0] traceback_state;
    reg [2:0] traceback_index;
    reg [7:0] decoded_work;
    reg [7:0] decoded_next;

    wire predecessor_older_bit = survivor_memory[traceback_index][traceback_state];

    assign received_symbol = MSB_FIRST ? encoded_shift[15:14] : encoded_shift[1:0];

    always @* begin
        decoded_next = decoded_work;
        // A destination state's MSB is the input bit that entered that state.
        if (MSB_FIRST)
            decoded_next[3'd7 - traceback_index] = traceback_state[1];
        else
            decoded_next[traceback_index] = traceback_state[1];
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            control_state <= IDLE;
            encoded_shift <= 16'd0;
            path_metrics <= INITIAL_METRICS;
            symbol_index <= 3'd0;
            traceback_state <= 2'd0;
            traceback_index <= 3'd0;
            decoded_work <= 8'd0;
            output_data <= 8'd0;
            output_done <= 1'b0;
            // Survivor RAM needs no reset: all eight entries are overwritten
            // before any traceback read, including after an aborted frame.
        end else begin
            output_done <= 1'b0;
            case (control_state)
                IDLE: begin
                    // Accept one complete frame only in IDLE.
                    if (viterbi_enable) begin
                        encoded_shift <= input_data;
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
                        output_data <= decoded_next;
                        output_done <= 1'b1;
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
