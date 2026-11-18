module sequence_detector_1011 (
    input  wire clk,
    input  wire rst,
    input  wire serial_in,
    output reg  detected
);
    localparam [1:0] S0 = 2'd0, S1 = 2'd1,
                     S10 = 2'd2, S101 = 2'd3;
    reg [1:0] state;

    // Registered Mealy output; overlapping occurrences are allowed.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= S0;
            detected <= 1'b0;
        end else begin
            detected <= 1'b0;
            case (state)
                S0:   state <= serial_in ? S1 : S0;
                S1:   state <= serial_in ? S1 : S10;
                S10:  state <= serial_in ? S101 : S0;
                S101: begin
                    if (serial_in) begin
                        state    <= S1;
                        detected <= 1'b1;
                    end else begin
                        state <= S10;
                    end
                end
                default: state <= S0;
            endcase
        end
    end
endmodule
