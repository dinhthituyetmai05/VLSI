module traffic_light_fsm #(
    // Durations in tick events; each parameter must be at least 1.
    parameter integer GREEN_TICKS   = 10,
    parameter integer YELLOW_TICKS  = 3,
    parameter integer ALL_RED_TICKS = 1
) (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    output reg  ns_red,
    output reg  ns_yellow,
    output reg  ns_green,
    output reg  ew_red,
    output reg  ew_yellow,
    output reg  ew_green
);
    localparam [2:0] NS_GREEN = 3'd0, NS_YELLOW = 3'd1,
                     ALL_RED_TO_EW = 3'd2, EW_GREEN = 3'd3,
                     EW_YELLOW = 3'd4, ALL_RED_TO_NS = 3'd5;
    localparam integer MAX_GY = (GREEN_TICKS > YELLOW_TICKS)
                              ? GREEN_TICKS : YELLOW_TICKS;
    localparam integer MAX_TICKS = (MAX_GY > ALL_RED_TICKS)
                                 ? MAX_GY : ALL_RED_TICKS;
    localparam integer COUNT_WIDTH = (MAX_TICKS <= 1)
                                   ? 1 : $clog2(MAX_TICKS);
    reg [2:0] state;
    reg [2:0] next_state;
    reg [COUNT_WIDTH-1:0] count;
    integer duration;

    always @(*) begin
        // Safe default: both directions red.
        ns_red = 1'b1;
        ns_yellow = 1'b0;
        ns_green = 1'b0;
        ew_red = 1'b1;
        ew_yellow = 1'b0;
        ew_green = 1'b0;
        duration = ALL_RED_TICKS;
        next_state = ALL_RED_TO_NS;
        case (state)
            NS_GREEN: begin
                ns_red = 1'b0;
                ns_green = 1'b1;
                duration = GREEN_TICKS;
                next_state = NS_YELLOW;
            end
            NS_YELLOW: begin
                ns_red = 1'b0;
                ns_yellow = 1'b1;
                duration = YELLOW_TICKS;
                next_state = ALL_RED_TO_EW;
            end
            ALL_RED_TO_EW: next_state = EW_GREEN;
            EW_GREEN: begin
                ew_red = 1'b0;
                ew_green = 1'b1;
                duration = GREEN_TICKS;
                next_state = EW_YELLOW;
            end
            EW_YELLOW: begin
                ew_red = 1'b0;
                ew_yellow = 1'b1;
                duration = YELLOW_TICKS;
                next_state = ALL_RED_TO_NS;
            end
            ALL_RED_TO_NS: next_state = NS_GREEN;
            default: begin
                next_state = ALL_RED_TO_NS;
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ALL_RED_TO_NS;
            count <= {COUNT_WIDTH{1'b0}};
        end else if (tick) begin
            if (count == duration - 1) begin
                state <= next_state;
                count <= {COUNT_WIDTH{1'b0}};
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
