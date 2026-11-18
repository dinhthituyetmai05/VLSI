`timescale 1ns/1ps
`default_nettype none

// Run from the project root. Files contain one binary word per nonblank line.
// output.txt: 16 encoded bits; input.txt: 8 expected information bits.
module tb_viterbi_files;
    parameter MSB_FIRST = 0;
    reg clk = 0;
    always #2.5 clk = ~clk;
    reg reset = 1, start = 0;
    reg [15:0] encoded_data = 0;
    wire busy, done;
    wire [7:0] decoded_data;
    integer encoded_file, expected_file, encoded_status, expected_status;
    integer count = 0, cycle;
    reg [7:0] expected_data;
    string encoded_path, expected_path, encoded_word, expected_word;

    viterbi_decoder #(.MSB_FIRST(MSB_FIRST)) dut (
        .clk(clk), .reset(reset), .start(start), .encoded_data(encoded_data),
        .busy(busy), .done(done), .decoded_data(decoded_data)
    );

    function automatic bit valid_binary(input string word, input integer width);
        integer i;
        begin
            valid_binary = (word.len() == width);
            for (i = 0; i < word.len(); i = i + 1)
                if (word[i] != 8'h30 && word[i] != 8'h31)
                    valid_binary = 0;
        end
    endfunction

    initial begin
        if (!$value$plusargs("ENCODED=%s", encoded_path)) encoded_path = "output.txt";
        if (!$value$plusargs("EXPECTED=%s", expected_path)) expected_path = "input.txt";
        encoded_file = $fopen(encoded_path, "r");
        expected_file = $fopen(expected_path, "r");
        if (!encoded_file || !expected_file) $fatal(1, "Cannot open input/output vector files");
        repeat (2) @(negedge clk);
        reset = 0;
        forever begin
            encoded_status = $fscanf(encoded_file, "%s", encoded_word);
            expected_status = $fscanf(expected_file, "%s", expected_word);
            if (encoded_status != 1 || expected_status != 1) begin
                if (encoded_status == 1 || expected_status == 1)
                    $fatal(1, "Vector files have different lengths");
                if (count == 0) $fatal(1, "Vector files are empty");
                $display("PASS: %0d file vectors", count);
                $fclose(encoded_file);
                $fclose(expected_file);
                $finish;
            end
            if (!valid_binary(encoded_word, 16) || !valid_binary(expected_word, 8))
                $fatal(1, "Invalid binary vector at row %0d", count + 1);
            @(negedge clk);
            encoded_status = $sscanf(encoded_word, "%b", encoded_data);
            expected_status = $sscanf(expected_word, "%b", expected_data);
            start = 1;
            @(negedge clk); start = 0;
            for (cycle = 0; cycle < 17; cycle = cycle + 1) begin
                @(posedge clk); #0.1;
                if (cycle < 16 && done !== 0) $fatal(1, "Early done");
            end
            if (done !== 1 || busy !== 0 || decoded_data !== expected_data)
                $fatal(1, "row=%0d encoded=%b expected=%b got=%b",
                       count + 1, encoded_data, expected_data, decoded_data);
            count = count + 1;
        end
    end
endmodule

`default_nettype wire
