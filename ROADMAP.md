
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
- [ ] **Milestone 2 — Analog oscilloscope** (In Progress)
  - Input probe attenuation (1x / 10x) & AC/DC/GND coupling (first-order RC high-pass filter)
  - Vertical amplifier gain/saturation & vertical position offset
  - Edge trigger circuit (Rising/Falling slope, trigger level, hysteresis, holdoff)
  - Timebase sweep generator, horizontal position, and beam flyback/blanking
  - CRT phosphor persistence (`I(t) = I0 * exp(-t/tau_p)`), intensity, and beam focus
- [ ] **Milestone 3 — Analog internal architecture**
- [ ] **Milestone 4 — Digital oscilloscope**
- [ ] **Milestone 5 — Digital internal architecture**
- [ ] **Milestone 6 — Laboratory**
- [ ] **Milestone 7 — Validation and release**
