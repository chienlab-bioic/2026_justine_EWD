# 2026_justine_EWD

Extension-enhanced Wavelet Decomposition (EWD) for robust peak extraction in Square Wave Voltammetry (SWV) voltammograms.

---

## What this repo contains
- MATLAB implementation of EWD-based SWV peak extraction.
- Core function: `i_extract_ewd.m` under `functions/`
  - Input: voltage + current
  - Output: extracted peak current (and optional debug plots)
- Conventional function (for benchmarking/comparison): `i_extract_lbf.m` under `functions/`
- Example scripts for both EWD and LBF under `examples/`.

---

## Requirements
- MATLAB
- Wavelet Toolbox (required)

---

## Method Overview
EWD is designed to be more resilient to background/baseline drift and noise than simple linear baseline fitting.
High-level pipeline:

1. **Peak-region localization + truncation**  
   Smooth the trace and use derivatives to find a peak-centered region. Truncate around that region using `V_peak_width`.

2. **Extension / repetition + mirroring**  
   Repeat the truncated waveform with continuity offsets and mirror it to reduce boundary discontinuities and create a pseudo-periodic signal (helps wavelet decomposition behave better).

3. **MODWT decomposition**  
   Apply MODWT to separate the signal into multi-resolution components.

4. **Band selection + reconstruction**  
   Select wavelet levels that best represent the SWV peak content (and reject baseline/noise-like components), then reconstruct a denoised peak waveform.

5. **Peak extraction**  
   Average across effective cycles and take the maximum (typically within the central region) as the extracted peak current.

---

## Quickstart
### Function call
```matlab
i_signal = i_extract_ewd(voltage0, current0, V_peak_width, plot_all);
```

### Inputs
| Name | Type | Units | Description |
|------|------|-------|-------------|
| `voltage0` | vector | V | SWV Vvltage vector |
| `current0` | vector | A | SWV current vector, same length as `voltage0`. |
| `V_peak_width` | 1x2 vector `[V_left V_right]` | V | Single-sided widths (in volts) used to truncate around the detected peak region. Increase if truncation clips the peak; decrease if too much baseline is included. |
| `plot_all` | logical (`true`/`false`) | — | `true` shows diagnostic plots (derivatives, wavelet levels, reconstructions). `false` runs without debug plots (recommended for batch). |

### Output
| Name | Type | Units | Description |
|------|------|-------|-------------|
| `i_signal` | scalar | A | Extracted SWV peak current from the reconstructed/denoised waveform. |

## Citation
For more information, please see:
- Tsai, Y.-C.; Soh, H. T.; Chien, J.-C. **Extension-Enhanced Wavelet Decomposition: a Noise and Background Resilient Square-Wave Voltammogram Signal-Processing Technique for Electrochemical Aptamer-Based Biosensing In Vivo.** *ACS Sensors* (published online Jan 14, 2026). https://doi.org/10.1021/acssensors.5c02906
