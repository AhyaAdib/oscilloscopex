
# Changelog

## [0.2.0] - 2026-11-20 — Milestone 1
### Added
- Implemented `SignalGenerator` (`scripts/signal/signal_generator.gd`) supporting Sine, Square, Triangle, Sawtooth, Pulse, DC, and seeded Gaussian Noise.
- Created `SimState` autoload (`scripts/core/simulation_state.gd`) with `PackedFloat64Array` voltage/time buffers.
- Implemented custom `_draw()` `WaveformCanvas` (`scripts/visualization/waveform_canvas.gd`) with 10x8 graticule and HUD readouts.
- Built interactive Signal Generator & Display Scale front panel in `scripts/core/main.gd`.
- Added CLI numerical validation suite (`tests/run_tests.gd`).

## [0.1.0] - 2026-11-20 — Milestone 0
### Added
- Initialized repository at `/mnt/d/godotproj/oscillooscope` on `D:`.
- Configured Godot 4.3-stable (`gl_compatibility` renderer) with isolated XDG storage on `D:`.
- Created programmatic bootstrap scene (`scenes/main/main.tscn`) and entry script (`scripts/core/main.gd`).
- Created project architecture, development, and roadmap documentation.
