`timescale 1ns/1ps
module fir_filter_parallel_l3 #(
    parameter integer DATA_WIDTH  = 16,
    parameter integer COEFF_WIDTH = 20,
    parameter integer ACC_WIDTH   = 56
)(
    input wire clk,
    input wire rst_n,
    input wire sample_valid,
    input wire signed [DATA_WIDTH-1:0] x0,
    input wire signed [DATA_WIDTH-1:0] x1,
    input wire signed [DATA_WIDTH-1:0] x2,
    output wire y_valid,
    output wire signed [DATA_WIDTH-1:0] y0,
    output wire signed [DATA_WIDTH-1:0] y1,
    output wire signed [DATA_WIDTH-1:0] y2
);
    wire v0, v1, v2;
    fir_filter_pipelined #(.DATA_WIDTH(DATA_WIDTH), .COEFF_WIDTH(COEFF_WIDTH), .ACC_WIDTH(ACC_WIDTH)) lane0 (.clk(clk), .rst_n(rst_n), .sample_valid(sample_valid), .sample_in(x0), .y_valid(v0), .sample_out(y0));
    fir_filter_pipelined #(.DATA_WIDTH(DATA_WIDTH), .COEFF_WIDTH(COEFF_WIDTH), .ACC_WIDTH(ACC_WIDTH)) lane1 (.clk(clk), .rst_n(rst_n), .sample_valid(sample_valid), .sample_in(x1), .y_valid(v1), .sample_out(y1));
    fir_filter_pipelined #(.DATA_WIDTH(DATA_WIDTH), .COEFF_WIDTH(COEFF_WIDTH), .ACC_WIDTH(ACC_WIDTH)) lane2 (.clk(clk), .rst_n(rst_n), .sample_valid(sample_valid), .sample_in(x2), .y_valid(v2), .sample_out(y2));
    assign y_valid = v0 & v1 & v2;
endmodule
