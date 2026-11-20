class_name LabEnvironmentBuilder
extends RefCounted

static func build_studio_workbench(parent: Node) -> void:
	var env_root := Node3D.new()
	env_root.name = "StudioElectronicsLab"
	parent.add_child(env_root)

	# 1. White Laminate Electronics Lab Desk + Steel Frame Legs
	var desk := _add_box(env_root, Vector3(1.85, 0.04, 1.12), Vector3(0.02, -0.02, 0.14), Color(0.86, 0.85, 0.82), 0.55)
	for lx in [-0.82, 0.86]:
		for lz in [-0.34, 0.62]:
			_add_box(env_root, Vector3(0.04, 0.72, 0.04), Vector3(lx, -0.38, lz), Color(0.18, 0.20, 0.23), 0.45)

	# 2. Royal-Blue ESD Anti-Static Mat + Grounding Snap Puck (bottom-right) + Bench Stylus
	_add_box(env_root, Vector3(1.12, 0.003, 0.68), Vector3(0.02, 0.0015, 0.18), Color(0.07, 0.38, 0.68), 0.60)
	# ESD Grounding Snap Puck & Cord on lower-right corner of mat
	_add_box(env_root, Vector3(0.032, 0.010, 0.038), Vector3(0.45, 0.007, 0.44), Color(0.11, 0.12, 0.14), 0.45)
	_add_cyl(env_root, 0.004, 0.004, Vector3(0.45, 0.013, 0.44), Color(0.85, 0.72, 0.22), 0.25, 0.85)
	# Precision Screwdriver / Stylus resting above breadboard
	var pen := _add_cyl(env_root, 0.0028, 0.11, Vector3(-0.18, 0.0055, 0.16), Color(0.14, 0.16, 0.20), 0.35, 0.4)
	pen.rotation.z = PI * 0.5

	# 3. Studio Wall + Wall-Mounted Widescreen Reference Monitor + Vertical Ribbon Cables
	_add_box(env_root, Vector3(2.4, 1.35, 0.04), Vector3(0.02, 0.58, -0.26), Color(0.88, 0.87, 0.84), 0.85)
	# Monitor VESA Column & Widescreen Bezel
	_add_box(env_root, Vector3(0.04, 0.48, 0.03), Vector3(-0.34, 0.24, -0.22), Color(0.10, 0.11, 0.13), 0.4)
	_add_box(env_root, Vector3(0.58, 0.34, 0.024), Vector3(-0.16, 0.43, -0.20), Color(0.09, 0.10, 0.12), 0.35)
	# Glossy Dark Monitor Screen with subtle Lab Code/Schematic glow
	var mon_scr := _add_box(env_root, Vector3(0.55, 0.31, 0.003), Vector3(-0.16, 0.43, -0.187), Color(0.04, 0.06, 0.09), 0.15)
	var scr_mat := StandardMaterial3D.new()
	scr_mat.albedo_color = Color(0.04, 0.06, 0.09)
	scr_mat.emission_enabled = true
	scr_mat.emission = Color(0.05, 0.12, 0.18)
	scr_mat.emission_energy_multiplier = 0.65
	mon_scr.material_override = scr_mat

	# Colorful Vertical Patch Cables hanging behind monitor
	var cable_colors := [
		Color(0.85, 0.20, 0.18), Color(0.18, 0.65, 0.32), Color(0.92, 0.76, 0.16),
		Color(0.18, 0.45, 0.85), Color(0.15, 0.16, 0.18), Color(0.88, 0.42, 0.14)
	]
	for i in range(10):
		var cx := -0.34 + float(i) * 0.036
		var col: Color = cable_colors[i % cable_colors.size()]
		_add_cyl(env_root, 0.0024, 0.26, Vector3(cx, 0.14, -0.215), col, 0.5)

	# 4. Companion Modern Widescreen DSO Preview Unit on Bench (Center-Left Back, next to VP-5231A)
	var dso_root := Node3D.new()
	dso_root.position = Vector3(0.02, 0.0, 0.01)
	env_root.add_child(dso_root)
	_add_box(dso_root, Vector3(0.24, 0.135, 0.12), Vector3(0.0, 0.0675, 0.0), Color(0.15, 0.16, 0.18), 0.45)
	var dso_lcd := _add_box(dso_root, Vector3(0.135, 0.095, 0.003), Vector3(-0.04, 0.072, 0.061), Color(0.03, 0.07, 0.11), 0.15)
	var dso_mat := StandardMaterial3D.new()
	dso_mat.albedo_color = Color(0.03, 0.07, 0.11)
	dso_mat.emission_enabled = true
	dso_mat.emission = Color(0.06, 0.20, 0.30)
	dso_mat.emission_energy_multiplier = 0.75
	dso_lcd.material_override = dso_mat
	for ky in [0.095, 0.068, 0.042]:
		_add_cyl(dso_root, 0.007, 0.012, Vector3(0.065, ky, 0.064), Color(0.22, 0.24, 0.27), 0.4).rotation.x = PI * 0.5
	for bx in [-0.08, -0.045, -0.01, 0.025]:
		_add_cyl(dso_root, 0.0055, 0.014, Vector3(bx, 0.014, 0.065), Color(0.75, 0.77, 0.80), 0.25, 0.85).rotation.x = PI * 0.5

	# 5. Wooden Plywood Instrument Shelf Rack (Right Side, housing DMM + PSU above Siglent FG)
	var rack_x := 0.25
	var rack_z := 0.04
	var wood_col := Color(0.76, 0.62, 0.44)
	# Left & Right plywood walls + Top & Middle shelves
	_add_box(env_root, Vector3(0.016, 0.38, 0.24), Vector3(rack_x - 0.145, 0.19, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.016, 0.38, 0.24), Vector3(rack_x + 0.145, 0.19, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.306, 0.016, 0.24), Vector3(rack_x, 0.175, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.306, 0.016, 0.24), Vector3(rack_x, 0.375, rack_z), wood_col, 0.72)

	# Upper Shelf: Benchtop Digital Multimeter (Beige/Grey) + Programmable DC Power Supply
	_add_box(env_root, Vector3(0.25, 0.082, 0.21), Vector3(rack_x, 0.325, rack_z), Color(0.82, 0.81, 0.77), 0.45)
	var dmm_disp := _add_box(env_root, Vector3(0.11, 0.028, 0.003), Vector3(rack_x - 0.045, 0.338, rack_z + 0.106), Color(0.05, 0.18, 0.14), 0.2)
	var dmm_mat := StandardMaterial3D.new()
	dmm_mat.albedo_color = Color(0.05, 0.18, 0.14)
	dmm_mat.emission_enabled = true
	dmm_mat.emission = Color(0.12, 0.65, 0.48)
	dmm_mat.emission_energy_multiplier = 0.9
	dmm_disp.material_override = dmm_mat
	for j_col in [Color(0.85, 0.15, 0.15), Color(0.12, 0.12, 0.14), Color(0.85, 0.15, 0.15)]:
		var idx_j := 0
		_add_cyl(env_root, 0.005, 0.010, Vector3(rack_x + 0.095, 0.335 - float(idx_j) * 0.018, rack_z + 0.108), j_col, 0.35).rotation.x = PI * 0.5

	# Lower-Upper Shelf: Benchtop DC Power Supply
	_add_box(env_root, Vector3(0.25, 0.088, 0.21), Vector3(rack_x, 0.232, rack_z), Color(0.24, 0.26, 0.29), 0.45)
	var psu_disp := _add_box(env_root, Vector3(0.10, 0.042, 0.003), Vector3(rack_x - 0.045, 0.236, rack_z + 0.106), Color(0.06, 0.12, 0.22), 0.2)
	var psu_mat := StandardMaterial3D.new()
	psu_mat.albedo_color = Color(0.06, 0.12, 0.22)
	psu_mat.emission_enabled = true
	psu_mat.emission = Color(0.20, 0.55, 0.95)
	psu_mat.emission_energy_multiplier = 0.85
	psu_disp.material_override = psu_mat

	# 6. Angled Analog Panel Meter Unit (Right of Plywood Rack, matching reference photo)
	var meter_root := Node3D.new()
	meter_root.position = Vector3(0.49, 0.0, 0.16)
	meter_root.rotation.y = -0.35
	env_root.add_child(meter_root)
	_add_box(meter_root, Vector3(0.11, 0.15, 0.10), Vector3(0.0, 0.075, 0.0), Color(0.32, 0.34, 0.37), 0.45)
	_add_box(meter_root, Vector3(0.088, 0.065, 0.004), Vector3(0.0, 0.105, 0.051), Color(0.94, 0.93, 0.89), 0.3)
	for b_x in [-0.025, 0.0, 0.025]:
		var b_c := Color(0.85, 0.15, 0.15) if b_x != 0.0 else Color(0.12, 0.12, 0.14)
		_add_cyl(meter_root, 0.0055, 0.014, Vector3(b_x, 0.032, 0.055), b_c, 0.35).rotation.x = PI * 0.5

	# 7. Wall-Mounted BNC & Banana Test Lead Hanging Rack (Far Right Wall)
	var hanger := _add_box(env_root, Vector3(0.18, 0.012, 0.045), Vector3(0.68, 0.48, -0.22), Color(0.14, 0.15, 0.18), 0.4)
	hanger.rotation.y = -0.25
	var lead_cols := [Color(0.88, 0.16, 0.16), Color(0.14, 0.15, 0.17), Color(0.92, 0.78, 0.16), Color(0.16, 0.68, 0.34)]
	for k in range(8):
		var lx := 0.61 + float(k) * 0.020
		var l_len := 0.34 + float(k % 3) * 0.05
		_add_cyl(env_root, 0.0020, l_len, Vector3(lx, 0.48 - l_len * 0.5, -0.205), lead_cols[k % lead_cols.size()], 0.45)

static func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, col: Color, rough := 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, rad: float, h: float, pos: Vector3, col: Color, rough := 0.5, metal := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rad
	cm.bottom_radius = rad
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	mat.metallic = metal
	mi.material_override = mat
	parent.add_child(mi)
	return mi
