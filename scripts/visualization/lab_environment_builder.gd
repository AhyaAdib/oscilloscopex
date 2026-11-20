class_name LabEnvironmentBuilder
extends RefCounted

const LAB_THEMES := [
	{
		"name": "Theme: Daylight Studio",
		"desk_col": Color(0.86, 0.85, 0.82),
		"desk_rough": 0.55,
		"esd_col": Color(0.07, 0.38, 0.68),
		"wall_col": Color(0.88, 0.87, 0.84),
		"bg_col": Color(0.14, 0.16, 0.19),
		"amb_col": Color(0.78, 0.82, 0.88),
		"amb_energy": 0.65,
		"key_col": Color(1.0, 0.98, 0.95),
		"key_energy": 1.35,
		"lamp_on": false,
		"lamp_col": Color(1.0, 0.82, 0.55),
		"lamp_energy": 0.0
	},
	{
		"name": "Theme: Dark Wood + Overhead Lamp",
		"desk_col": Color(0.24, 0.14, 0.08),
		"desk_rough": 0.42,
		"esd_col": Color(0.05, 0.22, 0.38),
		"wall_col": Color(0.11, 0.12, 0.15),
		"bg_col": Color(0.03, 0.04, 0.06),
		"amb_col": Color(0.22, 0.26, 0.34),
		"amb_energy": 0.22,
		"key_col": Color(0.65, 0.74, 0.90),
		"key_energy": 0.30,
		"lamp_on": true,
		"lamp_col": Color(1.0, 0.80, 0.52),
		"lamp_energy": 2.60
	},
	{
		"name": "Theme: Midnight R&D Neon",
		"desk_col": Color(0.12, 0.13, 0.16),
		"desk_rough": 0.38,
		"esd_col": Color(0.04, 0.28, 0.42),
		"wall_col": Color(0.07, 0.09, 0.13),
		"bg_col": Color(0.02, 0.03, 0.05),
		"amb_col": Color(0.18, 0.32, 0.45),
		"amb_energy": 0.28,
		"key_col": Color(0.55, 0.85, 1.0),
		"key_energy": 0.45,
		"lamp_on": true,
		"lamp_col": Color(0.35, 0.92, 1.0),
		"lamp_energy": 2.20
	},
	{
		"name": "Theme: Classic University Lab",
		"desk_col": Color(0.56, 0.40, 0.24),
		"desk_rough": 0.58,
		"esd_col": Color(0.08, 0.34, 0.26),
		"wall_col": Color(0.76, 0.78, 0.72),
		"bg_col": Color(0.12, 0.15, 0.14),
		"amb_col": Color(0.75, 0.80, 0.76),
		"amb_energy": 0.58,
		"key_col": Color(1.0, 0.96, 0.86),
		"key_energy": 1.15,
		"lamp_on": false,
		"lamp_col": Color(1.0, 0.90, 0.70),
		"lamp_energy": 0.0
	}
]

static func build_studio_workbench(parent: Node) -> Dictionary:
	var env_root := Node3D.new()
	env_root.name = "StudioElectronicsLab"
	parent.add_child(env_root)

	# 1. Electronics Lab Desk + Steel Frame Legs
	var desk := _add_box(env_root, Vector3(1.85, 0.04, 1.12), Vector3(0.02, -0.02, 0.14), Color(0.86, 0.85, 0.82), 0.55)
	for lx in [-0.82, 0.86]:
		for lz in [-0.34, 0.62]:
			_add_box(env_root, Vector3(0.04, 0.72, 0.04), Vector3(lx, -0.38, lz), Color(0.18, 0.20, 0.23), 0.45)

	# 2. ESD Anti-Static Mat + Grounding Snap Puck + Precision Stylus
	var esd := _add_box(env_root, Vector3(1.12, 0.003, 0.68), Vector3(0.02, 0.0015, 0.18), Color(0.07, 0.38, 0.68), 0.60)
	_add_box(env_root, Vector3(0.032, 0.010, 0.038), Vector3(0.45, 0.007, 0.44), Color(0.11, 0.12, 0.14), 0.45)
	_add_cyl(env_root, 0.004, 0.004, Vector3(0.45, 0.013, 0.44), Color(0.85, 0.72, 0.22), 0.25, 0.85)
	var pen := _add_cyl(env_root, 0.0028, 0.11, Vector3(-0.18, 0.0055, 0.16), Color(0.14, 0.16, 0.20), 0.35, 0.4)
	pen.rotation.z = PI * 0.5

	# 3. Studio Wall + Wall-Mounted Widescreen Monitor + Vertical Patch Cables
	var wall := _add_box(env_root, Vector3(2.4, 1.35, 0.04), Vector3(0.02, 0.58, -0.26), Color(0.88, 0.87, 0.84), 0.85)
	_add_box(env_root, Vector3(0.04, 0.48, 0.03), Vector3(-0.34, 0.24, -0.22), Color(0.10, 0.11, 0.13), 0.4)
	_add_box(env_root, Vector3(0.58, 0.34, 0.024), Vector3(-0.16, 0.43, -0.20), Color(0.09, 0.10, 0.12), 0.35)
	var mon_scr := _add_box(env_root, Vector3(0.55, 0.31, 0.003), Vector3(-0.16, 0.43, -0.187), Color(0.04, 0.06, 0.09), 0.15)
	var scr_mat := StandardMaterial3D.new()
	scr_mat.albedo_color = Color(0.04, 0.06, 0.09)
	scr_mat.emission_enabled = true
	scr_mat.emission = Color(0.05, 0.14, 0.22)
	scr_mat.emission_energy_multiplier = 0.75
	mon_scr.material_override = scr_mat

	var cable_colors := [
		Color(0.85, 0.20, 0.18), Color(0.18, 0.65, 0.32), Color(0.92, 0.76, 0.16),
		Color(0.18, 0.45, 0.85), Color(0.15, 0.16, 0.18), Color(0.88, 0.42, 0.14)
	]
	for i in range(10):
		var cx := -0.34 + float(i) * 0.036
		_add_cyl(env_root, 0.0024, 0.26, Vector3(cx, 0.14, -0.215), cable_colors[i % cable_colors.size()], 0.5)

	# 4. Articulated Overhead Desk Task Lamp (illuminates bench in Dark Wood / Midnight themes)
	var lamp_arm := Node3D.new()
	lamp_arm.position = Vector3(-0.56, 0.0, -0.12)
	env_root.add_child(lamp_arm)
	_add_cyl(lamp_arm, 0.038, 0.016, Vector3(0.0, 0.008, 0.0), Color(0.14, 0.15, 0.17), 0.4, 0.6)
	var strut1 := _add_cyl(lamp_arm, 0.007, 0.32, Vector3(0.04, 0.16, 0.04), Color(0.16, 0.17, 0.19), 0.35, 0.7)
	strut1.rotation = Vector3(0.24, 0.0, -0.22)
	var strut2 := _add_cyl(lamp_arm, 0.006, 0.34, Vector3(0.22, 0.35, 0.16), Color(0.16, 0.17, 0.19), 0.35, 0.7)
	strut2.rotation = Vector3(0.45, 0.0, -1.15)
	# Lamp shade & glowing LED emitter bar hovering above the workbench
	var shade := _add_box(lamp_arm, Vector3(0.26, 0.018, 0.048), Vector3(0.48, 0.40, 0.28), Color(0.12, 0.13, 0.15), 0.35)
	shade.rotation.y = -0.15
	var bulb_bar := _add_box(lamp_arm, Vector3(0.23, 0.005, 0.032), Vector3(0.48, 0.390, 0.28), Color(1.0, 0.85, 0.60), 0.2)
	bulb_bar.rotation.y = -0.15
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1.0, 0.88, 0.68)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.80, 0.52)
	bulb_mat.emission_energy_multiplier = 0.0
	bulb_bar.material_override = bulb_mat

	var task_light := OmniLight3D.new()
	task_light.position = Vector3(-0.04, 0.36, 0.18)
	task_light.omni_range = 1.65
	task_light.omni_attenuation = 1.15
	task_light.light_color = Color(1.0, 0.80, 0.52)
	task_light.light_energy = 0.0
	task_light.shadow_enabled = true
	env_root.add_child(task_light)

	# 5. Detailed Handheld Yellow Digital Multimeter (Fluke-style DMM on Left ESD Mat)
	var hdmm := Node3D.new()
	hdmm.position = Vector3(-0.40, 0.018, 0.29)
	hdmm.rotation = Vector3(-0.32, 0.38, 0.0)
	env_root.add_child(hdmm)
	# Yellow protective rubber holster + dark grey inner chassis
	_add_box(hdmm, Vector3(0.086, 0.032, 0.165), Vector3(0, 0, 0), Color(0.95, 0.74, 0.10), 0.55)
	_add_box(hdmm, Vector3(0.072, 0.034, 0.150), Vector3(0, 0.001, 0), Color(0.16, 0.17, 0.20), 0.45)
	# Backlit LCD display window
	var hdmm_lcd := _add_box(hdmm, Vector3(0.056, 0.003, 0.036), Vector3(0, 0.0185, -0.044), Color(0.08, 0.22, 0.18), 0.2)
	var hlcd_mat := StandardMaterial3D.new()
	hlcd_mat.albedo_color = Color(0.08, 0.22, 0.18)
	hlcd_mat.emission_enabled = true
	hlcd_mat.emission = Color(0.18, 0.75, 0.58)
	hlcd_mat.emission_energy_multiplier = 0.85
	hdmm_lcd.material_override = hlcd_mat
	# Yellow function pushbuttons row
	for bx in [-0.018, -0.006, 0.006, 0.018]:
		_add_box(hdmm, Vector3(0.008, 0.004, 0.006), Vector3(bx, 0.019, -0.018), Color(0.95, 0.76, 0.12), 0.4)
	# Central Rotary Range Selector Dial + Indicator Bar
	_add_cyl(hdmm, 0.019, 0.008, Vector3(0, 0.020, 0.010), Color(0.22, 0.24, 0.28), 0.35)
	_add_box(hdmm, Vector3(0.004, 0.010, 0.034), Vector3(0, 0.021, 0.010), Color(0.92, 0.93, 0.95), 0.3)
	# 3 Shrouded Banana Input Jacks (10A Red, COM Black, V/Ohm Red)
	var jack_specs := [
		[-0.020, Color(0.85, 0.15, 0.15)],
		[0.0, Color(0.10, 0.11, 0.13)],
		[0.020, Color(0.85, 0.15, 0.15)]
	]
	for js in jack_specs:
		_add_cyl(hdmm, 0.0055, 0.006, Vector3(js[0], 0.019, 0.054), js[1], 0.35)
		_add_cyl(hdmm, 0.0025, 0.007, Vector3(js[0], 0.0195, 0.054), Color(0.82, 0.72, 0.28), 0.25, 0.85)

	# 6. Companion Modern Widescreen DSO Unit (Center-Back)
	var dso_root := Node3D.new()
	dso_root.position = Vector3(0.02, 0.0, 0.01)
	env_root.add_child(dso_root)
	_add_box(dso_root, Vector3(0.24, 0.135, 0.12), Vector3(0.0, 0.0675, 0.0), Color(0.15, 0.16, 0.18), 0.45)
	var dso_lcd := _add_box(dso_root, Vector3(0.135, 0.095, 0.003), Vector3(-0.04, 0.072, 0.061), Color(0.03, 0.07, 0.11), 0.15)
	var dso_mat := StandardMaterial3D.new()
	dso_mat.albedo_color = Color(0.03, 0.07, 0.11)
	dso_mat.emission_enabled = true
	dso_mat.emission = Color(0.06, 0.22, 0.34)
	dso_mat.emission_energy_multiplier = 0.80
	dso_lcd.material_override = dso_mat
	for ky in [0.095, 0.068, 0.042]:
		_add_cyl(dso_root, 0.007, 0.012, Vector3(0.065, ky, 0.064), Color(0.22, 0.24, 0.27), 0.4).rotation.x = PI * 0.5
	for bx in [-0.08, -0.045, -0.01, 0.025]:
		_add_cyl(dso_root, 0.0055, 0.014, Vector3(bx, 0.014, 0.065), Color(0.78, 0.80, 0.83), 0.25, 0.85).rotation.x = PI * 0.5

	# 7. Wooden Plywood Instrument Shelf Rack (Right Side) + Detailed Benchtop DMM & Dual PSU
	var rack_x := 0.25
	var rack_z := 0.04
	var wood_col := Color(0.76, 0.62, 0.44)
	_add_box(env_root, Vector3(0.016, 0.38, 0.24), Vector3(rack_x - 0.145, 0.19, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.016, 0.38, 0.24), Vector3(rack_x + 0.145, 0.19, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.306, 0.016, 0.24), Vector3(rack_x, 0.175, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.306, 0.016, 0.24), Vector3(rack_x, 0.375, rack_z), wood_col, 0.72)

	# Top Shelf: Detailed Benchtop Digital Multimeter (VFD readout + button keypad + HI/LO terminals)
	_add_box(env_root, Vector3(0.25, 0.082, 0.21), Vector3(rack_x, 0.325, rack_z), Color(0.82, 0.81, 0.77), 0.45)
	_add_box(env_root, Vector3(0.236, 0.072, 0.004), Vector3(rack_x, 0.325, rack_z + 0.105), Color(0.22, 0.24, 0.27), 0.4)
	var dmm_disp := _add_box(env_root, Vector3(0.115, 0.028, 0.003), Vector3(rack_x - 0.048, 0.338, rack_z + 0.108), Color(0.04, 0.16, 0.12), 0.2)
	var dmm_mat := StandardMaterial3D.new()
	dmm_mat.albedo_color = Color(0.04, 0.16, 0.12)
	dmm_mat.emission_enabled = true
	dmm_mat.emission = Color(0.12, 0.75, 0.52)
	dmm_mat.emission_energy_multiplier = 0.95
	dmm_disp.material_override = dmm_mat
	for col_b in range(5):
		for row_b in range(2):
			_add_box(env_root, Vector3(0.014, 0.007, 0.004), Vector3(rack_x - 0.088 + float(col_b) * 0.020, 0.312 - float(row_b) * 0.012, rack_z + 0.108), Color(0.75, 0.76, 0.78), 0.4)
	var dmm_jacks := [Color(0.85, 0.15, 0.15), Color(0.12, 0.12, 0.14), Color(0.85, 0.15, 0.15)]
	for idx_j in range(dmm_jacks.size()):
		_add_cyl(env_root, 0.005, 0.011, Vector3(rack_x + 0.095, 0.342 - float(idx_j) * 0.018, rack_z + 0.109), dmm_jacks[idx_j], 0.35).rotation.x = PI * 0.5

	# Middle Shelf: Dual-Channel DC Power Supply (LED readouts + V/A knobs + output binding posts)
	_add_box(env_root, Vector3(0.25, 0.088, 0.21), Vector3(rack_x, 0.232, rack_z), Color(0.22, 0.24, 0.27), 0.45)
	var psu_disp := _add_box(env_root, Vector3(0.105, 0.042, 0.003), Vector3(rack_x - 0.052, 0.238, rack_z + 0.106), Color(0.05, 0.11, 0.20), 0.2)
	var psu_mat := StandardMaterial3D.new()
	psu_mat.albedo_color = Color(0.05, 0.11, 0.20)
	psu_mat.emission_enabled = true
	psu_mat.emission = Color(0.22, 0.62, 1.0)
	psu_mat.emission_energy_multiplier = 0.90
	psu_disp.material_override = psu_mat
	for kx in [0.025, 0.062]:
		_add_cyl(env_root, 0.0085, 0.012, Vector3(rack_x + kx, 0.248, rack_z + 0.109), Color(0.14, 0.15, 0.18), 0.35).rotation.x = PI * 0.5
		_add_cyl(env_root, 0.0065, 0.012, Vector3(rack_x + kx, 0.222, rack_z + 0.109), Color(0.14, 0.15, 0.18), 0.35).rotation.x = PI * 0.5
	for px in [0.020, 0.045, 0.070]:
		var pc := Color(0.85, 0.15, 0.15) if px != 0.045 else Color(0.16, 0.68, 0.32)
		_add_cyl(env_root, 0.0045, 0.011, Vector3(rack_x + px, 0.198, rack_z + 0.109), pc, 0.35).rotation.x = PI * 0.5

	# 8. Detailed Analog Panel Meter Unit + Bench Soldering Iron Stand (Right Side)
	var meter_root := Node3D.new()
	meter_root.position = Vector3(0.49, 0.0, 0.15)
	meter_root.rotation.y = -0.35
	env_root.add_child(meter_root)
	_add_box(meter_root, Vector3(0.115, 0.155, 0.10), Vector3(0.0, 0.0775, 0.0), Color(0.30, 0.32, 0.35), 0.45)
	_add_box(meter_root, Vector3(0.092, 0.068, 0.004), Vector3(0.0, 0.108, 0.051), Color(0.95, 0.94, 0.90), 0.25)
	# Meter scale arc & physical pointer needle
	_add_box(meter_root, Vector3(0.068, 0.003, 0.002), Vector3(0.0, 0.122, 0.0535), Color(0.12, 0.12, 0.14), 0.4)
	var needle := _add_box(meter_root, Vector3(0.002, 0.036, 0.002), Vector3(-0.008, 0.106, 0.0535), Color(0.85, 0.14, 0.14), 0.3)
	needle.rotation.z = 0.32
	for b_x in [-0.026, 0.0, 0.026]:
		var b_c := Color(0.85, 0.15, 0.15) if b_x != 0.0 else Color(0.12, 0.12, 0.14)
		_add_cyl(meter_root, 0.0055, 0.014, Vector3(b_x, 0.032, 0.055), b_c, 0.35).rotation.x = PI * 0.5

	# Compact Solder Spool + Precision Tweezers near right edge of mat
	_add_cyl(env_root, 0.018, 0.032, Vector3(0.45, 0.018, 0.32), Color(0.18, 0.42, 0.78), 0.45)
	_add_cyl(env_root, 0.014, 0.022, Vector3(0.45, 0.018, 0.32), Color(0.76, 0.78, 0.80), 0.25, 0.85)

	# 9. Wall-Mounted BNC & Banana Test Lead Hanging Rack (Far Right Wall)
	var hanger := _add_box(env_root, Vector3(0.18, 0.012, 0.045), Vector3(0.68, 0.48, -0.22), Color(0.14, 0.15, 0.18), 0.4)
	hanger.rotation.y = -0.25
	var lead_cols := [Color(0.88, 0.16, 0.16), Color(0.14, 0.15, 0.17), Color(0.92, 0.78, 0.16), Color(0.16, 0.68, 0.34)]
	for k in range(8):
		var lx := 0.61 + float(k) * 0.020
		var l_len := 0.34 + float(k % 3) * 0.05
		_add_cyl(env_root, 0.0020, l_len, Vector3(lx, 0.48 - l_len * 0.5, -0.205), lead_cols[k % lead_cols.size()], 0.45)

	return {
		"desk_mat": desk.material_override,
		"esd_mat": esd.material_override,
		"wall_mat": wall.material_override,
		"bulb_mat": bulb_mat,
		"task_light": task_light
	}

static func apply_theme(env_data: Dictionary, world_env: WorldEnvironment, key_light: DirectionalLight3D, theme_idx: int) -> void:
	if env_data.is_empty():
		return
	var cfg: Dictionary = LAB_THEMES[clampi(theme_idx, 0, LAB_THEMES.size() - 1)]
	var desk_mat: StandardMaterial3D = env_data["desk_mat"]
	var esd_mat: StandardMaterial3D = env_data["esd_mat"]
	var wall_mat: StandardMaterial3D = env_data["wall_mat"]
	var bulb_mat: StandardMaterial3D = env_data["bulb_mat"]
	var task_light: OmniLight3D = env_data["task_light"]

	desk_mat.albedo_color = cfg["desk_col"]
	desk_mat.roughness = float(cfg["desk_rough"])
	esd_mat.albedo_color = cfg["esd_col"]
	wall_mat.albedo_color = cfg["wall_col"]

	var lamp_on := bool(cfg["lamp_on"])
	bulb_mat.emission = cfg["lamp_col"]
	bulb_mat.emission_energy_multiplier = 2.8 if lamp_on else 0.0
	task_light.light_color = cfg["lamp_col"]
	task_light.light_energy = float(cfg["lamp_energy"]) if lamp_on else 0.0

	if world_env != null and world_env.environment != null:
		world_env.environment.background_color = cfg["bg_col"]
		world_env.environment.ambient_light_color = cfg["amb_col"]
		world_env.environment.ambient_light_energy = float(cfg["amb_energy"])
	if key_light != null:
		key_light.light_color = cfg["key_col"]
		key_light.light_energy = float(cfg["key_energy"])

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
