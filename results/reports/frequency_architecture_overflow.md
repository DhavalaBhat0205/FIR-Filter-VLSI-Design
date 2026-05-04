# Frequency Response, Quantization, Overflow Handling, and Architecture

## Frequency response summary

| Metric | Floating-point filter | Quantized Q1.19 filter |
|---|---:|---:|
| Passband ripple | 0.01341 dB | 0.01368 dB |
| Stopband attenuation | 121.92 dB | 91.37 dB |
| Required stopband attenuation | 80 dB | 80 dB |
| Requirement satisfied? | Yes | Yes |

The un-quantized floating-point FIR filter provides approximately 121.92 dB stopband attenuation. After fixed-point coefficient quantization, the stopband attenuation reduces to approximately 91.37 dB. This reduction is expected because quantization slightly perturbs the coefficient values. However, the final quantized filter still provides more than the required 80 dB stopband attenuation.

The passband ripple changes only slightly from 0.01341 dB to 0.01368 dB. Therefore, the passband behavior is almost unchanged by the Q1.19 coefficient quantization.

## Quantization comments

A 16-bit coefficient format was initially considered, but it did not provide enough precision to keep the stopband attenuation safely above 80 dB. The final design therefore uses 20-bit signed Q1.19 coefficients. This is a good tradeoff because it improves stopband performance without making the coefficient width unnecessarily large.

## Overflow handling

The fixed-point datapath avoids overflow using the following choices:

1. Input samples are represented in signed Q1.15 format.
2. Coefficients are represented in signed Q1.19 format.
3. Multiplication is performed using a widened product path.
4. The products are accumulated using a 56-bit signed accumulator.
5. The final result is rounded before shifting back to Q1.15 scale.
6. The output is saturated to the signed 16-bit range instead of allowing wrap-around.

This is important because a 361-tap FIR filter can produce a large intermediate sum even when the final output is within the valid 16-bit range. Saturation prevents wrap-around distortion at the output.

## Pipelined architecture

The pipelined FIR separates the 361-tap accumulation into three partial-sum groups. The first group covers taps 0-119, the second group covers taps 120-239, and the third group covers taps 240-360. These partial sums are registered and then combined in later stages.

This structure reduces the amount of combinational logic between registers and improves timing compared with a completely unpipelined direct-form implementation. The tradeoff is a small increase in latency and register count.

## L = 3 parallel architecture

The L = 3 architecture instantiates three FIR lanes and processes three input samples during the same clock cycle. This increases throughput from one output sample per clock to three output samples per clock. The cost is higher area and power because the main datapath is replicated three times.

## Architecture conclusion

The direct-form FIR is simple and useful as a baseline. The pipelined FIR is the best balanced architecture for this project because it improves clock frequency while keeping hardware cost reasonable. The L = 3 parallel design is best only when maximum throughput is more important than area and power.
