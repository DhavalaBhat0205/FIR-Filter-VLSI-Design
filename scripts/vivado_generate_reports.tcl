# Vivado batch synthesis script for FIR filter project
# Run from repository root:
# vivado -mode batch -source scripts/vivado_generate_reports.tcl

set_part xc7a200tfbg484-1
read_verilog rtl/fir_filter_pipelined.v
read_verilog rtl/fir_filter_serial.v
read_verilog rtl/fir_filter_parallel_l3.v
read_xdc scripts/timing_constraints.xdc
synth_design -top fir_filter_pipelined -part xc7a200tfbg484-1
opt_design
place_design
route_design
file mkdir results/synthesis_reports/vivado
report_utilization -file results/synthesis_reports/vivado/vivado_utilization_report.rpt
report_timing_summary -file results/synthesis_reports/vivado/vivado_timing_summary_report.rpt
report_power -file results/synthesis_reports/vivado/vivado_power_report.rpt
write_checkpoint -force results/synthesis_reports/vivado/fir_filter_pipelined_post_route.dcp
write_verilog -force results/synthesis_reports/vivado/fir_filter_pipelined_post_synth_netlist.v
