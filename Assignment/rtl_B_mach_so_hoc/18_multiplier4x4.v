module multiplier4x4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] product
);
    // Unsigned 4 x 4 multiplication; preserve the full 8-bit result.
    assign product = a * b;
endmodule
