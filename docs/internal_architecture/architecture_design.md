# Milestone 1 Design — 3D Viewport & Chassis Alignment

- Add a `[2D Signal Flow]` / `[3D Physical Architecture]` view switcher in the Internal Architecture tab while preserving the existing 2D schematic and node probe inspector.
- Host an isolated `SubViewport` (`own_world_3d = true`, `MSAA_DISABLED`) with resize handling, perspective camera clipping, basic directional/ambient lighting, an engineering floor grid, a ghosted/translucent chassis shell toggle, and `internal_assembly_root` aligned to `National_VP5231A`.
