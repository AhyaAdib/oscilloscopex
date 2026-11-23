class_name LabEnvironmentBuilder
extends RefCounted

const LAB_THEMES := [
	{
		"name": "Theme: Daylight Studio",
		"is_campus": false,
		"desk_col": Color(0.86, 0.85, 0.82),
		"desk_rough": 0.55,
		"esd_col": Color(0.07, 0.38, 0.68),
		"wall_col": Color(0.88, 0.87, 0.84),
		"bg_col": Color(0.14, 0.16, 0.19),
		"amb_col": Color(0.78, 0.82, 0.88),
		"amb_energy": 0.65,
		"key_col": Color(1.0, 0.98, 0.95),
		"key_energy": 1.35,
		"key_rot": Vector3(-0.75, 0.55, 0.0),
		"lamp_on": false,
		"lamp_col": Color(1.0, 0.82, 0.55),
		"lamp_energy": 0.0
	},
	{
		"name": "Theme: Dark Wood + Overhead Lamp",
		"is_campus": false,
		"desk_col": Color(0.24, 0.14, 0.08),
		"desk_rough": 0.42,
		"esd_col": Color(0.05, 0.22, 0.38),
		"wall_col": Color(0.11, 0.12, 0.15),
		"bg_col": Color(0.03, 0.04, 0.06),
		"amb_col": Color(0.22, 0.26, 0.34),
		"amb_energy": 0.22,
		"key_col": Color(0.65, 0.74, 0.90),
		"key_energy": 0.30,
		"key_rot": Vector3(-0.75, 0.55, 0.0),
		"lamp_on": true,
		"lamp_col": Color(1.0, 0.80, 0.52),
		"lamp_energy": 2.60
	},
	{
		"name": "Theme: Midnight R&D Neon",
		"is_campus": false,
		"desk_col": Color(0.12, 0.13, 0.16),
		"desk_rough": 0.38,
		"esd_col": Color(0.04, 0.28, 0.42),
		"wall_col": Color(0.07, 0.09, 0.13),
		"bg_col": Color(0.02, 0.03, 0.05),
		"amb_col": Color(0.18, 0.32, 0.45),
		"amb_energy": 0.28,
		"key_col": Color(0.55, 0.85, 1.0),
		"key_energy": 0.45,
		"key_rot": Vector3(-0.75, 0.55, 0.0),
		"lamp_on": true,
		"lamp_col": Color(0.35, 0.92, 1.0),
		"lamp_energy": 2.20
	},
	{
		"name": "Theme: Classic University Lab",
		"is_campus": false,
		"desk_col": Color(0.56, 0.40, 0.24),
		"desk_rough": 0.58,
		"esd_col": Color(0.08, 0.34, 0.26),
		"wall_col": Color(0.76, 0.78, 0.72),
		"bg_col": Color(0.12, 0.15, 0.14),
		"amb_col": Color(0.75, 0.80, 0.76),
		"amb_energy": 0.58,
		"key_col": Color(1.0, 0.96, 0.86),
		"key_energy": 1.15,
		"key_rot": Vector3(-0.75, 0.55, 0.0),
		"lamp_on": false,
		"lamp_col": Color(1.0, 0.90, 0.70),
		"lamp_energy": 0.0
	},
	{
		"name": "Theme: PENS Campus Lab (4 PM Sunset)",
		"is_campus": true,
		"desk_col": Color(0.34, 0.21, 0.14),
		"desk_rough": 0.36,
		"esd_col": Color(0.06, 0.26, 0.42),
		"wall_col": Color(0.76, 0.68, 0.66),
		"bg_col": Color(0.36, 0.30, 0.38),
		"amb_col": Color(0.46, 0.39, 0.54),
		"amb_energy": 0.36,
		"key_col": Color(1.0, 0.72, 0.44),
		"key_energy": 2.45,
		"key_rot": Vector3(-0.36, 1.24, 0.0),
		"lamp_on": false,
		"lamp_col": Color(1.0, 0.74, 0.46),
		"lamp_energy": 0.0
	}
]

static func build_studio_workbench(parent: Node) -> Dictionary:
	var env_root := Node3D.new()
	env_root.name = "StudioElectronicsLab"
	parent.add_child(env_root)

	# 1. Primary Workbench Desk + Heavy Frame Legs + Campus Under-Apron AC Outlet Block
	var desk := _add_box(env_root, Vector3(1.85, 0.04, 1.12), Vector3(0.02, -0.02, 0.14), Color(0.86, 0.85, 0.82), 0.55)
	for lx in [-0.82, 0.86]:
		for lz in [-0.34, 0.62]:
			_add_box(env_root, Vector3(0.05, 0.72, 0.05), Vector3(lx, -0.38, lz), Color(0.14, 0.11, 0.09), 0.45)

	var outlet_box := _add_box(env_root, Vector3(0.16, 0.042, 0.032), Vector3(-0.34, -0.062, 0.685), Color(0.86, 0.85, 0.81), 0.4)
	for ox in [-0.052, -0.018, 0.018, 0.052]:
		_add_cyl(outlet_box, 0.011, 0.006, Vector3(ox, 0.0, 0.016), Color(0.16, 0.16, 0.18), 0.4).rotation.x = PI * 0.5

	# 2. ESD Anti-Static Mat + Grounding Snap Puck + Precision Stylus
	var esd := _add_box(env_root, Vector3(1.12, 0.003, 0.68), Vector3(0.02, 0.0015, 0.18), Color(0.07, 0.38, 0.68), 0.60)
	_add_box(env_root, Vector3(0.032, 0.010, 0.038), Vector3(0.45, 0.007, 0.44), Color(0.11, 0.12, 0.14), 0.45)
	_add_cyl(env_root, 0.004, 0.004, Vector3(0.45, 0.013, 0.44), Color(0.85, 0.72, 0.22), 0.25, 0.85)
	var pen := _add_cyl(env_root, 0.0028, 0.11, Vector3(-0.18, 0.0055, 0.16), Color(0.14, 0.16, 0.20), 0.35, 0.4)
	pen.rotation.z = PI * 0.5

	# =========================================================================
	# STUDIO PROPS GROUP
	# =========================================================================
	var studio_group := Node3D.new()
	studio_group.name = "StudioRoomProps"
	env_root.add_child(studio_group)

	var wall := _add_box(studio_group, Vector3(2.4, 1.35, 0.04), Vector3(0.02, 0.58, -0.26), Color(0.88, 0.87, 0.84), 0.85)
	_add_box(studio_group, Vector3(0.04, 0.48, 0.03), Vector3(-0.34, 0.24, -0.22), Color(0.10, 0.11, 0.13), 0.4)
	_add_box(studio_group, Vector3(0.58, 0.34, 0.024), Vector3(-0.16, 0.43, -0.20), Color(0.09, 0.10, 0.12), 0.35)
	var mon_scr := _add_box(studio_group, Vector3(0.55, 0.31, 0.003), Vector3(-0.16, 0.43, -0.187), Color(0.04, 0.06, 0.09), 0.15)
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
		_add_cyl(studio_group, 0.0024, 0.26, Vector3(cx, 0.14, -0.215), cable_colors[i % cable_colors.size()], 0.5)

	# Articulated Overhead Desk Task Lamp
	var lamp_arm := Node3D.new()
	lamp_arm.position = Vector3(-0.56, 0.0, -0.10)
	studio_group.add_child(lamp_arm)

	var p_base := Vector3(0.0, 0.016, 0.0)
	var p_elbow := Vector3(0.05, 0.30, 0.05)
	var p_wrist := Vector3(0.46, 0.44, 0.24)
	var p_head := Vector3(0.46, 0.415, 0.24)

	_add_cyl(lamp_arm, 0.044, 0.016, Vector3(0.0, 0.008, 0.0), Color(0.12, 0.13, 0.15), 0.4, 0.65)
	_add_cyl(lamp_arm, 0.014, 0.024, Vector3(0.0, 0.020, 0.0), Color(0.18, 0.19, 0.22), 0.35, 0.75)
	_add_strut(lamp_arm, p_base, p_elbow, 0.0085, Color(0.15, 0.16, 0.18))
	_add_joint_sphere(lamp_arm, p_elbow, 0.013, Color(0.22, 0.24, 0.28))
	_add_strut(lamp_arm, p_elbow, p_wrist, 0.0075, Color(0.15, 0.16, 0.18))
	_add_joint_sphere(lamp_arm, p_wrist, 0.012, Color(0.22, 0.24, 0.28))
	_add_strut(lamp_arm, p_wrist, p_head, 0.0070, Color(0.18, 0.19, 0.22))

	var shade := _add_box(lamp_arm, Vector3(0.28, 0.018, 0.050), p_head + Vector3(0.0, -0.006, 0.0), Color(0.12, 0.13, 0.15), 0.35)
	shade.rotation.y = -0.14
	var bulb_bar := _add_box(lamp_arm, Vector3(0.25, 0.005, 0.034), p_head + Vector3(0.0, -0.016, 0.0), Color(1.0, 0.85, 0.60), 0.2)
	bulb_bar.rotation.y = -0.14
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1.0, 0.88, 0.68)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.80, 0.52)
	bulb_mat.emission_energy_multiplier = 0.0
	bulb_bar.material_override = bulb_mat

	var task_light := OmniLight3D.new()
	task_light.position = Vector3(-0.10, 0.38, 0.14)
	task_light.omni_range = 1.65
	task_light.omni_attenuation = 1.15
	task_light.light_color = Color(1.0, 0.80, 0.52)
	task_light.light_energy = 0.0
	task_light.shadow_enabled = false
	studio_group.add_child(task_light)

	var hanger := _add_box(studio_group, Vector3(0.18, 0.012, 0.045), Vector3(0.68, 0.48, -0.22), Color(0.14, 0.15, 0.18), 0.4)
	hanger.rotation.y = -0.25
	for k in range(8):
		var lx := 0.61 + float(k) * 0.020
		var l_len := 0.34 + float(k % 3) * 0.05
		_add_cyl(studio_group, 0.0020, l_len, Vector3(lx, 0.48 - l_len * 0.5, -0.205), cable_colors[k % cable_colors.size()], 0.45)

	# =========================================================================
	# CAMPUS ELECTRONICS LAB ROOM (Back-Row View at 4:00 PM Golden Afternoon)
	# =========================================================================
	var campus_group := Node3D.new()
	campus_group.name = "CampusElectronicsLabRoom"
	campus_group.visible = false
	env_root.add_child(campus_group)
	var campus_anim := _build_campus_lab_room(campus_group)

	# =========================================================================
	# SHARED BENCH INSTRUMENTS (Present in both Studio & Campus Lab Modes)
	# =========================================================================
	var hdmm := Node3D.new()
	hdmm.position = Vector3(-0.40, 0.019, 0.29)
	hdmm.rotation = Vector3(0.0, 0.38, 0.0)
	env_root.add_child(hdmm)
	_add_box(hdmm, Vector3(0.086, 0.032, 0.165), Vector3(0, 0, 0), Color(0.95, 0.74, 0.10), 0.55)
	_add_box(hdmm, Vector3(0.072, 0.034, 0.150), Vector3(0, 0.001, 0), Color(0.16, 0.17, 0.20), 0.45)
	var hdmm_lcd := _add_box(hdmm, Vector3(0.056, 0.003, 0.036), Vector3(0, 0.0185, -0.044), Color(0.08, 0.22, 0.18), 0.2)
	var hlcd_mat := StandardMaterial3D.new()
	hlcd_mat.albedo_color = Color(0.08, 0.22, 0.18)
	hlcd_mat.emission_enabled = true
	hlcd_mat.emission = Color(0.18, 0.75, 0.58)
	hlcd_mat.emission_energy_multiplier = 0.85
	hdmm_lcd.material_override = hlcd_mat
	for bx in [-0.018, -0.006, 0.006, 0.018]:
		_add_box(hdmm, Vector3(0.008, 0.004, 0.006), Vector3(bx, 0.019, -0.018), Color(0.95, 0.76, 0.12), 0.4)
	_add_cyl(hdmm, 0.019, 0.008, Vector3(0, 0.020, 0.010), Color(0.22, 0.24, 0.28), 0.35)
	_add_box(hdmm, Vector3(0.004, 0.010, 0.034), Vector3(0, 0.021, 0.010), Color(0.92, 0.93, 0.95), 0.3)
	var jack_specs := [
		[-0.020, Color(0.85, 0.15, 0.15)],
		[0.0, Color(0.10, 0.11, 0.13)],
		[0.020, Color(0.85, 0.15, 0.15)]
	]
	for js in jack_specs:
		_add_cyl(hdmm, 0.0055, 0.006, Vector3(js[0], 0.019, 0.054), js[1], 0.35)
		_add_cyl(hdmm, 0.0025, 0.007, Vector3(js[0], 0.0195, 0.054), Color(0.82, 0.72, 0.28), 0.25, 0.85)

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

	var rack_x := 0.25
	var rack_z := 0.04
	var wood_col := Color(0.76, 0.62, 0.44)
	_add_box(env_root, Vector3(0.016, 0.38, 0.24), Vector3(rack_x - 0.145, 0.19, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.016, 0.38, 0.24), Vector3(rack_x + 0.145, 0.19, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.306, 0.016, 0.24), Vector3(rack_x, 0.175, rack_z), wood_col, 0.72)
	_add_box(env_root, Vector3(0.306, 0.016, 0.24), Vector3(rack_x, 0.375, rack_z), wood_col, 0.72)

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

	var meter_root := Node3D.new()
	meter_root.position = Vector3(0.49, 0.0, 0.15)
	meter_root.rotation.y = -0.35
	env_root.add_child(meter_root)
	_add_box(meter_root, Vector3(0.115, 0.155, 0.10), Vector3(0.0, 0.0775, 0.0), Color(0.30, 0.32, 0.35), 0.45)
	_add_box(meter_root, Vector3(0.092, 0.068, 0.004), Vector3(0.0, 0.108, 0.051), Color(0.95, 0.94, 0.90), 0.25)
	_add_box(meter_root, Vector3(0.068, 0.003, 0.002), Vector3(0.0, 0.122, 0.0535), Color(0.12, 0.12, 0.14), 0.4)
	var needle := _add_box(meter_root, Vector3(0.002, 0.036, 0.002), Vector3(-0.008, 0.106, 0.0535), Color(0.85, 0.14, 0.14), 0.3)
	needle.rotation.z = 0.32
	for b_x in [-0.026, 0.0, 0.026]:
		var b_c := Color(0.85, 0.15, 0.15) if b_x != 0.0 else Color(0.12, 0.12, 0.14)
		_add_cyl(meter_root, 0.0055, 0.014, Vector3(b_x, 0.032, 0.055), b_c, 0.35).rotation.x = PI * 0.5

	_add_cyl(env_root, 0.018, 0.032, Vector3(0.45, 0.018, 0.32), Color(0.18, 0.42, 0.78), 0.45)
	_add_cyl(env_root, 0.014, 0.022, Vector3(0.45, 0.018, 0.32), Color(0.76, 0.78, 0.80), 0.25, 0.85)

	return {
		"desk_mat": desk.material_override,
		"esd_mat": esd.material_override,
		"wall_mat": wall.material_override,
		"bulb_mat": bulb_mat,
		"task_light": task_light,
		"studio_group": studio_group,
		"campus_group": campus_group,
		"campus_anim": campus_anim
	}

static func _build_campus_lab_room(root: Node3D) -> Dictionary:
	# User's bench is positioned at the back-right row (z=0), looking forward toward the front whiteboard (z=-4.8)
	var floor_y := -0.74
	var wall_cream := Color(0.88, 0.85, 0.77)
	var mahogany := Color(0.27, 0.16, 0.10)
	var tile_dark := Color(0.23, 0.24, 0.26)

	# 1. Charcoal Ceramic Tiled Floor + White PVC Cable Conduits
	_add_box(root, Vector3(9.0, 0.04, 11.5), Vector3(-0.3, floor_y - 0.02, -1.2), tile_dark, 0.32)
	for tz in [-3.2, -1.7, -0.2, 1.3]:
		_add_box(root, Vector3(5.6, 0.008, 0.035), Vector3(-0.5, floor_y + 0.004, tz), Color(0.90, 0.90, 0.88), 0.4)

	# 2. Front Classroom Wall (z = -4.9) with Raised Wooden Lecturer Stage, Whiteboard, Clock & 5R Poster
	_add_box(root, Vector3(9.0, 3.2, 0.12), Vector3(-0.3, floor_y + 1.60, -4.9), wall_cream, 0.85)
	_add_box(root, Vector3(4.8, 0.10, 1.65), Vector3(0.5, floor_y + 0.05, -4.0), Color(0.32, 0.22, 0.14), 0.55)
	_add_box(root, Vector3(2.95, 1.22, 0.03), Vector3(0.55, floor_y + 1.72, -4.82), Color(0.96, 0.97, 0.98), 0.16)
	_add_box(root, Vector3(3.00, 0.04, 0.07), Vector3(0.55, floor_y + 1.10, -4.80), Color(0.72, 0.74, 0.76), 0.35)
	_add_cyl(root, 0.16, 0.03, Vector3(0.55, floor_y + 2.55, -4.82), Color(0.95, 0.95, 0.94), 0.3).rotation.x = PI * 0.5
	_add_box(root, Vector3(0.68, 0.94, 0.025), Vector3(2.55, floor_y + 1.68, -4.82), Color(0.76, 0.78, 0.74), 0.6)

	# Lecturer Table on Front Stage
	_add_box(root, Vector3(1.55, 0.04, 0.78), Vector3(0.55, floor_y + 0.84, -3.75), mahogany, 0.38)
	for lx in [-0.15, 1.25]:
		for lz in [-4.08, -3.42]:
			_add_box(root, Vector3(0.05, 0.74, 0.05), Vector3(lx, floor_y + 0.45, lz), Color(0.12, 0.12, 0.14), 0.4)

	# 3. Left Window Wall (x = -3.8) with 4:00 PM Golden Afternoon Sunbeams & Louver Blinds
	var left_wall := _add_box(root, Vector3(0.12, 3.2, 11.5), Vector3(-3.95, floor_y + 1.60, -1.2), wall_cream, 0.85)
	left_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_box(root, Vector3(0.62, 0.82, 9.6), Vector3(-3.55, floor_y + 0.41, -1.2), Color(0.66, 0.44, 0.24), 0.55)
	_add_box(root, Vector3(0.66, 0.04, 9.6), Vector3(-3.53, floor_y + 0.84, -1.2), Color(0.32, 0.35, 0.38), 0.4)

	# Left-Side Sunset Windows (Peach-Gold Horizon -> Lavender Zenith Gradient + Sills + Curtains)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.56, 0.48, 0.72), Color(0.96, 0.66, 0.52), Color(1.0, 0.86, 0.58)])
	grad.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)

	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_texture = grad_tex
	win_mat.emission_enabled = true
	win_mat.emission_texture = grad_tex
	win_mat.emission_energy_multiplier = 1.65

	for wz in [-3.4, -1.6, 0.2]:
		var pane := _add_box(root, Vector3(0.012, 1.56, 1.44), Vector3(-3.88, floor_y + 1.86, wz), Color(1, 1, 1), 0.25)
		pane.material_override = win_mat
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Window sill ledge
		_add_box(root, Vector3(0.18, 0.04, 1.56), Vector3(-3.80, floor_y + 1.07, wz), Color(0.78, 0.72, 0.68), 0.5)
		# Crisp window mullions casting clean geometric sunlight patches onto desks & whiteboard
		for h_bar in [1.10, 1.62, 2.12, 2.62]:
			var bar := _add_box(root, Vector3(0.06, 0.045, 1.50), Vector3(-3.82, floor_y + h_bar, wz), Color(0.42, 0.36, 0.34), 0.6)
			bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for v_off in [-0.72, 0.0, 0.72]:
			var vbar := _add_box(root, Vector3(0.06, 1.56, 0.045), Vector3(-3.82, floor_y + 1.86, wz + v_off), Color(0.42, 0.36, 0.34), 0.6)
			vbar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# Warm cream curtains framing each window bay
		for c_off in [-0.66, 0.66]:
			_add_box(root, Vector3(0.05, 1.64, 0.16), Vector3(-3.76, floor_y + 1.86, wz + c_off), Color(0.86, 0.74, 0.58), 0.75)

	# Diagonal Golden-Peach Sunset Beams slanting from Left Windows toward Front Whiteboard & Desks
	var beam_mat := StandardMaterial3D.new()
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	beam_mat.albedo_color = Color(1.0, 0.74, 0.44, 0.032)
	for bz in [-3.4, -1.6, 0.2]:
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(5.6, 1.25, 1.28)
		beam.mesh = bm
		beam.position = Vector3(-1.15, floor_y + 1.42, bz - 0.35)
		beam.rotation = Vector3(0.0, -0.18, -0.34)
		beam.material_override = beam_mat
		root.add_child(beam)

	# 4. Right Aisle Wall (x = +2.85) with Tall Cream-Beige Sliding Glass Instrument Cabinets
	_add_box(root, Vector3(0.12, 3.2, 11.5), Vector3(3.05, floor_y + 1.60, -1.2), wall_cream, 0.85)
	for cz in [-3.4, -1.9, -0.4, 1.1]:
		_add_box(root, Vector3(0.56, 2.15, 1.38), Vector3(2.68, floor_y + 1.075, cz), Color(0.84, 0.81, 0.73), 0.55)
		for sy in [0.45, 1.05, 1.60]:
			_add_box(root, Vector3(0.50, 0.025, 1.32), Vector3(2.64, floor_y + sy, cz), Color(0.72, 0.70, 0.64), 0.5)
			_add_box(root, Vector3(0.32, 0.22, 0.45), Vector3(2.62, floor_y + sy + 0.12, cz - 0.30), Color(0.22, 0.35, 0.52), 0.4)
			_add_box(root, Vector3(0.32, 0.22, 0.45), Vector3(2.62, floor_y + sy + 0.12, cz + 0.30), Color(0.76, 0.75, 0.70), 0.4)

	# 5. Neighboring Student Mahogany Lab Tables (2 Rows in Front of You + Left Neighboring Table)
	var neighbor_coords := [
		Vector3(-2.10, 0.0, 0.14),   # Left-side neighboring table next to you
		Vector3(0.02, 0.0, -1.55),   # Row directly in front of you
		Vector3(-2.10, 0.0, -1.55),  # Front-left table
		Vector3(0.02, 0.0, -3.05),   # Second row in front of you
		Vector3(-2.10, 0.0, -3.05)   # Second row left
	]
	for nc in neighbor_coords:
		_add_box(root, Vector3(1.55, 0.04, 0.95), Vector3(nc.x, -0.02, nc.z), mahogany, 0.36)
		for lx in [-0.70, 0.70]:
			for lz in [-0.40, 0.40]:
				_add_box(root, Vector3(0.045, 0.72, 0.045), Vector3(nc.x + lx, -0.38, nc.z + lz), Color(0.14, 0.11, 0.09), 0.45)
		# Student benchtop instruments (oscilloscopes & power supplies)
		_add_box(root, Vector3(0.30, 0.17, 0.24), Vector3(nc.x - 0.28, 0.085, nc.z - 0.10), Color(0.80, 0.79, 0.75), 0.45)
		_add_box(root, Vector3(0.22, 0.14, 0.20), Vector3(nc.x + 0.25, 0.070, nc.z - 0.10), Color(0.25, 0.27, 0.30), 0.45)

	# 6. Detailed Faceted Low-Poly PENS DTE Students (Hijab, Woman, Man) + Walking Aisle Student
	var seated_students: Array[Dictionary] = []
	var student_spots := [
		{"pos": Vector3(-1.78, floor_y, 0.56), "yaw": PI - 0.35, "variant": "hijab"},
		{"pos": Vector3(-2.38, floor_y, 0.62), "yaw": PI + 0.14, "variant": "man"},
		{"pos": Vector3(-0.28, floor_y, -1.05), "yaw": PI - 0.10, "variant": "woman"},
		{"pos": Vector3(0.32, floor_y, -1.05), "yaw": PI + 0.12, "variant": "hijab"},
		{"pos": Vector3(-1.95, floor_y, -1.05), "yaw": PI - 0.15, "variant": "man"},
		{"pos": Vector3(0.08, floor_y, -2.55), "yaw": PI + 0.06, "variant": "woman"}
	]
	for sp in student_spots:
		var st := CampusStudentBuilder.build_student(root, String(sp["variant"]), true)
		st["root"].position = sp["pos"]
		st["root"].rotation.y = float(sp["yaw"])
		seated_students.append(st)

	# Walking Student in the Right Aisle (showcasing DTE + PENS chest crest & yellow sleeve bands)
	var walker := CampusStudentBuilder.build_student(root, "man", false)
	walker["root"].position = Vector3(1.92, floor_y, -2.4)

	var rear_group := Node3D.new(); rear_group.name = "RearRoomProps"; root.add_child(rear_group)
	# 7. Rear Slotted-Angle Steel Racks behind your seat (z = +2.35)
	_add_box(rear_group, Vector3(2.8, 2.05, 0.55), Vector3(-0.4, floor_y + 1.025, 2.35), Color(0.68, 0.67, 0.64), 0.6)
	_add_box(rear_group, Vector3(0.45, 0.32, 0.36), Vector3(0.45, floor_y + 0.92, 2.15), Color(0.92, 0.93, 0.94), 0.4)

	# 8. Acoustic Tile Ceiling + Twin-Tube Fluorescent Lights
	var ceil_slab := _add_box(root, Vector3(9.0, 0.08, 11.5), Vector3(-0.3, floor_y + 3.22, -1.2), Color(0.86, 0.86, 0.84), 0.85)
	ceil_slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tube_mat := StandardMaterial3D.new()
	tube_mat.albedo_color = Color(1.0, 1.0, 1.0)
	tube_mat.emission_enabled = true
	tube_mat.emission = Color(0.96, 0.97, 1.0)
	tube_mat.emission_energy_multiplier = 0.0
	for fx in [-1.8, 0.8]:
		for fz in [-3.4, -1.5, 0.4]:
			_add_box(root, Vector3(0.28, 0.04, 1.15), Vector3(fx, floor_y + 3.15, fz), Color(0.75, 0.76, 0.78), 0.4)
			var tube := _add_box(root, Vector3(0.18, 0.02, 1.08), Vector3(fx, floor_y + 3.12, fz), Color(1, 1, 1), 0.2)
			tube.material_override = tube_mat

	# Warm Golden Window Sunlight Accent angled onto your workbench from the left windows
	var desk_sun := SpotLight3D.new()
	desk_sun.position = Vector3(-2.65, 1.15, 0.35)
	desk_sun.look_at_from_position(Vector3(-2.65, 1.15, 0.35), Vector3(0.10, 0.05, 0.18), Vector3.UP)
	desk_sun.light_color = Color(1.0, 0.72, 0.42)
	desk_sun.light_energy = 2.6
	desk_sun.spot_range = 5.5
	desk_sun.spot_angle = 42.0
	desk_sun.shadow_enabled = false
	root.add_child(desk_sun)

	# 9. Cinematic Floating Dust Motes in 4:00 PM Sunbeams
	var dust := GPUParticles3D.new()
	dust.name = "AfternoonDustMotes"
	dust.amount = 140
	dust.lifetime = 8.0
	dust.preprocess = 4.0
	dust.position = Vector3(-0.8, 0.45, -1.0)
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(2.8, 1.1, 2.6)
	pmat.gravity = Vector3(0.004, -0.003, 0.002)
	pmat.initial_velocity_min = 0.005
	pmat.initial_velocity_max = 0.018
	pmat.scale_min = 0.6
	pmat.scale_max = 1.4
	dust.process_material = pmat

	var mote_mesh := SphereMesh.new()
	mote_mesh.radius = 0.0035
	mote_mesh.height = 0.007
	var mote_mat := StandardMaterial3D.new()
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.albedo_color = Color(1.0, 0.88, 0.58, 0.85)
	mote_mesh.material = mote_mat
	dust.draw_pass_1 = mote_mesh
	root.add_child(dust)

	return {
		"seated": seated_students,
		"walker": walker,
		"time": 0.0
	}

static func animate_lab_life(env_data: Dictionary, delta: float) -> void:
	if env_data.is_empty():
		return
	var campus_group: Node3D = env_data.get("campus_group")
	if campus_group == null or not campus_group.visible:
		return
	var anim: Dictionary = env_data.get("campus_anim", {})
	if anim.is_empty():
		return
	anim["time"] = float(anim.get("time", 0.0)) + delta
	var t := float(anim["time"])

	# Seated practicum students adjusting oscilloscope knobs & writing lab notes
	var seated: Array = anim.get("seated", [])
	for i in range(seated.size()):
		var st: Dictionary = seated[i]
		var torso: Node3D = st["torso"]
		var head: Node3D = st["head"]
		var arm_r: Dictionary = st["arm_r"]
		var phase := t * 1.45 + float(i) * 1.8
		torso.rotation.x = 0.16 + sin(phase) * 0.035
		head.rotation.y = sin(phase * 0.6) * 0.14
		arm_r["shoulder"].rotation.x = -0.84 + cos(phase * 1.5) * 0.10
		arm_r["elbow"].rotation.x = -0.72 + sin(phase * 1.5) * 0.08

	# Walking student pacing along the right aisle (z = -3.0 to +0.8)
	var walker: Dictionary = anim.get("walker", {})
	if not walker.is_empty():
		var w_root: Node3D = walker["root"]
		var cycle := fmod(t * 0.20, 2.0)
		var forward := cycle < 1.0
		var u := cycle if forward else (2.0 - cycle)
		w_root.position.z = lerpf(-3.0, 0.8, u)
		w_root.rotation.y = 0.0 if forward else PI
		var stride := sin(t * 5.0) * 0.42
		var knee_bend := maxf(0.0, -sin(t * 5.0)) * 0.48
		var knee_bend_r := maxf(0.0, sin(t * 5.0)) * 0.48
		walker["leg_l"]["hip"].rotation.x = stride
		walker["leg_l"]["knee"].rotation.x = knee_bend
		walker["leg_r"]["hip"].rotation.x = -stride
		walker["leg_r"]["knee"].rotation.x = knee_bend_r
		walker["arm_l"]["shoulder"].rotation.x = -stride * 0.65
		walker["arm_r"]["shoulder"].rotation.x = stride * 0.65

static func apply_theme(env_data: Dictionary, world_env: WorldEnvironment, key_light: DirectionalLight3D, theme_idx: int) -> void:
	if env_data.is_empty():
		return
	var cfg: Dictionary = LAB_THEMES[clampi(theme_idx, 0, LAB_THEMES.size() - 1)]
	var desk_mat: StandardMaterial3D = env_data["desk_mat"]
	var esd_mat: StandardMaterial3D = env_data["esd_mat"]
	var wall_mat: StandardMaterial3D = env_data["wall_mat"]
	var bulb_mat: StandardMaterial3D = env_data["bulb_mat"]
	var task_light: OmniLight3D = env_data["task_light"]
	var studio_group: Node3D = env_data.get("studio_group")
	var campus_group: Node3D = env_data.get("campus_group")

	var is_campus := bool(cfg.get("is_campus", false))
	if studio_group != null:
		studio_group.visible = not is_campus
	if campus_group != null:
		campus_group.visible = is_campus

	desk_mat.albedo_color = cfg["desk_col"]
	desk_mat.roughness = float(cfg["desk_rough"])
	esd_mat.albedo_color = cfg["esd_col"]
	wall_mat.albedo_color = cfg["wall_col"]

	var lamp_on := bool(cfg["lamp_on"]) and (not is_campus)
	bulb_mat.emission = cfg["lamp_col"]
	bulb_mat.emission_energy_multiplier = 2.8 if lamp_on else 0.0
	task_light.light_color = cfg["lamp_col"]
	task_light.light_energy = float(cfg["lamp_energy"]) if lamp_on else 0.0

	if world_env != null and world_env.environment != null:
		world_env.environment.background_color = cfg["bg_col"]
		world_env.environment.ambient_light_color = cfg["amb_col"]
		world_env.environment.ambient_light_energy = float(cfg["amb_energy"])
		world_env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES if is_campus else Environment.TONE_MAPPER_LINEAR
		world_env.environment.glow_enabled = is_campus
		world_env.environment.glow_intensity = 0.32
		world_env.environment.glow_bloom = 0.12
	if key_light != null:
		key_light.light_color = cfg["key_col"]
		key_light.light_energy = float(cfg["key_energy"])
		if cfg.has("key_rot"):
			key_light.rotation = cfg["key_rot"]

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

static func _add_strut(parent: Node3D, a: Vector3, b: Vector3, rad: float, col: Color) -> void:
	var dist := a.distance_to(b)
	if dist < 0.001:
		return
	var pivot := Node3D.new()
	pivot.position = (a + b) * 0.5
	parent.add_child(pivot)
	var up := Vector3.UP if absf((b - a).normalized().dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	pivot.look_at(parent.to_global(b), up)
	var cyl := _add_cyl(pivot, rad, dist, Vector3.ZERO, col, 0.35, 0.72)
	cyl.rotation.x = PI * 0.5

static func _add_joint_sphere(parent: Node3D, pos: Vector3, rad: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	mi.mesh = sm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.32
	mat.metallic = 0.78
	mi.material_override = mat
	parent.add_child(mi)

static func update_view_occlusion(env_data: Dictionary, cam: Camera3D) -> void:
	if env_data.is_empty() or cam == null:
		return
	var campus_group: Node3D = env_data.get("campus_group")
	if campus_group == null or not campus_group.visible:
		return
	var cam_fwd := -cam.global_transform.basis.z
	var cam_pos := cam.global_transform.origin
	var rear_group := campus_group.get_node_or_null("RearRoomProps") as Node3D
	if rear_group != null:
		# Only render rear storage racks behind the player if camera turns backward (+Z)
		rear_group.visible = cam_fwd.z > -0.15
	# Cull any student avatar outside the camera's forward cone (dot < -0.15)
	var anim: Dictionary = env_data.get("campus_anim", {})
	for st in anim.get("seated", []):
		var r: Node3D = st["root"]
		var to_obj := (r.global_position + Vector3(0, 0.7, 0) - cam_pos).normalized()
		r.visible = cam_fwd.dot(to_obj) > -0.15
	var walker: Dictionary = anim.get("walker", {})
	if not walker.is_empty():
		var wr: Node3D = walker["root"]
		var to_w := (wr.global_position + Vector3(0, 0.8, 0) - cam_pos).normalized()
		wr.visible = cam_fwd.dot(to_w) > -0.15
