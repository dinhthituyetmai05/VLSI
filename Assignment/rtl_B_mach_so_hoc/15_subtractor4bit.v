module subtractor4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       bin,
    output wire [3:0] diff,
    output wire       bout
);
    wire [4:0] extended_diff;
    // Unsigned subtraction with active-high borrow-in/borrow-out.
    assign extended_diff = {1'b0, a} - {1'b0, b} - {4'b0000, bin};
    assign diff = extended_diff[3:0];
    assign bout = extended_diff[4];
endmodule
