module shift_register_sipo8bit (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire       serial_in,
    output reg  [7:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 8'b00000000;
        else if (en)
            q <= {q[6:0], serial_in};
    end
endmodule
