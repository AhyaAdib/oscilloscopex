# Oscilloscope Lab

**Interactive Oscilloscope & Internal Circuit Simulation Laboratory**  
*From Signal Input to CRT Beam and Digital Display.*

## Overview
Oscilloscope Lab is a code-first educational electronic instrumentation simulator built in Godot 4.3 (GDScript). It couples a realistic **Virtual Instrument Mode** (Analog CRT & Digital Storage Oscilloscope), an **Internal Architecture Mode** (interactive signal-flow block diagrams and node inspection), and a **Laboratory Mode** (fault injection, theoretical comparisons, and CSV export) to a single shared mathematical simulation engine.

## Environment & Storage Policy
All binaries, XDG directories, and project files reside exclusively on `D:`:
- Project Root: `/mnt/d/godotproj/oscillooscope` (`D:\godotproj\oscillooscope`)
- Godot Binary: `/mnt/d/tools/godot/godot`
- XDG Paths: `/mnt/d/tools/godot-{data,config,cache}`

## CLI Execution
```bash
# Headless validation
"$GODOT_BIN" --headless --path "$OSCILLO_ROOT" --quit-after 2

# Launch GUI via WSLg
"$GODOT_BIN" --path "$OSCILLO_ROOT"
