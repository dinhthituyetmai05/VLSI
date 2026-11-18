module alu4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [2:0] op,
    output reg  [3:0] result,
    output wire       zero,
    output reg        carry,
    output reg        borrow,
    output reg        overflow
);
    reg [4:0] arithmetic;
    assign zero = (result == 4'b0000);

    always @(*) begin
        result     = 4'b0000;
        carry      = 1'b0;
        borrow     = 1'b0;
        overflow   = 1'b0;
        arithmetic = 5'b00000;

        case (op)
            3'b000: begin // ADD
                arithmetic = {1'b0, a} + {1'b0, b};
                result = arithmetic[3:0];
                carry = arithmetic[4];
                overflow = (~(a[3] ^ b[3])) & (result[3] ^ a[3]);
            end
            3'b001: begin // SUB
                arithmetic = {1'b0, a} - {1'b0, b};
                result = arithmetic[3:0];
                borrow = arithmetic[4];
                overflow = (a[3] ^ b[3]) & (result[3] ^ a[3]);
            end
            3'b010: result = a & b;
            3'b011: result = a | b;
            3'b100: result = a ^ b;
            3'b101: result = ~a;
            3'b110: begin // Logical left shift by one; ignore b.
                result = {a[2:0], 1'b0};
                carry = a[3];
            end
            3'b111: begin // Logical right shift by one; ignore b.
                result = {1'b0, a[3:1]};
                carry = a[0];
            end
            default: begin
                result = 4'b0000;
            end
        endcase
    end
endmodule
