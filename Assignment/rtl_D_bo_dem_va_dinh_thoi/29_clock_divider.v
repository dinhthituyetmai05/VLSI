module clock_divider #(
    // DIVISOR must be even and at least 2.
    parameter integer DIVISOR = 4
) (
    input  wire clk,
    input  wire rst,
    output reg  clk_div
);
    localparam integer HALF_PERIOD = DIVISOR / 2;
    localparam integer COUNT_WIDTH = (HALF_PERIOD <= 1)
                                   ? 1 : $clog2(HALF_PERIOD);
    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count   <= {COUNT_WIDTH{1'b0}};
            clk_div <= 1'b0;
        end else if (count == HALF_PERIOD - 1) begin
            count   <= {COUNT_WIDTH{1'b0}};
            clk_div <= ~clk_div;
        end else begin
            count <= count + 1'b1;
        end
    end
endmodule
