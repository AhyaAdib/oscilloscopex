
# Development Roadmap

- [x] **Milestone 0 — Environment and project bootstrap** (Completed)
  - Verified Ubuntu 24.04.5 WSL2 on `D:\WSL\Ubuntu-24.04`
  - Installed Godot 4.3-stable portable on `/mnt/d/tools/godot/godot`
  - Configured isolated XDG paths on `D:`
  - Bootstrapped programmatic `project.godot`, `scenes/main/main.tscn`, and `scripts/core/main.gd`
- [x] **Milestone 1 — Signal generation** (Completed)
  - Signal generator (`Sine`, `Square`, `Triangle`, `Sawtooth`, `Pulse`, `DC`, `Noise`)
  - Configurable amplitude, frequency, phase, DC offset, duty cycle, and deterministic Gaussian noise
  - Waveform canvas with voltage/time axes and 10x8 graticule grid
  - Automated numerical unit tests (`7 PASSED, 0 FAILED`)
- [x] **Milestone 2 — Analog oscilloscope & National VP-5231A Front Panel** (Completed)
  - Input probe attenuation (1x / 10x) & AC/DC/GND coupling (first-order RC high-pass filter)
  - Vertical amplifier gain/saturation & vertical position offset
  - Edge trigger circuit (Rising/Falling slope, trigger level, hysteresis)
  - Timebase sweep generator & horizontal position
  - National VP-5231A themed chassis, cyan-blue CRT screen, scale illumination, focus, intensity, and persistence (`11 PASSED, 0 FAILED`)
- [ ] **Milestone 3 — Analog Internal Architecture Explorer** (Next)
  - Interactive block diagram & live node voltage/waveform inspection sharing `SimState`
- [ ] **Milestone 4 — 3D Workbench & Exact National VP-5231A 3D Instrument**
  - Procedural 3D National VP-5231A chassis with every physical knob, switch, and jack from the reference hardware
  - Keep Talking and Nobody Explodes style interactive camera inspection, 3D rotary knob manipulation, and physical BNC/hook probe placement onto Circuit-Under-Test (DUT) test points
- [ ] **Milestone 5 — Digital Oscilloscope (DSO)**
- [ ] **Milestone 6 — Digital Internal Architecture Explorer**
- [ ] **Milestone 7 — Laboratory Mode (Fault Injection, FFT, CSV Export) & Release**
