System Architecture
Core Principle: Single Shared Simulation State
All views (Virtual Instrument, Internal Circuit Explorer, Laboratory) read from and write to a single shared simulation state (SimState). Rendering modules never generate independent synthetic waveforms.

Module Layout
scripts/core/: Application lifecycle, SimState authoritative data store, configuration management.

scripts/signal/: Mathematical signal synthesis (Sine, Square, Triangle, Sawtooth, Pulse, DC, Noise).

scripts/simulation/: Fixed-step simulation clock and node solver orchestration.

scripts/analog/: Analog CRT signal path (attenuator, vertical amp, delay line, trigger, sweep, deflection).

scripts/digital/: DSO path (anti-aliasing filter, sample-and-hold, ADC quantizer, acquisition memory, FIR DSP).

scripts/circuit/: Programmatic block diagrams, node probes, and fault-injection hooks.

scripts/measurement/: Vpp, Vrms, frequency, period, and Radix-2 FFT engine.

scripts/visualization/: High-performance _draw() CRT phosphor and DSO waveform canvases.

scripts/ui/: Programmatic front-panel controls and parameter inspectors.

scripts/laboratory/: Experiment presets, analytical reference equations, error calculation, and CSV export.
