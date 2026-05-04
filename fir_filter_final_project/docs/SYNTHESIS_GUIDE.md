# Synthesis Guide

Use this guide to collect the implementation results required in the final project grading.

## Top Modules

| Top module | Purpose |
|---|---|
| `fir_filter_serial` | Baseline direct-form implementation |
| `fir_filter_pipelined` | Pipelined design for higher clock frequency |
| `fir_filter_parallel_l3` | L=3 parallel-processing design for higher throughput |

## Vivado Flow

Run this from the repository root:

```tcl
source scripts/vivado_synthesis.tcl
```

Generated reports:

```text
results/vivado_utilization.rpt
results/vivado_timing_summary.rpt
results/vivado_power.rpt
```

## Synopsys Design Compiler Flow

Update `scripts/synopsys_dc_synthesis.tcl` with the correct `.db` technology library, then run:

```tcl
dc_shell -f scripts/synopsys_dc_synthesis.tcl
```

Generated reports:

```text
results/area_fir_filter_pipelined.rpt
results/timing_fir_filter_pipelined.rpt
results/power_fir_filter_pipelined.rpt
```

## Analytical Hardware Summary

| Architecture | Multipliers | Registers / accumulator | Throughput |
|---|---:|---|---:|
| Serial/direct form | 361 | 361 sample-delay registers, 56-bit accumulator | 1 sample/cycle |
| Pipelined | 361 | Delay line + partial-sum pipeline registers | 1 sample/cycle |
| L=3 parallel | 1083 | Three pipelined lanes | 3 samples/cycle |

The exact area, Fmax, and power depend on the selected FPGA or ASIC library. The scripts above generate those target-specific numbers.
