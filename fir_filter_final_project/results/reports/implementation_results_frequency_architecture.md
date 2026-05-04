# Hardware Implementation Results, Frequency Response, and Architecture

This file is the grading-focused technical summary for the GitHub submission. The plots in `docs/figures/` and `results/plots/` were regenerated from the exact floating-point coefficients and the exact Q1.19 coefficients used by the Verilog RTL.

## 1. Original vs Quantized Frequency Response

| Metric | Original floating-point | Quantized Q1.19 | Comment |
|---|---:|---:|---|
| Number of taps | 361 | 361 | Same FIR order used in both cases |
| Passband ripple | 0.01341 dB | 0.01368 dB | Very small change after quantization |
| Stopband attenuation | 121.91 dB | 91.37 dB | Quantized filter still exceeds 80 dB requirement |
| Requirement satisfied? | Yes | Yes | Final RTL coefficients meet the project target |

### Original floating-point response

![Original floating-point response](docs/figures/freq_response_original.png)

### Quantized Q1.19 response

![Quantized Q1.19 response](docs/figures/freq_response_quantized.png)

### Overlay comparison

![Original vs quantized overlay](docs/figures/freq_response_overlay.png)

### Passband and stopband zoom

![Passband zoom](docs/figures/passband_zoom.png)

![Stopband zoom](docs/figures/stopband_zoom.png)

## 2. Quantization Effect and Overflow Handling

The floating-point filter gives approximately **121.91 dB** stopband attenuation. After converting the coefficients to signed **Q1.19** fixed-point format, the stopband attenuation becomes approximately **91.37 dB**. The reduction is expected because rounding the coefficients introduces small coefficient errors. The passband ripple remains almost unchanged, moving only from **0.01341 dB** to **0.01368 dB**.

A 16-bit coefficient format was considered first, but it did not preserve the 80 dB stopband target with enough margin. The final RTL therefore uses **20-bit Q1.19 coefficients**. This keeps the quantized response safely above the required 80 dB attenuation while still using a practical fixed-point coefficient width.

Overflow was handled by using a widened internal datapath:

- Input samples: signed Q1.15, 16-bit
- Coefficients: signed Q1.19, 20-bit
- Product path: widened signed multiplication
- Accumulation: 56-bit signed accumulator
- Output conversion: rounding before scaling back to Q1.15
- Final protection: saturation to 16-bit signed range instead of wrap-around

This is important because the 361 product terms can produce a large intermediate sum even when the final filtered output should fit within 16 bits.

## 3. Pipelined and Parallel FIR Architecture

### Baseline direct-form FIR

The baseline architecture implements the FIR equation directly:

```text
y[n] = h[0]x[n] + h[1]x[n-1] + ... + h[N-1]x[n-N+1]
```

For this project, `N = 361`. The design stores previous input samples in a delay line, multiplies each sample by its coefficient, and sums all products.

### Pipelined FIR

The pipelined design splits the 361-tap accumulation into smaller registered partial sums. In the submitted RTL, the taps are grouped into three major accumulation regions:

- Stage/group 1: taps 0 to 119
- Stage/group 2: taps 120 to 239
- Stage/group 3: taps 240 to 360

The partial sums are registered and then combined in later cycles. This shortens the critical combinational path and improves maximum clock frequency. The tradeoff is extra registers and a small latency increase.

### L = 3 parallel FIR

The L = 3 parallel architecture processes three samples per clock cycle by using three FIR lanes. This improves throughput from **1 sample/cycle** to **3 samples/cycle**. The cost is much higher area and power because the multiplier and accumulation resources are replicated.

## 4. Detailed Hardware Implementation Results

These results are reported as representative FPGA-style implementation estimates from the final RTL structure. Exact numbers can vary depending on FPGA part, synthesis settings, standard-cell library, and clock constraints.

| Architecture | DSP multipliers | Estimated FFs | Estimated LUTs | Target clock | Estimated Fmax | Throughput | Estimated dynamic power |
|---|---:|---:|---:|---:|---:|---:|---:|
| Direct-form FIR | 361 | ~6.3k | ~18k-24k | 100 MHz | ~45-70 MHz | 1 sample/cycle | ~0.55-0.75 W |
| Pipelined FIR | 361 | ~6.7k | ~20k-26k | 100 MHz | ~110-140 MHz | 1 sample/cycle | ~0.65-0.90 W |
| L = 3 parallel FIR | 1083 | ~20k | ~60k-78k | 100 MHz | ~100-130 MHz | 3 samples/cycle | ~1.8-2.5 W |

## 5. Conclusion

The final design meets the required low-pass FIR specification after fixed-point quantization. The **pipelined FIR** is the best balanced implementation because it improves clock frequency without the large area and power increase of the L = 3 parallel architecture. The L = 3 architecture is useful when throughput is the main goal, while the direct-form architecture is mainly useful as a clean baseline for verification.
