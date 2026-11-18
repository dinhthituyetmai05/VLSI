module counter_up_down4bit (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire       up,
    output reg  [3:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 4'd0;
        else if (en) begin
            if (up)
                q <= q + 4'd1;
            else
                q <= q - 4'd1;
        end
    end
endmodule
