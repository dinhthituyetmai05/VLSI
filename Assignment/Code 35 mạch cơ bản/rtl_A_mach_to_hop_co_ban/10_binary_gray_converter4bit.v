module binary_gray_converter4bit (
    input  wire [3:0] din,
    input  wire       mode,
    output wire [3:0] dout
);
    wire [3:0] binary_to_gray;
    wire [3:0] gray_to_binary;

    assign binary_to_gray = din ^ (din >> 1);
    assign gray_to_binary[3] = din[3];
    assign gray_to_binary[2] = ^din[3:2];
    assign gray_to_binary[1] = ^din[3:1];
    assign gray_to_binary[0] = ^din[3:0];

    // 0: Binary to Gray; 1: Gray to Binary.
    assign dout = mode ? gray_to_binary : binary_to_gray;
endmodule
