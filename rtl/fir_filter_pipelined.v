`timescale 1ns/1ps
module fir_filter_pipelined #(
    parameter integer DATA_WIDTH  = 16,
    parameter integer COEFF_WIDTH = 20,
    parameter integer ACC_WIDTH   = 56
)(
    input wire clk,
    input wire rst_n,
    input wire sample_valid,
    input wire signed [DATA_WIDTH-1:0] sample_in,
    output reg y_valid,
    output reg signed [DATA_WIDTH-1:0] sample_out
);
    `include "fir_coeffs_q19.vh"
    localparam integer SPLIT1 = 120;
    localparam integer SPLIT2 = 240;
    reg signed [DATA_WIDTH-1:0] x [0:NTAPS-1];
    reg signed [ACC_WIDTH-1:0] part0_r, part1_r, part2_r, sum01_r, sum012_r;
    reg v1, v2, v3;
    integer i;
    reg signed [ACC_WIDTH-1:0] p0, p1, p2;
    function signed [DATA_WIDTH-1:0] sat16;
        input signed [ACC_WIDTH-1:0] v;
        begin
            if (v > 32767) sat16 = 16'sh7fff;
            else if (v < -32768) sat16 = 16'sh8000;
            else sat16 = v[DATA_WIDTH-1:0];
        end
    endfunction
    always @(*) begin
        p0 = 0; p1 = 0; p2 = 0;
        for (i=0; i<SPLIT1; i=i+1) p0 = p0 + x[i] * coeff[i];
        for (i=SPLIT1; i<SPLIT2; i=i+1) p1 = p1 + x[i] * coeff[i];
        for (i=SPLIT2; i<NTAPS; i=i+1) p2 = p2 + x[i] * coeff[i];
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<NTAPS; i=i+1) x[i] <= 0;
            part0_r<=0; part1_r<=0; part2_r<=0; sum01_r<=0; sum012_r<=0;
            v1<=0; v2<=0; v3<=0; y_valid<=0; sample_out<=0;
        end else begin
            if (sample_valid) begin
                for (i=NTAPS-1; i>0; i=i-1) x[i] <= x[i-1];
                x[0] <= sample_in;
            end
            part0_r <= p0; part1_r <= p1; part2_r <= p2;
            sum01_r <= part0_r + part1_r;
            sum012_r <= sum01_r + part2_r;
            sample_out <= sat16((sum012_r + (1 <<< 18)) >>> 19);
            v1 <= sample_valid; v2 <= v1; v3 <= v2; y_valid <= v3;
        end
    end
endmodule
