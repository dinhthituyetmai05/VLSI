module priority_encoder4to2 (
    input  wire [3:0] d,
    output reg  [1:0] code,
    output wire       valid
);
    assign valid = |d;

    // Highest-index input has the highest priority.
    always @(*) begin
        if      (d[3]) code = 2'd3;
        else if (d[2]) code = 2'd2;
        else if (d[1]) code = 2'd1;
        else           code = 2'd0;
    end
endmodule
