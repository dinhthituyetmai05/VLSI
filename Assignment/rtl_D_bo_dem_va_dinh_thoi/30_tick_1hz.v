module tick_1hz #(
    // Must equal the actual input-clock frequency in Hz; at least 1.
    parameter integer CLK_FREQ_HZ = 50000000
) (
    input  wire clk,
    input  wire rst,
    output reg  tick
);
    localparam integer COUNT_WIDTH = (CLK_FREQ_HZ <= 1)
                                   ? 1 : $clog2(CLK_FREQ_HZ);
    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {COUNT_WIDTH{1'b0}};
            tick  <= 1'b0;
        end else begin
            tick <= 1'b0;
            if (count == CLK_FREQ_HZ - 1) begin
                count <= {COUNT_WIDTH{1'b0}};
                tick  <= 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
