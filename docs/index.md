\---

layout: default
title: Low-Pass FIR Filter Design and Hardware Implementation
---

# Low-Pass FIR Filter Design and Hardware Implementation



###### **By Dhavala Bhat**



This project presents a complete DSP-to-RTL implementation of a low-pass FIR filter. The work includes filter coefficient generation, fixed-point quantization, Verilog RTL design, simulation, pipelined and parallel FIR architectures, synthesis scripts, implementation reports, waveform evidence, and final project documentation.

The target filter has a transition region from **0.20π to 0.23π rad/sample** with a required stopband attenuation of at least **80 dB**. A 100-tap filter was initially evaluated, but the final implementation uses **361 taps** to preserve the attenuation requirement after fixed-point quantization.

\---

## Key Project Results

|Item|Final Result|
|-|-:|
|Filter type|Low-pass FIR|
|Passband edge|0.20π rad/sample|
|Stopband edge|0.23π rad/sample|
|Required stopband attenuation|≥ 80 dB|
|Final number of taps|361|
|Coefficient format|Signed Q1.19, 20-bit|
|Input/output format|Signed Q1.15, 16-bit|
|Accumulator width|56-bit signed|
|Floating-point stopband attenuation|121.91 dB|
|Quantized stopband attenuation|91.37 dB|
|Quantized passband ripple|0.01368 dB|
|Selected architecture|Pipelined FIR|

\---

## Repository Structure

```text
fir\_filter\_final\_project/
├── README.md
├── rtl/
│   ├── fir\_filter\_serial.v
│   ├── fir\_filter\_pipelined.v
│   ├── fir\_filter\_parallel\_l3.v
│   ├── fir\_coeffs\_q15.vh
│   └── fir\_coeffs\_q19.vh
├── tb/
│   └── tb\_fir\_filter.v
├── matlab/
│   └── design\_fir\_filter.m
├── python/
│   └── generate\_coefficients.py
├── scripts/
│   ├── run\_iverilog.sh
│   ├── vivado\_synthesis.tcl
│   ├── vivado\_generate\_reports.tcl
│   ├── synopsys\_dc\_synthesis.tcl
│   ├── dc\_generate\_reports.tcl
│   └── timing\_constraints.xdc
├── results/
│   ├── filter\_metrics.txt
│   ├── coefficients/
│   ├── plots/
│   ├── reports/
│   ├── synthesis\_reports/
│   └── waveforms/
└── docs/
    ├── FIR\_Filter\_Final\_Report.docx
    ├── SYNTHESIS\_GUIDE.md
    ├── index.md
    └── figures/
```

\---

# 1\. MATLAB/Python FIR Design and Verilog Code Structure

## FIR Design Flow

The FIR filter design was completed using a MATLAB-style DSP design flow. A Python coefficient-generation script is also included so the design can be reproduced without depending only on MATLAB.

The design flow is:

1. Define the passband edge at 0.20π rad/sample.
2. Define the stopband edge at 0.23π rad/sample.
3. Set the stopband attenuation requirement to at least 80 dB.
4. Generate floating-point FIR coefficients.
5. Quantize the coefficients into signed fixed-point format.
6. Compare the original and quantized frequency responses.
7. Export the final fixed-point coefficients into Verilog include format.
8. Use the coefficients inside the Verilog FIR RTL.

|File|Purpose|
|-|-|
|`matlab/design\_fir\_filter.m`|MATLAB version of the FIR design and plotting flow|
|`python/generate\_coefficients.py`|Reproducible Python coefficient and plot generation flow|
|`rtl/fir\_coeffs\_q19.vh`|Final 20-bit Q1.19 Verilog coefficient file|
|`results/filter\_metrics.txt`|Saved numerical frequency-response metrics|
|`results/plots/`|Original, quantized, overlay, passband, and stopband plots|

## Verilog Code Structure

|RTL file|Description|
|-|-|
|`rtl/fir\_filter\_serial.v`|Baseline direct-form FIR implementation|
|`rtl/fir\_filter\_pipelined.v`|Pipelined FIR implementation using registered partial sums|
|`rtl/fir\_filter\_parallel\_l3.v`|L = 3 parallel FIR architecture for higher throughput|
|`rtl/fir\_coeffs\_q19.vh`|Final fixed-point coefficient include file|
|`tb/tb\_fir\_filter.v`|Testbench for RTL simulation|

The datapath uses signed fixed-point arithmetic. Input samples are stored in a delay line, multiplied by the Q1.19 coefficients, accumulated using a 56-bit signed accumulator, rounded, and finally saturated to a signed Q1.15 output. Saturation is used instead of wrap-around to avoid incorrect sign-flipped results during large intermediate accumulation.

\---

# 2\. Original vs Quantized Frequency Response

## Frequency Response Metrics

|Metric|Original floating-point|Quantized Q1.19|Comment|
|-|-:|-:|-|
|Passband ripple|0.01341 dB|0.01368 dB|Very small change|
|Stopband attenuation|121.91 dB|91.37 dB|Still above the 80 dB requirement|
|Requirement satisfied?|Yes|Yes|Final RTL coefficients meet target|

## Original Floating-Point Response

!\[Original floating-point response](figures/freq\_response\_original.png)

## Quantized Q1.19 Response

!\[Quantized Q1.19 response](figures/freq\_response\_quantized.png)

## Original vs Quantized Overlay

!\[Original vs quantized overlay](figures/freq\_response\_overlay.png)

## Passband Zoom

!\[Passband zoom](figures/passband\_zoom.png)

## Stopband Zoom

!\[Stopband zoom](figures/stopband\_zoom.png)

## Quantization Discussion

The floating-point filter provides **121.91 dB** stopband attenuation. After Q1.19 coefficient quantization, the attenuation becomes **91.37 dB**, which still satisfies the required **80 dB** specification with margin.

The main quantization effect is a small degradation in stopband attenuation because coefficient rounding slightly perturbs the ideal filter response. The passband response remains almost unchanged, with ripple changing from **0.01341 dB** to **0.01368 dB**. A 16-bit coefficient format was considered, but the final design uses **20-bit Q1.19 coefficients** because it gives better margin for the stopband attenuation requirement.

## Overflow Handling

Overflow is handled by using a wider internal datapath and saturation at the final output stage:

|Signal|Format|
|-|-|
|Input samples|Signed Q1.15, 16-bit|
|Coefficients|Signed Q1.19, 20-bit|
|Accumulator|56-bit signed|
|Output samples|Signed Q1.15, 16-bit|

This prevents accumulator overflow during the multiply-accumulate operation and avoids wrap-around at the output.

\---

# 3\. Pipelined and Parallel FIR Architecture

## Baseline Direct-Form FIR

The baseline FIR implements:

```text
y\[n] = h\[0]x\[n] + h\[1]x\[n-1] + ... + h\[N-1]x\[n-N+1]
```

This architecture is simple and useful as a reference implementation. However, because the multiply-accumulate chain is long, it has the weakest timing and lowest expected maximum clock frequency.

## Pipelined FIR Architecture

The pipelined FIR divides the 361-tap accumulation into registered partial-sum groups.

|Pipeline group|Tap range|Purpose|
|-|-:|-|
|Group 1|0–119|First partial accumulation|
|Group 2|120–239|Second partial accumulation|
|Group 3|240–360|Third partial accumulation|
|Final stage|Registered sum|Combines partial sums, rounds, and saturates output|

This improves the timing path because each pipeline stage performs a smaller accumulation. The tradeoff is a small increase in register count and latency. Since the multiplier count remains the same as the direct-form design, the pipelined FIR gives the best overall balance for this project.

## L = 3 Parallel FIR Architecture

The L = 3 parallel FIR processes three input samples per clock cycle using three parallel FIR lanes. This increases throughput from **1 sample/cycle** to **3 samples/cycle**.

The tradeoff is increased area and power because the architecture uses approximately three times the number of multipliers and lane registers compared to the single-lane design.

\---

# 4\. Simulation, Synthesis, and Hardware Implementation Results

## Simulation and Waveform Evidence

The repository includes simulation outputs and waveform evidence under:

```text
results/waveforms/
├── fir\_filter\_behavioral\_waveform.vcd
├── fir\_input\_output\_waveform.png
├── accumulator\_overflow\_margin.png
├── impulse\_response\_simulation.csv
└── sine\_response\_simulation.csv
```

These files are used to verify the FIR response behavior, input/output timing, impulse response, sine response, and accumulator margin.

## Synthesis Reports

The repository includes synthesis/report-generation files under:

```text
results/synthesis\_reports/
├── area\_utilization\_report.rpt
├── timing\_summary\_report.rpt
├── power\_estimation\_report.rpt
├── vivado\_generate\_reports.tcl
└── dc\_generate\_reports.tcl
```

The included report files provide implementation-style area, timing, and power summaries for documentation. Final vendor-specific synthesis reports can be regenerated using Vivado or Synopsys Design Compiler with the scripts provided in the repository.

## FPGA-Style Hardware Results

|Architecture|DSP multipliers|Estimated FFs|Estimated LUTs|Target clock|Estimated Fmax|Throughput|Estimated dynamic power|
|-|-:|-:|-:|-:|-:|-:|-:|
|Direct-form FIR|361|\~6.3k|\~18k–24k|100 MHz|\~45–70 MHz|1 sample/cycle|\~0.55–0.75 W|
|Pipelined FIR|361|\~6.7k|\~20k–26k|100 MHz|\~110–140 MHz|1 sample/cycle|\~0.65–0.90 W|
|L = 3 parallel FIR|1083|\~20k|\~60k–78k|100 MHz|\~100–130 MHz|3 samples/cycle|\~1.8–2.5 W|

## ASIC-Style Trend Summary

|Architecture|Relative area|Multiplier count|Register cost|Clock-frequency trend|Power trend|
|-|-:|-:|-:|-|-|
|Direct-form FIR|1.00x|361|Baseline|Lowest due to long MAC path|Baseline|
|Pipelined FIR|1.08x–1.15x|361|Higher due to pipeline registers|Best single-lane timing|Slightly higher|
|L = 3 parallel FIR|3.10x–3.30x|1083|About 3x lane registers|Highest throughput|Highest|

## Hardware Result Discussion

The direct-form FIR has the lowest architectural complexity but the weakest timing. The pipelined FIR is the preferred implementation because it improves timing while keeping the multiplier count unchanged. The L = 3 parallel FIR provides the highest throughput, but it uses significantly more DSP resources, registers, and power.

For this project, the **pipelined FIR architecture** is selected as the final preferred hardware design because it gives the best balance between area, timing, throughput, and power.

\---

# 5\. Final Report and Synthesis Guide

The final documentation files are included in the `docs/` folder.

|File|Purpose|
|-|-|
|`docs/FIR\_Filter\_Final\_Report.docx`|Final written project report|
|`docs/SYNTHESIS\_GUIDE.md`|Step-by-step Vivado and Design Compiler synthesis instructions|
|`docs/index.md`|GitHub Pages project webpage|

The synthesis guide explains how to create the project, add RTL files, add timing constraints, set the top module, run synthesis, and collect area, timing, and power reports.

\---

# 6\. Further Analysis and Conclusion

This project completes the full flow from floating-point FIR specification to fixed-point RTL implementation. The final Q1.19 coefficients satisfy the 80 dB stopband attenuation requirement after quantization, and the 56-bit accumulator provides safe internal precision for the hardware datapath.

The architecture comparison shows that pipelining is the most practical optimization for this FIR filter because it improves clock frequency without tripling the hardware resources. The L = 3 parallel design is useful when maximum throughput is required, but it comes with much higher area and power cost.

Overall, the project demonstrates a complete FIR filter design methodology covering DSP design, quantization, RTL implementation, architectural optimization, verification, and synthesis-oriented hardware analysis.

\---

## Reproduce the Results

Generate coefficients and plots:

```bash
python3 python/generate\_coefficients.py
```

Run RTL simulation:

```bash
bash scripts/run\_iverilog.sh
```

Run Vivado synthesis:

```bash
vivado -mode batch -source scripts/vivado\_synthesis.tcl
```

Generate Vivado reports:

```bash
vivado -mode batch -source scripts/vivado\_generate\_reports.tcl
```

Run Synopsys Design Compiler synthesis:

```bash
dc\_shell -f scripts/synopsys\_dc\_synthesis.tcl
```

Generate Design Compiler reports:

```bash
dc\_shell -f scripts/dc\_generate\_reports.tcl
```

\---

## Final Submission Checklist

* \[x] MATLAB/Python FIR coefficient generation
* \[x] Original floating-point frequency-response plot
* \[x] Quantized Q1.19 frequency-response plot
* \[x] Original vs quantized overlay plot
* \[x] Passband and stopband zoom plots
* \[x] Quantization-effect discussion
* \[x] Overflow handling explanation
* \[x] Verilog RTL source code
* \[x] Baseline direct-form FIR architecture
* \[x] Pipelined FIR architecture
* \[x] L = 3 parallel FIR architecture
* \[x] Testbench and simulation evidence
* \[x] Waveform and response files
* \[x] Hardware implementation result tables
* \[x] Vivado synthesis script
* \[x] Synopsys Design Compiler synthesis script
* \[x] Synthesis guide
* \[x] Final DOCX report
* \[x] GitHub Pages-ready `index.md`

