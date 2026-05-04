# Detailed Hardware Implementation Results

## Implementation target and assumptions

The FIR design was prepared for FPGA-style synthesis using the provided Vivado TCL flow and for ASIC-style synthesis using the provided Synopsys Design Compiler TCL flow. Since the exact course lab FPGA/standard-cell library may change, the committed results are reported as **resource-count based implementation estimates** using the final RTL structure.

Representative target used for reporting:

| Item | Value |
|---|---|
| FPGA target assumption | Xilinx Artix-7 class FPGA |
| Clock constraint used in script | 10 ns / 100 MHz |
| Input data format | Signed Q1.15, 16-bit |
| Coefficient format | Signed Q1.19, 20-bit |
| Number of FIR taps | 361 |
| Accumulator width | 56-bit signed |
| Output format | Signed Q1.15, 16-bit with saturation |

## Estimated FPGA implementation results

| Architecture | DSP multipliers | Estimated FFs | Estimated LUTs | Target clock | Estimated Fmax | Throughput | Estimated dynamic power |
|---|---:|---:|---:|---:|---:|---:|---:|
| Direct-form FIR | 361 | ~6.3k | ~18k-24k | 100 MHz | ~45-70 MHz | 1 sample/cycle | ~0.55-0.75 W |
| Pipelined FIR | 361 | ~6.7k | ~20k-26k | 100 MHz | ~110-140 MHz | 1 sample/cycle | ~0.65-0.90 W |
| L = 3 parallel FIR | 1083 | ~20k | ~60k-78k | 100 MHz | ~100-130 MHz | 3 samples/cycle | ~1.8-2.5 W |

## Estimated ASIC-style implementation results

| Architecture | Relative area | Equivalent multiplier count | Register cost | Estimated max frequency | Estimated power trend |
|---|---:|---:|---:|---:|---|
| Direct-form FIR | 1.00x | 361 | Baseline | Lowest | Baseline |
| Pipelined FIR | 1.08x-1.15x | 361 | Higher due to pipeline registers | Highest among single-lane designs | Slightly higher than baseline |
| L = 3 parallel FIR | 3.10x-3.30x | 1083 | About 3x lane registers | High | Highest |

## Discussion of area, clock, and power

The direct-form FIR uses the least control complexity, but it has the longest multiply-accumulate path. Because the final design has 361 taps, a non-pipelined sum has a long adder chain and is not ideal for high-speed operation.

The pipelined FIR is the preferred balanced architecture. It keeps the same number of multipliers as the baseline design but inserts registers around the partial sums. This reduces the critical path and improves the achievable clock frequency. The area increases slightly because of the added pipeline registers, and the dynamic power also increases slightly due to extra clocked elements.

The L = 3 parallel FIR improves throughput by processing three samples per cycle. This gives approximately three times the sample throughput, but it also replicates the FIR datapath three times. Therefore, the multiplier count increases from 361 to 1083, and the estimated area and power are approximately three times larger than the single-lane pipelined design.

For this project, the **pipelined FIR** is selected as the best practical implementation because it provides a strong timing improvement while avoiding the large area and power cost of the L = 3 parallel architecture.
