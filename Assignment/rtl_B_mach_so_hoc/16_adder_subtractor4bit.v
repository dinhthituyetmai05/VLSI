module adder_subtractor4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       sub,
    output wire [3:0] result,
    output wire       carry,
    output wire       borrow
);
    wire [3:0] b_modified;
    wire [4:0] extended_sum;
    // sub = 0: a + b; sub = 1: a + ~b + 1.
    assign b_modified = b ^ {4{sub}};
    assign extended_sum = {1'b0, a} + {1'b0, b_modified}
                        + {4'b0000, sub};
    assign result = extended_sum[3:0];
    assign carry  = (~sub) & extended_sum[4];
    assign borrow = sub & (~extended_sum[4]);
endmodule
