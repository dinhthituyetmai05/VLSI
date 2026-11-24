`timescale 1ns/1ps
`default_nettype none

module tb_viterbi_top;
    reg clk = 0;
    always #2.5 clk = ~clk;
    reg rstn = 0;
    reg viterbi_enable = 0;
    reg [15:0] input_data = 0;
    wire output_done, done_msb;
    wire [7:0] output_data, decoded_msb;
    integer checked = 0;
    integer vector_file, scan_result, received, golden, index;
    string vector_path;

    function automatic [15:0] reverse_pairs(input [15:0] value);
        integer i;
        for (i = 0; i < 8; i = i + 1)
            reverse_pairs[2*i +: 2] = value[14-2*i +: 2];
    endfunction
    function automatic [7:0] reverse_bits(input [7:0] value);
        integer i;
        for (i = 0; i < 8; i = i + 1)
            reverse_bits[i] = value[7-i];
    endfunction
    function automatic [15:0] encode(input [7:0] message);
        reg newest, older;
        integer i;
        begin
            newest = 0;
            older = 0;
            for (i = 0; i < 8; i = i + 1) begin
                encode[2*i+1] = message[i] ^ newest ^ older;
                encode[2*i] = message[i] ^ older;
                older = newest;
                newest = message[i];
            end
        end
    endfunction

    viterbi_top dut (
        .clk(clk), .rstn(rstn), .viterbi_enable(viterbi_enable), .input_data(input_data),
        .output_done(output_done), .output_data(output_data)
    );
    viterbi_top #(.MSB_FIRST(1)) dut_msb (
        .clk(clk), .rstn(rstn), .viterbi_enable(viterbi_enable), .input_data(reverse_pairs(input_data)),
        .output_done(done_msb), .output_data(decoded_msb)
    );

    task automatic check_frame(input [15:0] frame, input [7:0] expected);
        integer cycle;
        reg [7:0] previous_output;
        begin
            @(negedge clk);
            previous_output = output_data;
            viterbi_enable = 1;
            input_data = frame;
            @(posedge clk); #0.1;
            if (output_done !== 0) $fatal(1, "Frame not accepted");
            for (cycle = 1; cycle <= 17; cycle = cycle + 1) begin
                @(negedge clk);
                // Change the bus and attempt a second enable during decoding.
                input_data = ~frame;
                viterbi_enable = (cycle == 3);
                @(posedge clk); #0.1;
                if (done_msb !== output_done)
                    $fatal(1, "Bit-order modes have different timing");
                if (cycle < 17) begin
                    if (output_done !== 0 || output_data !== previous_output)
                        $fatal(1, "Early completion/output change at cycle %0d", cycle);
                end else begin
                    if (output_done !== 1 || output_data !== expected ||
                        decoded_msb !== reverse_bits(expected))
                        $fatal(1, "frame=%04h expected=%02h got=%02h msb=%02h",
                               frame, expected, output_data, decoded_msb);
                end
            end
            @(negedge clk); viterbi_enable = 0;
            @(posedge clk); #0.1;
            if (output_done !== 0 || output_data !== expected ||
                done_msb !== 0 || decoded_msb !== reverse_bits(expected))
                $fatal(1, "output_done must pulse once and result must remain stable");
            checked = checked + 1;
        end
    endtask

    task automatic check_held_enable;
        integer cycle;
        reg [7:0] previous_output, expected_output;
        begin
            @(negedge clk);
            previous_output = output_data;
            input_data = encode(8'h3c);
            viterbi_enable = 1;
            @(posedge clk); #0.1;
            for (cycle = 1; cycle <= 36; cycle = cycle + 1) begin
                @(negedge clk);
                // Hold enable across completion; frame two is accepted at N+18.
                input_data = encode(8'ha5);
                viterbi_enable = (cycle <= 18);
                @(posedge clk); #0.1;
                expected_output = (cycle < 17) ? previous_output :
                                  (cycle < 35) ? 8'h3c : 8'ha5;
                if (output_done !== ((cycle == 17) || (cycle == 35)) ||
                    done_msb !== output_done || output_data !== expected_output ||
                    decoded_msb !== reverse_bits(expected_output))
                    $fatal(1, "Held-enable protocol failed at cycle %0d", cycle);
            end
            checked = checked + 2;
        end
    endtask

    task automatic abort_frame(input integer delay_cycles);
        begin
            @(negedge clk); input_data = 16'hffff; viterbi_enable = 1;
            @(negedge clk); viterbi_enable = 0;
            repeat (delay_cycles) @(negedge clk);
            rstn = 0;
            #0.1;
            if (output_done !== 0 || output_data !== 0 ||
                done_msb !== 0 || decoded_msb !== 0)
                $fatal(1, "Asynchronous active-low reset did not cancel the frame");
            @(negedge clk); rstn = 1;
            repeat (2) begin
                @(posedge clk); #0.1;
                if (output_done !== 0 || done_msb !== 0)
                    $fatal(1, "Aborted frame produced a stale completion");
            end
            check_frame(encode(8'h96), 8'h96);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rstn = 1;
        // PDF's six-bit example, padded with two additional data zeros.
        if (encode(8'h19) !== 16'h35fb) $fatal(1, "Encoder convention mismatch");
        for (index = 0; index < 256; index = index + 1)
            check_frame(encode(index[7:0]), index[7:0]);
        abort_frame(1);
        abort_frame(7);
        abort_frame(8);
        abort_frame(12);
        abort_frame(15);
        check_held_enable();

        if (!$value$plusargs("VECTORS=%s", vector_path))
            $fatal(1, "Supply +VECTORS=<independent oracle file>");
        vector_file = $fopen(vector_path, "r");
        if (!vector_file) $fatal(1, "Cannot open %s", vector_path);
        for (index = 0; index < 65536; index = index + 1) begin
            scan_result = $fscanf(vector_file, "%h %h", received, golden);
            if (scan_result != 2 || received != index || golden < 0 || golden > 255)
                $fatal(1, "Missing/invalid oracle vector %0d", index);
            check_frame(received[15:0], golden[7:0]);
        end
        scan_result = $fscanf(vector_file, "%h", received);
        if (scan_result == 1) $fatal(1, "Unexpected extra oracle vector");
        $fclose(vector_file);
        $display("PASS: %0d frames in BOTH bit-order modes; all 65536 received words", checked);
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1, "Simulation watchdog expired");
    end
endmodule

`default_nettype wire
