# Vivado synthesis script template
create_project fir_filter_project ./vivado_build -part xc7a35tcpg236-1 -force
add_files [glob ./rtl/*.v]
set_property include_dirs ./rtl [current_fileset]
set_property top fir_filter_pipelined [current_fileset]
read_xdc ./scripts/timing_constraints.xdc
synth_design -top fir_filter_pipelined -part xc7a35tcpg236-1
report_utilization -file ./results/vivado_utilization.rpt
report_timing_summary -file ./results/vivado_timing_summary.rpt
report_power -file ./results/vivado_power.rpt
write_checkpoint -force ./results/fir_filter_pipelined_synth.dcp
