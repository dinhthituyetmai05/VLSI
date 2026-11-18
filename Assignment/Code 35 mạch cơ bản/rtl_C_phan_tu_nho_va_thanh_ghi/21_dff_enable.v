module dff_enable (
    input  wire clk,
    input  wire rst,
    input  wire en,
    input  wire d,
    output reg  q
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else if (en)
            q <= d;
    end
endmodule
