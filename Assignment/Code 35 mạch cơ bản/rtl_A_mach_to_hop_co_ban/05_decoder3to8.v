module decoder3to8 (
    input  wire [2:0] a,
    output wire [7:0] y
);
    // Active-high one-hot output; no enable input.
    assign y = 8'b00000001 << a;
endmodule
