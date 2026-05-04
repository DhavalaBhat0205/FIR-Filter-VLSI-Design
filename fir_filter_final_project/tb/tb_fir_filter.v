`timescale 1ns/1ps
module tb_fir_filter;
    reg clk = 0;
    reg rst_n = 0;
    reg sample_valid = 0;
    reg signed [15:0] sample_in = 0;
    wire y_valid;
    wire signed [15:0] sample_out;
    integer n;

    always #5 clk = ~clk;

    fir_filter_serial dut (
        .clk(clk), .rst_n(rst_n), .sample_valid(sample_valid), .sample_in(sample_in),
        .y_valid(y_valid), .sample_out(sample_out)
    );

    initial begin
        $dumpfile("fir_filter.vcd");
        $dumpvars(0, tb_fir_filter);
        repeat(5) @(posedge clk);
        rst_n = 1;
        // impulse input: first sample is 1.0 in Q1.15, followed by zeros
        for (n = 0; n < 500; n = n + 1) begin
            @(posedge clk);
            sample_valid <= 1'b1;
            if (n == 0) sample_in <= 16'sh7fff;
            else        sample_in <= 16'sh0000;
        end
        @(posedge clk); sample_valid <= 1'b0;
        repeat(20) @(posedge clk);
        $finish;
    end
endmodule
