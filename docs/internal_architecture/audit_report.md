# Milestone 0 Audit Report — Internal Architecture

## 1. Existing State Summary
- Simulation engine (`SimState` in `scripts/core/simulation_state.gd`) computes 8 analog stages (`INPUT BNC`, `COUPLING`, `ATTENUATOR`, `VERTICAL PREAMP`, `DELAY LINE`, `VERTICAL DEFLECTION`, `TRIGGER`, `SWEEP & X-AMP`) and emits `state_updated`.
- Exterior 3D builder (`VP5231A3DBuilder` in `scripts/visualization/vp5231a_3d_builder.gd`) builds the `National_VP5231A` cabinet (`Vector3(0.38, 0.19, 0.36)`, center `Vector3(0.0, 0.105, 0.0)`, front face `z = +0.181`) positioned at `Vector3(-0.17, 0.0, 0.0)`.
- Coordinate rule: Keep `VP5231A3DBuilder` untouched as the exterior authority and place internal assemblies in chassis-local space under a single `Vector3(-0.17, 0.0, 0.0)` root transform.
- WSL2 rendering baseline: Compatibility renderer, `MSAA_DISABLED`, low-poly procedural geometry, shared materials, and camera frustum/visibility culling.
