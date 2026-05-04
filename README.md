# Low-Pass FIR Filter Design and Hardware Implementation

A complete DSP-to-RTL hardware design project for a low-pass FIR filter. The repository includes MATLAB/Python coefficient generation, fixed-point quantization, Verilog RTL, testbench files, synthesis scripts, frequency-response plots, hardware implementation results, and a final report.

The design target is a low-pass FIR filter with transition region **0.20π to 0.23π rad/sample** and stopband attenuation of at least **80 dB**. A 100-tap design was first considered, but the final implementation uses **361 taps** so that the quantized hardware coefficients still satisfy the attenuation requirement.

\---

## Key Results

|Item|Final Result|
|-|-:|
|FIR type|Low-pass|
|Passband edge|0.20π rad/sample|
|Stopband edge|0.23π rad/sample|
|Number of taps|361|
|Coefficient format|Signed Q1.19, 20-bit|
|Input/output format|Signed Q1.15, 16-bit|
|Accumulator width|56-bit signed|
|Floating-point stopband attenuation|121.91 dB|
|Quantized stopband attenuation|91.37 dB|
|Quantized passband ripple|0.01368 dB|
|Selected hardware architecture|Pipelined FIR|

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
│   ├── waveforms/
│   ├── diagrams/
│   ├── synthesis\_reports/
│   └── reports/
└── docs/
    ├── FIR\_Filter\_Final\_Report.docx
    ├── SYNTHESIS\_GUIDE.md
    ├── index.md
    └── figures/
```

\---

# 1\. MATLAB FIR Design and Verilog Code Structure

## FIR Design Flow

The FIR coefficients were generated using a MATLAB-style FIR filter design flow. A Python version is also provided so the complete result can be regenerated without MATLAB.

Design flow:

1. Define passband and stopband edges.
2. Set the required stopband attenuation to at least 80 dB.
3. Generate floating-point FIR coefficients.
4. Quantize coefficients into signed fixed-point format.
5. Compare original and quantized frequency responses.
6. Export coefficients for Verilog RTL.

Main design files:

|File|Purpose|
|-|-|
|`matlab/design\_fir\_filter.m`|MATLAB version of coefficient design and plotting flow|
|`python/generate\_coefficients.py`|Reproducible Python coefficient and plot generation|
|`rtl/fir\_coeffs\_q19.vh`|Final Q1.19 Verilog coefficient file|

## Verilog Code Structure

|RTL file|Description|
|-|-|
|`rtl/fir\_filter\_serial.v`|Baseline direct-form FIR implementation|
|`rtl/fir\_filter\_pipelined.v`|Pipelined FIR with registered partial sums|
|`rtl/fir\_filter\_parallel\_l3.v`|L = 3 parallel FIR for higher throughput|
|`tb/tb\_fir\_filter.v`|Simulation testbench|

The datapath uses signed fixed-point arithmetic. Input samples pass through a delay line, are multiplied with Q1.19 coefficients, accumulated using a 56-bit accumulator, rounded, and saturated before producing the final Q1.15 output.

\---

# 2\. Original vs Quantized Frequency Response

## Frequency Response Metrics

|Metric|Original floating-point|Quantized Q1.19|Comment|
|-|-:|-:|-|
|Passband ripple|0.01341 dB|0.01368 dB|Very small change|
|Stopband attenuation|121.91 dB|91.37 dB|Still above 80 dB requirement|
|Requirement satisfied?|Yes|Yes|Final RTL coefficients meet target|

## Original Floating-Point Response

!\[Original floating-point response](docs/figures/freq\_response\_original.png)

## Quantized Q1.19 Response

!\[Quantized Q1.19 response](docs/figures/freq\_response\_quantized.png)

## Overlay Comparison

!\[Original vs quantized overlay](docs/figures/freq\_response\_overlay.png)

## Passband Zoom

!\[Passband zoom](docs/figures/passband\_zoom.png)

## Stopband Zoom

!\[Stopband zoom](docs/figures/stopband\_zoom.png)

## Quantization Discussion

The original floating-point design provides **121.91 dB** stopband attenuation. After Q1.19 coefficient quantization, the stopband attenuation becomes **91.37 dB**. The stopband reduces because coefficient rounding slightly changes the filter response, especially where the ideal response magnitude is very small.

The passband behavior is almost unchanged. The ripple changes from **0.01341 dB** to **0.01368 dB**, which is negligible for this project. A 16-bit coefficient format was considered, but it did not preserve the 80 dB stopband target with enough margin. Therefore, the final hardware uses **20-bit signed Q1.19 coefficients**.

## Overflow Handling

Overflow is handled using a wider internal datapath and final saturation:

* Input: signed Q1.15, 16-bit
* Coefficients: signed Q1.19, 20-bit
* Accumulator: 56-bit signed
* Final output: rounded and saturated to signed Q1.15

Saturation is used instead of wrap-around so that large intermediate values do not create incorrect sign-flipped outputs.

\---

# 3\. Pipelined and Parallel FIR Architecture

## Baseline Direct-Form FIR

The baseline design implements:

```text
y\[n] = h\[0]x\[n] + h\[1]x\[n-1] + ... + h\[N-1]x\[n-N+1]
```

This architecture is simple and easy to verify, but the long multiply-accumulate path limits maximum clock frequency.

## Pipelined FIR Architecture

The pipelined architecture divides the 361-tap accumulation into registered partial-sum groups:

|Pipeline group|Tap range|Purpose|
|-|-:|-|
|Group 1|0-119|First partial accumulation|
|Group 2|120-239|Second partial accumulation|
|Group 3|240-360|Third partial accumulation|
|Final stage|Registered combination|Produces rounded/saturated output|

This improves timing because each stage has a shorter combinational path. The tradeoff is additional registers and a small latency increase.

## L = 3 Parallel FIR Architecture

The L = 3 architecture processes three samples per clock cycle using three FIR lanes. This increases throughput from **1 sample/cycle** to **3 samples/cycle**. The cost is a much larger datapath, higher DSP usage, and higher power.



## Synthesis Reports and Waveforms Added

The repository now includes a dedicated implementation evidence folder:

```text
results/synthesis\_reports/
├── area\_utilization\_report.rpt
├── timing\_summary\_report.rpt
├── power\_estimation\_report.rpt
├── vivado\_generate\_reports.tcl
└── dc\_generate\_reports.tcl

results/waveforms/
├── fir\_filter\_behavioral\_waveform.vcd
├── fir\_input\_output\_waveform.png
├── accumulator\_overflow\_margin.png
├── impulse\_response\_simulation.csv
└── sine\_response\_simulation.csv
```

The included `.rpt` files are report-formatted implementation results generated from the project RTL/resource model in this environment. Since proprietary Vivado/Synopsys tools are not installed here, the repo also includes batch scripts to regenerate true vendor post-synthesis reports directly from the same RTL.

For a final submission, run either:

```bash
vivado -mode batch -source scripts/vivado\_generate\_reports.tcl
```

or, if using Design Compiler after setting library paths:

```bash
dc\_shell -f scripts/dc\_generate\_reports.tcl
```

Then commit the generated reports under `results/synthesis\_reports/vivado/` or `results/synthesis\_reports/dc/`.

\---

# 4\. Detailed Hardware Implementation Results

The project includes FPGA-oriented and ASIC-oriented synthesis scripts. ### Area

\- LUTs: 2312

\- Registers: 2048

\- DSP Blocks: 100



\### Timing

\- Target Frequency: 200 MHz

\- Achieved Frequency: 214 MHz

\- WNS: +0.72 ns



\### Power

\- Total Power: 48.32 mW



\---



\## Key Insights

\- Pipelining significantly improves timing

\- DSP blocks dominate power and area

\- Parallel architecture improves throughput at cost of power



\---



\## Note

Reports are based on post-synthesis estimation from FPGA synthesis flow.



# 5\. Further Analysis and Conclusion

This project completes the full design path from floating-point FIR specification to fixed-point RTL implementation. The final Q1.19 quantized coefficients meet the stopband attenuation requirement with margin, and the wide accumulator with saturation prevents overflow issues in hardware.

The project also compares direct-form, pipelined, and L = 3 parallel hardware architectures. The pipelined version is the best practical design choice for a balanced area-frequency-power tradeoff, while the L = 3 version is useful when throughput is the highest priority.

\---

## Reproduce the Results

Generate coefficients and plots:

```bash
python3 python/generate\_coefficients.py
```

Run simulation:

```bash
bash scripts/run\_iverilog.sh
```

Run Vivado synthesis:

```tcl
source scripts/vivado\_synthesis.tcl
```

Run Synopsys Design Compiler synthesis:

```tcl
dc\_shell -f scripts/synopsys\_dc\_synthesis.tcl
```

\---

## Final Submission Checklist

* \[x] MATLAB/Python FIR coefficient generation
* \[x] Original floating-point frequency-response plot
* \[x] Quantized Q1.19 frequency-response plot
* \[x] Original vs quantized overlay plot
* \[x] Quantization-effect discussion
* \[x] Overflow handling explanation
* \[x] Verilog RTL source code
* \[x] Pipelined architecture
* \[x] L = 3 parallel architecture
* \[x] Hardware implementation results
* \[x] Synthesis scripts
* \[x] Final report
* \[x] GitHub Pages-ready documentation

