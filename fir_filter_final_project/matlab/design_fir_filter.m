% FIR low-pass filter design for course project
clear; clc; close all;
numTaps = 361; f = [0 0.20 0.23 1.0]; a = [1 1 0 0]; w = [1 1000];
b = firpm(numTaps-1, f, a, w);
Q = 19; bq_int = round(b * 2^Q); bq_int = max(min(bq_int, 2^19-1), -2^19); bq = bq_int / 2^Q;
[H, om] = freqz(b,1,32768); [Hq,~] = freqz(bq,1,32768); fn=om/pi;
fprintf('Original stopband attenuation: %.2f dB
', -max(20*log10(abs(H(fn>=0.23)))));
fprintf('Q1.19 stopband attenuation: %.2f dB
', -max(20*log10(abs(Hq(fn>=0.23)))));
figure; plot(fn,20*log10(abs(H)+1e-12)); hold on; plot(fn,20*log10(abs(Hq)+1e-12),'--'); grid on; xline(0.20,':'); xline(0.23,':'); ylim([-140 5]); xlabel('Normalized frequency (x pi rad/sample)'); ylabel('Magnitude (dB)'); legend('Original','Q1.19');
writematrix(b(:), '../results/coefficients/fir_coefficients_float.txt');
writematrix(bq_int(:), '../results/coefficients/fir_coefficients_q19_decimal.txt');
fid=fopen('../results/coefficients/fir_coefficients_q19_hex.mem','w'); for k=1:length(bq_int), fprintf(fid,'%05X
', mod(bq_int(k),2^20)); end; fclose(fid);
