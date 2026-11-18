module bcd_counter_00_59 (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    output reg  [3:0] tens,
    output reg  [3:0] ones,
    output reg        minute_tick
);
    // Feed a one-clock-wide 1 Hz tick to en to count seconds.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tens        <= 4'd0;
            ones        <= 4'd0;
            minute_tick <= 1'b0;
        end else begin
            minute_tick <= 1'b0;
            if (en) begin
                if (ones == 4'd9) begin
                    ones <= 4'd0;
                    if (tens == 4'd5) begin
                        tens        <= 4'd0;
                        minute_tick <= 1'b1;
                    end else begin
                        tens <= tens + 4'd1;
                    end
                end else begin
                    ones <= ones + 4'd1;
                end
            end
        end
    end
endmodule
