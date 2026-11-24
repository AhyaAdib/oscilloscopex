class_name Psu3DBuilder
extends RefCounted

static func _mat(col: Color, rough: float = 0.45, metal: float = 0.1, emit: Color = Color.BLACK, emit_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_energy
	return m

static func _box(parent: Node3D, name_str: String, sz: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_str
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, name_str: String, r: float, h: float, pos: Vector3, rot: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_str
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 18
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _lbl(parent: Node3D, text_str: String, pos: Vector3, px: int, col: Color, rot_y: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = text_str
	l.pixel_size = 0.00018
	l.font_size = maxi(px * 2, 22)
	l.outline_size = 0
	l.modulate = col
	l.position = pos
	l.rotation = Vector3(0.0, rot_y, 0.0)
	parent.add_child(l)
	return l

static func _add_psu_knob(parent: Node3D, param_id: String, title: String, pos: Vector3, min_v: float, max_v: float, step_v: float, init_v: float, dial_ticks: Array, interactables: Array) -> Node3D:
	var holder := Node3D.new()
	holder.name = "PsuHolder_" + param_id
	holder.position = pos
	parent.add_child(holder)

	var tick_col := Color(0.16, 0.18, 0.21)
	for ti in range(dial_ticks.size()):
		var frac := float(ti) / float(maxi(dial_ticks.size() - 1, 1))
		var ang := lerpf(deg_to_rad(135.0), deg_to_rad(-135.0), frac)
		var dir := Vector2(-sin(ang), cos(ang))
		var t_mi := _box(holder, "Tick_" + str(ti), Vector3(0.0006, 0.0018, 0.0008), Vector3(dir.x * 0.0102, dir.y * 0.0102, 0.0014), _mat(tick_col, 0.5))
		t_mi.rotation.z = ang
		var l_nd := _lbl(holder, str(dial_ticks[ti]), Vector3(dir.x * 0.0136, dir.y * 0.0136, 0.0016), 10, tick_col)
		l_nd.pixel_size = 0.00017

	var pivot := Node3D.new()
	pivot.name = "PsuKnob_" + param_id
	holder.add_child(pivot)
	var init_norm := clampf((init_v - min_v) / maxf(max_v - min_v, 1e-6), 0.0, 1.0)
	pivot.rotation.z = lerpf(deg_to_rad(135.0), deg_to_rad(-135.0), init_norm)
	_cyl(pivot, "Skirt", 0.0085, 0.003, Vector3(0, 0, 0.0015), Vector3(PI * 0.5, 0, 0), _mat(Color(0.28, 0.30, 0.33), 0.45, 0.2))
	_cyl(pivot, "Body", 0.0072, 0.011, Vector3(0, 0, 0.0065), Vector3(PI * 0.5, 0, 0), _mat(Color(0.76, 0.78, 0.81), 0.35, 0.1))
	_cyl(pivot, "Cap", 0.0056, 0.002, Vector3(0, 0, 0.0122), Vector3(PI * 0.5, 0, 0), _mat(Color(0.32, 0.34, 0.38), 0.35, 0.2))
	_box(pivot, "Pointer", Vector3(0.0014, 0.0055, 0.0025), Vector3(0.0, 0.0030, 0.0128), _mat(Color(0.96, 0.96, 0.98), 0.25))
	interactables.append({
		"type": "knob",
		"param_id": param_id,
		"title": title,
		"pivot": pivot,
		"rotor": pivot,
		"focus_node": pivot,
		"hit_radius": 0.014,
		"ring_radius": 0.011,
		"min": min_v,
		"max": max_v,
		"step": step_v,
		"value": init_v,
		"labels": []
	})
	return pivot

static func _wire_segment(parent: Node, p0: Vector3, p1: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var diff := p1 - p0
	var length := diff.length()
	if length < 0.0005:
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = mat
	mi.position = (p0 + p1) * 0.5
	parent.add_child(mi)
	var up := diff.normalized()
	if absf(up.dot(Vector3.UP)) > 0.999:
		mi.rotation = Vector3.ZERO
	else:
		var axis := Vector3.UP.cross(up).normalized()
		var angle := acos(clampf(Vector3.UP.dot(up), -1.0, 1.0))
		mi.basis = Basis(axis, angle)

static func build_gps3030d_on_bench(parent: Node, board_root: Node3D, interactables: Array = []) -> Dictionary:
	var root := Node3D.new()
	root.name = "GWInstek_GPS3030D"
	root.position = Vector3(0.31, 0.003, 0.11)
	root.rotation = Vector3(0.0, -0.46, 0.0)
	parent.add_child(root)

	var chassis_mat := _mat(Color(0.83, 0.84, 0.86, 1.0), 0.42, 0.15)
	var panel_mat := _mat(Color(0.77, 0.78, 0.80, 1.0), 0.45, 0.12)
	var bezel_mat := _mat(Color(0.24, 0.26, 0.29, 1.0), 0.50, 0.10)
	var screen_mat := _mat(Color(0.05, 0.03, 0.03, 1.0), 0.20, 0.05)
	var dark_mat := _mat(Color(0.12, 0.13, 0.14, 1.0), 0.55, 0.10)
	var metal_mat := _mat(Color(0.78, 0.80, 0.83, 1.0), 0.25, 0.85)
	var red_led := _mat(Color(1.0, 0.18, 0.14, 1.0), 0.25, 0.0, Color(1.0, 0.16, 0.12, 1.0), 1.8)
	var green_led := _mat(Color(0.15, 0.92, 0.36, 1.0), 0.25, 0.0, Color(0.12, 0.88, 0.30, 1.0), 1.6)
	var pwr_green := _mat(Color(0.08, 0.46, 0.22, 1.0), 0.38, 0.05)

	var W := 0.124
	var H := 0.140
	var D := 0.215
	var fz := D * 0.5
	_box(root, "Enclosure", Vector3(W, H, D), Vector3(0.0, H * 0.5 + 0.005, 0.0), chassis_mat)
	_box(root, "FrontFace", Vector3(W - 0.006, H - 0.006, 0.003), Vector3(0.0, H * 0.5 + 0.005, fz + 0.001), panel_mat)

	# Side cooling louver slots
	for side_s in [-1.0, 1.0]:
		for vz in [-0.045, -0.015, 0.015, 0.045]:
			_box(root, "Vent", Vector3(0.002, 0.052, 0.014), Vector3(side_s * (W * 0.5 + 0.0005), 0.068, vz), _mat(Color(0.32, 0.34, 0.37), 0.6))

	# Rubber feet & Top Carrying Handle
	for fx in [-0.046, 0.046]:
		for fzz in [-0.084, 0.084]:
			_cyl(root, "Foot", 0.007, 0.005, Vector3(fx, 0.0025, fzz), Vector3.ZERO, dark_mat)
	_box(root, "HandleMountF", Vector3(0.022, 0.008, 0.018), Vector3(0.0, H + 0.009, 0.054), metal_mat)
	_box(root, "HandleMountR", Vector3(0.022, 0.008, 0.018), Vector3(0.0, H + 0.009, -0.054), metal_mat)
	_box(root, "HandleStrap", Vector3(0.018, 0.005, 0.108), Vector3(0.0, H + 0.014, 0.0), dark_mat)

	# Brand & Model Header
	_lbl(root, "GW INSTEK  GPS-3030D", Vector3(-0.014, H - 0.007, fz + 0.003), 16, Color(0.12, 0.14, 0.16))
	_lbl(root, "0-30V / 0-3A", Vector3(0.039, H - 0.007, fz + 0.003), 10, Color(0.22, 0.24, 0.27))

	# Display Bezel + Red 4-Digit 7-Segment LED Readout
	_box(root, "DisplayBezel", Vector3(0.102, 0.036, 0.004), Vector3(0.0, H - 0.031, fz + 0.003), bezel_mat)
	_box(root, "DisplayWindow", Vector3(0.090, 0.026, 0.002), Vector3(0.0, H - 0.031, fz + 0.0048), screen_mat)
	var readout_lbl := _lbl(root, "12.00 V", Vector3(-0.009, H - 0.031, fz + 0.0064), 32, Color(1.0, 0.20, 0.15))
	var volts_led := _cyl(root, "VoltsLed", 0.0018, 0.002, Vector3(0.027, H - 0.025, fz + 0.0058), Vector3(PI * 0.5, 0, 0), red_led)
	var amps_led := _cyl(root, "AmpsLed", 0.0018, 0.002, Vector3(0.027, H - 0.037, fz + 0.0058), Vector3(PI * 0.5, 0, 0), red_led)
	amps_led.visible = false
	_lbl(root, "VOLTS", Vector3(0.036, H - 0.025, fz + 0.0060), 9, Color(0.94, 0.94, 0.94))
	_lbl(root, "AMPS", Vector3(0.036, H - 0.037, fz + 0.0060), 9, Color(0.82, 0.82, 0.82))

	# CURRENT & VOLTAGE Fine/Coarse Interactive Knobs + Silkscreen
	_lbl(root, "CURRENT", Vector3(-0.033, 0.082, fz + 0.003), 11, Color(0.14, 0.16, 0.18))
	_lbl(root, "VOLTAGE", Vector3(0.033, 0.082, fz + 0.003), 11, Color(0.14, 0.16, 0.18))
	_add_psu_knob(root, "psu_current_limit", "PSU CURRENT LIMIT (A)", Vector3(-0.035, 0.066, fz + 0.003), 0.1, 3.0, 0.1, 1.5, ["0.1", "1.5", "3.0"], interactables)
	_add_psu_knob(root, "psu_voltage_fine", "PSU VOLTAGE FINE (±1V)", Vector3(0.017, 0.066, fz + 0.003), -1.0, 1.0, 0.1, 0.0, ["-1", "0", "+1"], interactables)
	_add_psu_knob(root, "psu_voltage_coarse", "PSU VOLTAGE COARSE (0-30V)", Vector3(0.046, 0.066, fz + 0.003), 0.0, 30.0, 1.0, 12.0, ["0", "15", "30"], interactables)
	_lbl(root, "LIMIT", Vector3(-0.033, 0.050, fz + 0.003), 9, Color(0.22, 0.24, 0.26))
	_lbl(root, "FINE", Vector3(0.019, 0.050, fz + 0.003), 9, Color(0.22, 0.24, 0.26))
	_lbl(root, "COARSE", Vector3(0.045, 0.050, fz + 0.003), 9, Color(0.22, 0.24, 0.26))

	_cyl(root, "CC_Led", 0.0018, 0.002, Vector3(-0.014, 0.065, fz + 0.003), Vector3(PI * 0.5, 0, 0), _mat(Color(0.45, 0.12, 0.12), 0.4))
	var cv_led := _cyl(root, "CV_Led", 0.0020, 0.002, Vector3(0.002, 0.065, fz + 0.003), Vector3(PI * 0.5, 0, 0), green_led)
	_lbl(root, "C.V.", Vector3(0.002, 0.057, fz + 0.003), 9, Color(0.12, 0.45, 0.20))

	# Interactive Green POWER Switch
	var pwr_btn := _box(root, "PowerSwitch", Vector3(0.025, 0.012, 0.008), Vector3(-0.035, 0.025, fz + 0.004), pwr_green)
	_lbl(root, "POWER", Vector3(-0.035, 0.036, fz + 0.003), 10, Color(0.14, 0.16, 0.18))
	interactables.append({
		"type": "button",
		"param_id": "psu_power_on",
		"title": "GW Instek GPS-3030D POWER (ON/OFF)",
		"mesh": pwr_btn,
		"focus_node": pwr_btn,
		"hit_radius": 0.016,
		"ring_radius": 0.013
	})

	# 3 Output Binding Posts (- Black, GND Green, + Red)
	var post_y := 0.024
	var posts := [
		{"name": "PostNeg", "x": 0.002, "lbl": "-", "col": Color(0.12, 0.12, 0.14)},
		{"name": "PostGnd", "x": 0.023, "lbl": "GND", "col": Color(0.12, 0.62, 0.28)},
		{"name": "PostPos", "x": 0.044, "lbl": "+", "col": Color(0.88, 0.15, 0.15)},
	]
	var post_local := {}
	for p in posts:
		var px: float = p["x"]
		_lbl(root, p["lbl"], Vector3(px, post_y + 0.013, fz + 0.003), 11, Color(0.14, 0.16, 0.18))
		_cyl(root, p["name"] + "_Collar", 0.0058, 0.007, Vector3(px, post_y, fz + 0.004), Vector3(PI * 0.5, 0, 0), _mat(p["col"], 0.35, 0.1))
		_cyl(root, p["name"] + "_Tip", 0.0034, 0.011, Vector3(px, post_y, fz + 0.010), Vector3(PI * 0.5, 0, 0), metal_mat)
		post_local[p["lbl"]] = Vector3(px, post_y, fz + 0.014)

	# Route Visible 3D Power (+12V Red) and Ground (GND Black) Leads from PSU Binding Posts to PCB Terminals
	var p_pos_world: Vector3 = root.transform * post_local["+"]
	var p_gnd_world: Vector3 = root.transform * post_local["GND"]
	var b_pos: Vector3 = board_root.position if board_root != null else Vector3(0.0, 0.003, 0.255)
	var pcb_vcc_world := b_pos + Vector3(0.072, 0.014, -0.025)
	var pcb_gnd_world := b_pos + Vector3(0.072, 0.014, 0.025)

	var red_wire_mat := _mat(Color(0.94, 0.14, 0.14, 1.0), 0.35, 0.05)
	var blk_wire_mat := _mat(Color(0.10, 0.11, 0.13, 1.0), 0.40, 0.05)
	var red_boot_mat := _mat(Color(0.85, 0.12, 0.12, 1.0), 0.45)
	var blk_boot_mat := _mat(Color(0.14, 0.15, 0.18, 1.0), 0.45)

	# Banana plug boots at PSU posts & clip boots at PCB terminals
	_wire_segment(parent, p_pos_world, p_pos_world + (root.transform.basis.z * 0.018), 0.0036, red_boot_mat)
	_wire_segment(parent, p_gnd_world, p_gnd_world + (root.transform.basis.z * 0.018), 0.0036, blk_boot_mat)
	_wire_segment(parent, pcb_vcc_world + Vector3(0.016, 0.008, -0.004), pcb_vcc_world, 0.0032, red_boot_mat)
	_wire_segment(parent, pcb_gnd_world + Vector3(0.016, 0.008, 0.006), pcb_gnd_world, 0.0032, blk_boot_mat)

	var vcc_pts := [
		p_pos_world + (root.transform.basis.z * 0.017),
		Vector3(0.24, 0.020, 0.205),
		Vector3(0.16, 0.016, 0.220),
		pcb_vcc_world + Vector3(0.015, 0.008, -0.004)
	]
	var gnd_pts := [
		p_gnd_world + (root.transform.basis.z * 0.017),
		Vector3(0.22, 0.019, 0.245),
		Vector3(0.15, 0.015, 0.275),
		pcb_gnd_world + Vector3(0.015, 0.008, 0.006)
	]
	for i in range(vcc_pts.size() - 1):
		_wire_segment(parent, vcc_pts[i], vcc_pts[i + 1], 0.0023, red_wire_mat)
	for i in range(gnd_pts.size() - 1):
		_wire_segment(parent, gnd_pts[i], gnd_pts[i + 1], 0.0023, blk_wire_mat)

	return {
		"root": root,
		"readout_lbl": readout_lbl,
		"volts_led": volts_led,
		"amps_led": amps_led,
		"cv_led": cv_led,
		"show_amps": false
	}
