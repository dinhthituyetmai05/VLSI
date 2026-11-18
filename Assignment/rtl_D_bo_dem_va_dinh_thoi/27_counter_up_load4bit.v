module counter_up_load4bit (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,
    input  wire       en,
    input  wire [3:0] load_data,
    output reg  [3:0] q
);
    // Priority: asynchronous reset > synchronous load > count enable.
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 4'd0;
        else if (load)
            q <= load_data;
        else if (en)
            q <= q + 4'd1;
    end
endmodule
