module d_latch (
    input  wire d,
    input  wire en,
    output reg  q
);
    // Intentional active-high transparent latch; no reset.
    always @(*) begin
        if (en)
            q <= d;
    end
endmodule
