module decoder2to4 (
    input  wire [1:0] a,
    output wire [3:0] y
);
    // Active-high one-hot output; no enable input.
    assign y = 4'b0001 << a;
endmodule
