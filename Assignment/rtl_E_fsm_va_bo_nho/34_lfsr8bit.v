module lfsr8bit #(
    parameter [7:0] SEED = 8'h01
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    output reg  [7:0] q
);
    // Polynomial x^8 + x^6 + x^5 + x^4 + 1.
    // Replace an all-zero reset seed with 1 to avoid the locked state.
    localparam [7:0] RESET_SEED = (SEED == 8'h00) ? 8'h01 : SEED;
    wire feedback;
    assign feedback = q[7] ^ q[5] ^ q[4] ^ q[3];

    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= RESET_SEED;
        else if (en)
            q <= {q[6:0], feedback};
    end
endmodule
