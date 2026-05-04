`timescale 1ns/1ps
module fir_filter_serial #(
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
    reg signed [DATA_WIDTH-1:0] x [0:NTAPS-1];
    integer i;
    reg signed [ACC_WIDTH-1:0] acc;
    function signed [DATA_WIDTH-1:0] sat16;
        input signed [ACC_WIDTH-1:0] v;
        begin
            if (v > 32767) sat16 = 16'sh7fff;
            else if (v < -32768) sat16 = 16'sh8000;
            else sat16 = v[DATA_WIDTH-1:0];
        end
    endfunction
    always @(*) begin
        acc = 0;
        for (i=0; i<NTAPS; i=i+1) acc = acc + x[i] * coeff[i];
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<NTAPS; i=i+1) x[i] <= 0;
            y_valid <= 0; sample_out <= 0;
        end else begin
            y_valid <= sample_valid;
            if (sample_valid) begin
                for (i=NTAPS-1; i>0; i=i-1) x[i] <= x[i-1];
                x[0] <= sample_in;
                sample_out <= sat16((acc + (1 <<< 18)) >>> 19);
            end
        end
    end
endmodule
