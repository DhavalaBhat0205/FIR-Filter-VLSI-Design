#!/usr/bin/env python3
from pathlib import Path
import numpy as np
from scipy.signal import remez, freqz
import matplotlib.pyplot as plt
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results'
PLOTS = OUT / 'plots'
FIGS = ROOT / 'docs' / 'figures'
COEFF = OUT / 'coefficients'
for d in (PLOTS, FIGS, COEFF): d.mkdir(parents=True, exist_ok=True)
NUM_TAPS = 361
Q = 19
h = remez(NUM_TAPS, [0, 0.20, 0.23, 1.0], [1, 0], weight=[1, 1000], fs=2, maxiter=1000)
hq = np.clip(np.round(h * (1 << Q)).astype(int), -(1 << Q), (1 << Q) - 1)
hqf = hq / (1 << Q)
np.savetxt(COEFF / 'fir_coefficients_float.txt', h, fmt='%.18e')
np.savetxt(COEFF / 'fir_coefficients_q19_decimal.txt', hq, fmt='%d')
with open(COEFF / 'fir_coefficients_q19_hex.mem', 'w') as f:
    for c in hq:
        f.write(f'{int(c) & 0xfffff:05X}\n')
w, H = freqz(h, worN=65536)
_, Hq = freqz(hqf, worN=65536)
wn = w / np.pi
def db(x): return 20 * np.log10(np.maximum(np.abs(x), 1e-14))
HdB, HqDB = db(H), db(Hq)
pass_idx, stop_idx = wn <= 0.20, wn >= 0.23
orig_ripple = HdB[pass_idx].max() - HdB[pass_idx].min()
quant_ripple = HqDB[pass_idx].max() - HqDB[pass_idx].min()
orig_stop = -HdB[stop_idx].max()
quant_stop = -HqDB[stop_idx].max()
def savefig(name):
    plt.tight_layout()
    for d in (PLOTS, FIGS): plt.savefig(d / name, dpi=240, bbox_inches='tight')
    plt.close()
plt.figure(figsize=(8, 4.8)); plt.plot(wn, HdB); plt.axvline(.20, linestyle='--'); plt.axvline(.23, linestyle='--'); plt.ylim([-150,5]); plt.xlim([0,1]); plt.grid(True, alpha=.35); plt.title('Original Floating-Point FIR Frequency Response'); plt.xlabel('Normalized Frequency (×π rad/sample)'); plt.ylabel('Magnitude (dB)'); savefig('freq_response_original.png')
plt.figure(figsize=(8, 4.8)); plt.plot(wn, HqDB); plt.axvline(.20, linestyle='--'); plt.axvline(.23, linestyle='--'); plt.axhline(-80, linestyle=':'); plt.ylim([-150,5]); plt.xlim([0,1]); plt.grid(True, alpha=.35); plt.title('Quantized Q1.19 FIR Frequency Response'); plt.xlabel('Normalized Frequency (×π rad/sample)'); plt.ylabel('Magnitude (dB)'); savefig('freq_response_quantized.png')
plt.figure(figsize=(8.5,5)); plt.plot(wn,HdB,label='Original floating-point'); plt.plot(wn,HqDB,label='Quantized Q1.19',linestyle='--'); plt.axvline(.20,linestyle='--'); plt.axvline(.23,linestyle='--'); plt.axhline(-80,linestyle=':', label='80 dB target'); plt.ylim([-150,5]); plt.xlim([0,1]); plt.grid(True, alpha=.35); plt.legend(fontsize=8); plt.title('Original vs Quantized FIR Frequency Response'); plt.xlabel('Normalized Frequency (×π rad/sample)'); plt.ylabel('Magnitude (dB)'); savefig('freq_response_overlay.png')
plt.figure(figsize=(8,4.8)); plt.plot(wn[pass_idx],HdB[pass_idx],label='Original'); plt.plot(wn[pass_idx],HqDB[pass_idx],label='Q1.19',linestyle='--'); plt.grid(True, alpha=.35); plt.legend(); plt.title('Passband Zoom'); plt.xlabel('Normalized Frequency (×π rad/sample)'); plt.ylabel('Magnitude (dB)'); savefig('passband_zoom.png')
plt.figure(figsize=(8,4.8)); plt.plot(wn[stop_idx],HdB[stop_idx],label='Original'); plt.plot(wn[stop_idx],HqDB[stop_idx],label='Q1.19',linestyle='--'); plt.axhline(-80,linestyle=':',label='80 dB target'); plt.ylim([-150,-70]); plt.xlim([.23,1]); plt.grid(True, alpha=.35); plt.legend(fontsize=8); plt.title('Stopband Zoom'); plt.xlabel('Normalized Frequency (×π rad/sample)'); plt.ylabel('Magnitude (dB)'); savefig('stopband_zoom.png')
plt.figure(figsize=(8,4.8)); plt.plot(np.arange(len(h)), h-hqf); plt.grid(True, alpha=.35); plt.title('Coefficient Quantization Error'); plt.xlabel('Tap index'); plt.ylabel('Floating-point - Q1.19'); savefig('coefficient_quantization_error.png')
plt.figure(figsize=(8,4.8)); plt.stem(np.arange(len(h)), h, markerfmt=' ', basefmt=' '); plt.grid(True, alpha=.35); plt.title('FIR Impulse Response / Coefficients'); plt.xlabel('Tap index'); plt.ylabel('Coefficient value'); savefig('impulse_response.png')
(OUT / 'filter_metrics.txt').write_text(f'Original passband ripple: {orig_ripple:.5f} dB\nOriginal stopband attenuation: {orig_stop:.2f} dB\nQ1.19 passband ripple: {quant_ripple:.5f} dB\nQ1.19 stopband attenuation: {quant_stop:.2f} dB\nFilter taps: {NUM_TAPS}\nCoefficient quantization: signed Q1.19, 20-bit\n')
print((OUT / 'filter_metrics.txt').read_text())
