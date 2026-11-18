module sync_ram16x8 (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire       we,
    input  wire [3:0] addr,
    input  wire [7:0] wdata,
    output reg  [7:0] rdata
);
    reg [7:0] mem [0:15];

    // Synchronous reset affects rdata only; memory is not initialized.
    // Read-first behavior: simultaneous read/write returns the old word.
    always @(posedge clk) begin
        if (rst) begin
            rdata <= 8'h00;
        end else if (en) begin
            rdata <= mem[addr];
            if (we)
                mem[addr] <= wdata;
        end
    end
endmodule
