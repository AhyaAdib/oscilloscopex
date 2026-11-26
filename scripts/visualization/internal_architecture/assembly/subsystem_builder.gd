class_name SubsystemBuilder
extends RefCounted

static func build_all_55_parts(assembly_root: Node3D) -> Array:
	var records := []
	var tex_grat := ProceduralCadTextures.create_graticule_texture()
	var tex_front := ProceduralCadTextures.create_front_panel_texture()
	var tex_badge := ProceduralCadTextures.create_header_badge_texture()
	var tex_pcb_main := ProceduralCadTextures.create_pcb_texture(Color(0.12, 0.34, 0.19), Color(0.29, 0.87, 0.50))
	var tex_pcb_vert := ProceduralCadTextures.create_pcb_texture(Color(0.09, 0.40, 0.20), Color(0.53, 0.94, 0.67))
	var tex_pcb_psu := ProceduralCadTextures.create_pcb_texture(Color(0.47, 0.21, 0.06), Color(0.98, 0.75, 0.14))
	var tex_pcb_hv := ProceduralCadTextures.create_pcb_texture(Color(0.50, 0.11, 0.11), Color(0.99, 0.65, 0.65))

	var mat_panel_silver := ComponentFactory.make_dual_mat(0xc8c5be, 0xf8fafc, 0.44, 0.36, tex_front)
	var mat_header := ComponentFactory.make_dual_mat(0x2d2d2a, 0x334155, 0.40, 0.30, tex_badge)
	var mat_bezel_cream := ComponentFactory.make_dual_mat(0xdfd1b8, 0xf1f5f9, 0.65, 0.06)
	var mat_knob_charcoal := ComponentFactory.make_dual_mat(0x292826, 0x475569, 0.42, 0.15)
	var mat_knob_cap := ComponentFactory.make_dual_mat(0x9ca3af, 0xe2e8f0, 0.30, 0.65)
	var mat_knob_beige := ComponentFactory.make_dual_mat(0xc8b99c, 0xf1f5f9, 0.48, 0.08)
	var mat_pointer := ComponentFactory.make_dual_mat(0xf8fafc, 0x0f172a, 0.40, 0.05)
	var mat_switch_cream := ComponentFactory.make_dual_mat(0xdad2c0, 0xffffff, 0.50, 0.05)
	var mat_chrome := ComponentFactory.make_dual_mat(0xd1d5db, 0xe2e8f0, 0.22, 0.85)
	var mat_steel := ComponentFactory.make_dual_mat(0x94a3b8, 0xf1f5f9, 0.42, 0.55)
	var mat_cabinet := ComponentFactory.make_dual_mat(0x9e9b93, 0xe2e8f0, 0.56, 0.28)
	var mat_dark_rear := ComponentFactory.make_dual_mat(0x374151, 0xe2e8f0, 0.50, 0.40)
	var mat_graticule := ComponentFactory.make_dual_mat(0x2994b2, 0xdbeafe, 0.15, 0.08, tex_grat, 0.85)
	var mat_crt_glass := ComponentFactory.make_dual_mat(0xcbd5e1, 0xf8fafc, 0.15, 0.10, null, 0.42)
	var mat_mumetal := ComponentFactory.make_dual_mat(0x4b5563, 0xd1d5db, 0.34, 0.72)
	var mat_copper := ComponentFactory.make_dual_mat(0xb45309, 0xfde68a, 0.28, 0.82)
	var mat_brass := ComponentFactory.make_dual_mat(0xca8a04, 0xfef08a, 0.30, 0.78)
	var mat_rubber := ComponentFactory.make_dual_mat(0x1f201e, 0x334155, 0.82, 0.05)
	var mat_ceramic := ComponentFactory.make_dual_mat(0xf1f5f9, 0xffffff, 0.35, 0.05)
	var mat_amber := ComponentFactory.make_dual_mat(0xf59e0b, 0xfef3c7, 0.20, 0.10)
	var mat_pcb_green := ComponentFactory.make_dual_mat(0x1e5631, 0xecfdf5, 0.55, 0.15, tex_pcb_main)
	var mat_pcb_vert := ComponentFactory.make_dual_mat(0x166534, 0xf0fdf4, 0.55, 0.15, tex_pcb_vert)
	var mat_pcb_psu := ComponentFactory.make_dual_mat(0x78350f, 0xfffbeb, 0.55, 0.15, tex_pcb_psu)
	var mat_pcb_hv := ComponentFactory.make_dual_mat(0x7f1d1d, 0xfef2f2, 0.55, 0.15, tex_pcb_hv)

	for cfg in ArchitectureRegistry.PARTS:
		var id: int = cfg["id"]
		var node := Node3D.new()
		node.name = "Part_%02d_%s" % [id, cfg["code"]]
		node.position = (cfg["base"] as Vector3) * ComponentFactory.CAD_SCALE
		assembly_root.add_child(node)

		match id:
			1:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.38, 0.24, 0.20)), mat_bezel_cream, Vector3(0, 0.96, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.38, 0.24, 0.20)), mat_bezel_cream, Vector3(0, -0.96, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.24, 1.68, 0.20)), mat_bezel_cream, Vector3(-1.07, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.24, 1.68, 0.20)), mat_bezel_cream, Vector3(1.07, 0, 0))
			2:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.36, 0.26, 0.06)), mat_header, Vector3.ZERO)
			3:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.94, 1.62, 0.04)), mat_graticule, Vector3.ZERO)
			4:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.96, 3.24, 0.07)), mat_panel_silver, Vector3(1.22, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.44, 0.64, 0.07)), mat_panel_silver, Vector3(-1.18, -1.30, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.44, 0.34, 0.07)), mat_panel_silver, Vector3(-1.18, 1.45, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.18, 2.26, 0.07)), mat_panel_silver, Vector3(-2.31, 0.15, 0))
			5:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.08, 0.08, 0.22, 16), mat_knob_charcoal, Vector3(0, 0.05, 0), Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.sphere(0.055, 12), mat_amber, Vector3(0, -0.14, 0.02), Vector3.ZERO, false)
			6:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.04, 0.04, 0.20, 12), mat_chrome, Vector3(0, 0.03, 0), Vector3(PI * 0.5, 0, 0))
			7:
				ComponentFactory.add_fluted_knob(node, 0.13, 0.26, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3(-0.42, 0, 0))
				ComponentFactory.add_fluted_knob(node, 0.13, 0.26, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3(0.0, 0, 0))
				ComponentFactory.add_fluted_knob(node, 0.13, 0.26, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3(0.44, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.045, 0.045, 0.08, 12), mat_brass, Vector3(0.22, -0.10, -0.05), Vector3(PI * 0.5, 0, 0))
			8:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.09, 0.09, 0.24, 16), mat_rubber, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.05, 0.05, 0.28, 12), mat_brass, Vector3(0, 0, 0.02), Vector3(PI * 0.5, 0, 0), false)
			9:
				ComponentFactory.add_fluted_knob(node, 0.15, 0.28, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3.ZERO)
			10:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.11, 0.16, 0.18)), mat_switch_cream, Vector3(-0.36, 0.05, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.11, 0.16, 0.18)), mat_switch_cream, Vector3(0.02, -0.04, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.11, 0.16, 0.18)), mat_switch_cream, Vector3(0.38, 0.08, 0))
			11:
				ComponentFactory.add_fluted_knob(node, 0.14, 0.28, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3(-0.22, -0.02, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.11, 0.15, 0.18)), mat_switch_cream, Vector3(0.24, -0.05, -0.02))
			12:
				ComponentFactory.add_fluted_knob(node, 0.14, 0.28, mat_knob_beige, mat_knob_cap, mat_pointer, Vector3.ZERO)
			13:
				ComponentFactory.add_fluted_knob(node, 0.22, 0.32, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3.ZERO)
			14:
				ComponentFactory.add_bnc_connector(node, mat_chrome, mat_ceramic, Vector3.ZERO, 0.0)
			15:
				ComponentFactory.add_fluted_knob(node, 0.13, 0.26, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3(-0.28, 0, 0))
				ComponentFactory.add_fluted_knob(node, 0.13, 0.26, mat_knob_beige, mat_knob_cap, mat_pointer, Vector3(0.28, 0, 0))
			16:
				ComponentFactory.add_fluted_knob(node, 0.21, 0.32, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3.ZERO)
			17:
				ComponentFactory.add_bnc_connector(node, mat_chrome, mat_ceramic, Vector3(-0.28, 0, 0), 0.0)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.14, 0.11, 0.18)), mat_switch_cream, Vector3(0.24, 0, 0.04))
			18:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.13, 0.18, 0.24)), mat_switch_cream, Vector3(0, 0.34, 0.04))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.06, 0.92, 0.04)), mat_rubber, Vector3(0, 0, -0.02), Vector3.ZERO, false)
			19:
				ComponentFactory.add_fluted_knob(node, 0.13, 0.26, mat_knob_beige, mat_knob_cap, mat_pointer, Vector3(-0.28, 0, 0))
				ComponentFactory.add_fluted_knob(node, 0.13, 0.26, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3(0.28, 0, 0))
			20:
				ComponentFactory.add_fluted_knob(node, 0.21, 0.32, mat_knob_charcoal, mat_knob_cap, mat_pointer, Vector3.ZERO)
			21:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.14, 0.11, 0.18)), mat_switch_cream, Vector3(-0.24, 0, 0.04))
				ComponentFactory.add_bnc_connector(node, mat_chrome, mat_ceramic, Vector3(0.28, 0, 0), 0.0)
			22:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.75, 0.12, 0.14)), mat_chrome, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.sphere(0.055, 10), mat_amber, Vector3(-0.55, -0.04, 0), Vector3.ZERO, false)
				ComponentFactory.add_part_mesh(node, ComponentFactory.sphere(0.055, 10), mat_amber, Vector3(0.55, -0.04, 0), Vector3.ZERO, false)
			23:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.98, 0.12, 0.14)), mat_rubber, Vector3(0, 0.80, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.98, 0.12, 0.14)), mat_rubber, Vector3(0, -0.80, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.12, 1.48, 0.14)), mat_rubber, Vector3(-0.93, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.12, 1.48, 0.14)), mat_rubber, Vector3(0.93, 0, 0))
			24:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.86, 1.52, 0.42)), mat_crt_glass, Vector3(0, 0, 1.18))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.36, 0.95, 1.15, 4), mat_crt_glass, Vector3(0, 0, 0.42), Vector3(PI * 0.5, PI * 0.25, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.32, 0.34, 1.35, 20), mat_crt_glass, Vector3(0, 0, -0.78), Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.16, 0.18, 0.85, 14), mat_chrome, Vector3(0, 0, -0.65), Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.08, 0.08, 0.08, 12), mat_brass, Vector3(-0.68, 0.25, 0.65), Vector3(0, 0, PI * 0.5))
			25:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.42, 1.02, 1.22, 4), mat_mumetal, Vector3(0, 0, 0.38), Vector3(PI * 0.5, PI * 0.25, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.38, 0.42, 1.25, 20), mat_mumetal, Vector3(0, 0, -0.78), Vector3(PI * 0.5, 0, 0))
			26:
				ComponentFactory.add_part_mesh(node, ComponentFactory.torus(0.36, 0.45), mat_copper, Vector3.ZERO)
			27:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.34, 0.34, 0.24, 18), mat_rubber, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.28, 0.28, 0.14, 14), mat_ceramic, Vector3(0, 0, -0.16), Vector3(PI * 0.5, 0, 0))
			28:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.54, 0.56, 0.72)), mat_chrome, Vector3(-0.66, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.54, 0.56, 0.72)), mat_chrome, Vector3(0.66, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.04, 0.04, 0.45, 12), mat_brass, Vector3(-0.66, 0, 0.48), Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.04, 0.04, 0.45, 12), mat_brass, Vector3(0.66, 0, 0.48), Vector3(PI * 0.5, 0, 0))
			29:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.58, 0.58, 0.78)), mat_brass, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.045, 0.045, 0.45, 12), mat_chrome, Vector3(0, 0, 0.52), Vector3(PI * 0.5, 0, 0))
			30:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.10, 2.15, 2.65)), mat_pcb_vert, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.16, 0.35, 0.45)), mat_knob_charcoal, Vector3(-0.12, 0.45, 0.55))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.16, 0.35, 0.45)), mat_knob_charcoal, Vector3(-0.12, -0.35, 0.55))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.14, 0.14, 0.24, 14), mat_chrome, Vector3(-0.14, 0.62, -0.45), Vector3(0, 0, PI * 0.5))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.14, 0.14, 0.24, 14), mat_chrome, Vector3(-0.14, 0.15, -0.45), Vector3(0, 0, PI * 0.5))
			31:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.24, 0.24, 1.35, 18), mat_copper, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.28, 0.28, 0.08, 18), mat_rubber, Vector3(0, 0, 0.68), Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.28, 0.28, 0.08, 18), mat_rubber, Vector3(0, 0, -0.68), Vector3(PI * 0.5, 0, 0))
			32:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.65, 0.10, 2.25)), mat_pcb_green, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.55, 0.14, 0.22)), mat_knob_charcoal, Vector3(-0.55, 0.12, 0.35))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.55, 0.14, 0.22)), mat_knob_charcoal, Vector3(0.35, 0.12, 0.35))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.11, 0.11, 0.28, 12), mat_steel, Vector3(-0.75, 0.18, -0.45))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.11, 0.11, 0.28, 12), mat_steel, Vector3(-0.35, 0.18, -0.45))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.11, 0.11, 0.28, 12), mat_steel, Vector3(0.65, 0.18, -0.35))
			33:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.45, 0.24, 0.18)), mat_knob_charcoal, Vector3.ZERO)
			34:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.12, 1.15, 0.98)), mat_steel, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.16, 0.42, 0.94)), mat_copper, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.22, 0.08, 1.08)), mat_chrome, Vector3(0, -0.56, 0))
			35:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.18, 0.18, 0.68, 16), mat_chrome, Vector3(-0.32, 0, 0.18))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.18, 0.18, 0.68, 16), mat_chrome, Vector3(0.10, 0, 0.18))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.15, 0.15, 0.62, 16), mat_knob_charcoal, Vector3(-0.32, 0, -0.22))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.15, 0.15, 0.62, 16), mat_knob_charcoal, Vector3(0.10, 0, -0.22))
			36:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.45, 0.10, 2.15)), mat_pcb_psu, Vector3.ZERO)
			37:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.15, 0.10, 1.15)), mat_pcb_hv, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.24, 0.24, 0.34, 18), mat_knob_charcoal, Vector3(-0.22, 0.22, 0.15))
			38:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.24, 0.46, 1.24)), mat_steel, Vector3.ZERO)
			39:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(4.78, 3.12, 0.08)), mat_steel, Vector3(0, 0, 1.62))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.08, 3.08, 3.25)), mat_steel, Vector3(-0.15, 0, 0.02))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(4.76, 0.08, 3.25)), mat_steel, Vector3(0, -1.52, 0.02))
			40:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(4.92, 0.08, 3.42)), mat_cabinet, Vector3(0, 1.62, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.08, 3.26, 3.42)), mat_cabinet, Vector3(-2.44, 0.02, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.08, 3.26, 3.42)), mat_cabinet, Vector3(2.44, 0.02, 0))
				for lx in [-1.6, -1.2, -0.8, -0.4, 0.0, 0.4, 0.8, 1.2, 1.6]:
					ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.24, 0.03, 1.8)), mat_knob_charcoal, Vector3(lx, 1.66, -0.2), Vector3.ZERO, false)
			41:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(5.16, 0.14, 0.24)), mat_chrome, Vector3(0, 1.48, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.12, 1.52, 0.22)), mat_chrome, Vector3(-2.54, 0.76, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.12, 1.52, 0.22)), mat_chrome, Vector3(2.54, 0.76, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.22, 0.22, 0.16, 18), mat_knob_charcoal, Vector3(-2.54, 0, 0), Vector3(0, 0, PI * 0.5))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.22, 0.22, 0.16, 18), mat_knob_charcoal, Vector3(2.54, 0, 0), Vector3(0, 0, PI * 0.5))
			42:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(4.86, 0.06, 3.38)), mat_cabinet, Vector3.ZERO)
				for fp in [Vector2(-2.05, -1.25), Vector2(2.05, -1.25), Vector2(-2.05, 1.25), Vector2(2.05, 1.25)]:
					ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.22, 0.26, 0.16, 14), mat_rubber, Vector3(fp.x, -0.10, fp.y))
			43:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(4.82, 3.16, 0.08)), mat_dark_rear, Vector3.ZERO)
			44:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.68, 0.44, 0.36)), mat_rubber, Vector3.ZERO)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.04, 0.14, 0.18)), mat_brass, Vector3(-0.16, -0.04, -0.12), Vector3.ZERO, false)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.04, 0.14, 0.18)), mat_brass, Vector3(0.16, -0.04, -0.12), Vector3.ZERO, false)
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.04, 0.14, 0.18)), mat_brass, Vector3(0, 0.08, -0.12), Vector3.ZERO, false)
			45:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.16, 0.16, 0.34, 14), mat_rubber, Vector3(-0.18, 0, 0), Vector3(PI * 0.5, 0, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.11, 0.11, 0.38, 14), mat_knob_charcoal, Vector3(0.22, 0, -0.04), Vector3(PI * 0.5, 0, 0))
			46:
				ComponentFactory.add_bnc_connector(node, mat_chrome, mat_ceramic, Vector3(0, 0.45, 0), PI)
				ComponentFactory.add_bnc_connector(node, mat_chrome, mat_ceramic, Vector3(0, 0.0, 0), PI)
				ComponentFactory.add_bnc_connector(node, mat_chrome, mat_ceramic, Vector3(0, -0.45, 0), PI)
			47:
				for bp in [Vector2(-2.18, 1.36), Vector2(2.18, 1.36), Vector2(-2.18, -1.36), Vector2(2.18, -1.36)]:
					ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.16, 0.20, 0.28, 14), mat_rubber, Vector3(bp.x, bp.y, 0), Vector3(PI * 0.5, 0, 0))
			48:
				for sp in [Vector2(-2.34, 1.54), Vector2(2.34, 1.54), Vector2(-2.34, -1.54), Vector2(2.34, -1.54)]:
					ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.055, 0.055, 0.08, 12), mat_chrome, Vector3(sp.x, sp.y, 0), Vector3(PI * 0.5, 0, 0))
			49:
				ComponentFactory.add_part_mesh(node, ComponentFactory.torus(0.45, 0.51), mat_knob_charcoal, Vector3.ZERO, Vector3(0.4, 0.5, 0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.torus(0.39, 0.44), mat_brass, Vector3(0.1, -0.05, 0.1), Vector3(0.4, 0.5, 0.2))
			50:
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.025, 0.025, 1.25, 8), mat_copper, Vector3.ZERO, Vector3(0, 0, PI / 3.0))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.025, 0.025, 1.25, 8), mat_chrome, Vector3(0, 0.06, 0.05), Vector3(0, 0, PI / 3.0))
			51:
				for pp in [Vector2(-0.85, 0.75), Vector2(0.85, 0.75), Vector2(-0.85, -0.75), Vector2(0.85, -0.75)]:
					ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.055, 0.055, 0.24, 6), mat_brass, Vector3(pp.x, 0, pp.y))
			52:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(2.55, 2.85, 0.05)), mat_steel, Vector3.ZERO)
			53:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.18, 0.65, 0.42)), mat_ceramic, Vector3.ZERO)
			54:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.28, 0.24, 0.62)), mat_knob_charcoal, Vector3.ZERO)
			55:
				ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(1.45, 0.85, 0.05)), mat_steel, Vector3.ZERO)
				# Cooling Fan Shroud + 5 Blades mounted inside rear exhaust cover
				ComponentFactory.add_part_mesh(node, ComponentFactory.torus(0.26, 0.31), mat_knob_charcoal, Vector3(0, 0, 0.04))
				ComponentFactory.add_part_mesh(node, ComponentFactory.cyl(0.09, 0.09, 0.12, 12), mat_chrome, Vector3(0, 0, 0.04), Vector3(PI * 0.5, 0, 0))
				for bi in range(5):
					var a := float(bi) * TAU / 5.0
					ComponentFactory.add_part_mesh(node, ComponentFactory.box(Vector3(0.08, 0.18, 0.015)), mat_chrome, Vector3(cos(a) * 0.16, sin(a) * 0.16, 0.04), Vector3(0.35, 0, a + PI * 0.5), false)

		records.append({
			"id": id,
			"cfg": cfg,
			"node": node,
			"base_pos": (cfg["base"] as Vector3) * ComponentFactory.CAD_SCALE,
			"exp_offset": (cfg["exp"] as Vector3) * ComponentFactory.CAD_SCALE,
			"pin_offset": (cfg["pin"] as Vector3) * ComponentFactory.CAD_SCALE
		})
	return records
