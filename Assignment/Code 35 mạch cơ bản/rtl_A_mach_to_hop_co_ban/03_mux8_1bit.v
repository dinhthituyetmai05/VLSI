module mux8_1bit (
    input  wire [7:0] d,
    input  wire [2:0] sel,
    output wire       y
);
    assign y = d[sel];
endmodule
