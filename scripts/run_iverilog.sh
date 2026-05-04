#!/usr/bin/env bash
set -e
mkdir -p build
iverilog -g2012 -I rtl -o build/tb_fir_filter tb/tb_fir_filter.v rtl/fir_filter_serial.v
vvp build/tb_fir_filter
