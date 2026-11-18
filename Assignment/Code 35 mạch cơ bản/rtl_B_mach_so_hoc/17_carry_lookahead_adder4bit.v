module carry_lookahead_adder4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire [3:0] p;
    wire [3:0] g;
    wire [4:0] c;

    assign p = a ^ b;
    assign g = a & b;
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0])
                | (p[1] & p[0] & cin);
    assign c[3] = g[2] | (p[2] & g[1])
                | (p[2] & p[1] & g[0])
                | (p[2] & p[1] & p[0] & cin);
    assign c[4] = g[3] | (p[3] & g[2])
                | (p[3] & p[2] & g[1])
                | (p[3] & p[2] & p[1] & g[0])
                | (p[3] & p[2] & p[1] & p[0] & cin);
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule
