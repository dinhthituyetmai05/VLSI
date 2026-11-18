module barrel_rotator8bit (
    input  wire [7:0] din,
    input  wire [2:0] shamt,
    input  wire       dir,
    output wire [7:0] dout
);
    wire [7:0] stage1;
    wire [7:0] stage2;
    wire [7:0] stage4;

    // dir = 0: rotate left; dir = 1: rotate right.
    // Three mux stages rotate by 1, 2, and 4 positions.
    assign stage1 = shamt[0]
                  ? (dir ? {din[0], din[7:1]} : {din[6:0], din[7]})
                  : din;

    assign stage2 = shamt[1]
                  ? (dir ? {stage1[1:0], stage1[7:2]}
                         : {stage1[5:0], stage1[7:6]})
                  : stage1;

    // For 8 bits, a rotation by 4 is identical in both directions.
    assign stage4 = shamt[2] ? {stage2[3:0], stage2[7:4]} : stage2;

    assign dout = stage4;
endmodule
