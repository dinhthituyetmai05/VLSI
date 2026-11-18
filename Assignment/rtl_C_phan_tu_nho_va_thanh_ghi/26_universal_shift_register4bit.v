module universal_shift_register4bit (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] mode,
    input  wire       serial_in,
    input  wire [3:0] parallel_in,
    output reg  [3:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 4'b0000;
        else begin
            case (mode)
                2'b00: q <= q;
                2'b01: q <= {serial_in, q[3:1]};
                2'b10: q <= {q[2:0], serial_in};
                2'b11: q <= parallel_in;
                default: q <= q;
            endcase
        end
    end
endmodule
