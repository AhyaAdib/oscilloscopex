class_name Breadboard3DBuilder
extends RefCounted

const CIRCUIT_MODELS := [
	{
		"id": "RC_LPF",
		"name": "Model 1: RC Low-Pass Filter (1kΩ + 100nF)",
		"r_ohm": 1000.0,
		"c_farad": 100e-9,
		"v_in_amp": 2.5,
		"freq_hz": 1600.0,
		"summary": "Measure TP1 (Input) vs TP2 (Capacitor Out) to find cutoff attenuation and phase lag."
	},
	{
		"id": "DIODE_RECT",
		"name": "Model 2: Diode Rectifier & Ripple Filter",
		"v_in_amp": 3.0,
		"freq_hz": 500.0,
		"ripple_v": 0.45,
		"summary": "Probe TP1 (AC), TP2 (Half-Wave Rectified), and TP3 (Filtered DC Ripple)."
	},
	{
		"id": "ASTABLE_555",
		"name": "Model 3: NE555 Astable + ÷2 Clock Divider",
		"vcc": 5.0,
		"freq_hz": 1000.0,
		"summary": "Probe TP1 (Timing Cap Ramp), TP2 (555 Clock Out), and TP3 (÷2 Flip-Flop Out)."
	},
	{
		"id": "PROCEDURAL_MIX",
		"name": "Model 4: Procedural Circuit (Randomized R/C/Freq)",
		"r_ohm": 2200.0,
		"c_farad": 47e-9,
		"v_in_amp": 2.0,
		"freq_hz": 1200.0,
		"summary": "Procedural circuit with randomized R, C, and drive frequency. Probe TP1–TP4 to characterize!"
	}
]

static func build_breadboard_on_bench(parent: Node, snap_targets: Dictionary, interactables: Array) -> Dictionary:
	var root := Node3D.new()
	root.name = "BreadboardUnit"
	root.position = Vector3(0.02, 0.003, 0.285)
	parent.add_child(root)

	# 1. Main Board Substrate (switches between High-Contrast Cream Breadboard & Green FR-4 PCB)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.165, 0.008, 0.076)
	body.mesh = box
	body.position = Vector3(0.0, 0.004, 0.0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.95, 0.94, 0.90, 1.0)
	body_mat.roughness = 0.48
	body.material_override = body_mat
	root.add_child(body)

	# Dark Beveled Perimeter Frame for crisp contrast against blue ESD mat
	var frame := MeshInstance3D.new()
	var f_box := BoxMesh.new()
	f_box.size = Vector3(0.171, 0.005, 0.082)
	frame.mesh = f_box
	frame.position = Vector3(0.0, 0.0025, 0.0)
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.12, 0.14, 0.17, 1.0)
	f_mat.roughness = 0.65
	frame.material_override = f_mat
	root.add_child(frame)

	# Group A: Breadboard-only tie-point holes & power stripes
	var bb_details := Node3D.new()
	root.add_child(bb_details)

	var groove := MeshInstance3D.new()
	var g_box := BoxMesh.new()
	g_box.size = Vector3(0.156, 0.0014, 0.009)
	groove.mesh = g_box
	groove.position = Vector3(0.0, 0.0082, 0.0)
	var g_mat := StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.58, 0.57, 0.54, 1.0)
	groove.material_override = g_mat
	bb_details.add_child(groove)

	for side in [-1.0, 1.0]:
		var red_line := MeshInstance3D.new()
		var r_box := BoxMesh.new()
		r_box.size = Vector3(0.152, 0.0008, 0.0018)
		red_line.mesh = r_box
		red_line.position = Vector3(0.0, 0.0083, side * 0.033)
		var r_mat := StandardMaterial3D.new()
		r_mat.albedo_color = Color(0.90, 0.14, 0.14, 1.0)
		red_line.material_override = r_mat
		bb_details.add_child(red_line)

		var blue_line := MeshInstance3D.new()
		blue_line.mesh = r_box
		blue_line.position = Vector3(0.0, 0.0083, side * 0.028)
		var b_mat := StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.10, 0.36, 0.90, 1.0)
		blue_line.material_override = b_mat
		bb_details.add_child(blue_line)

	# High-contrast dark tie-point hole grid (22 columns x 6 rows)
	var hole_mesh := BoxMesh.new()
	hole_mesh.size = Vector3(0.0022, 0.0008, 0.0022)
	var hole_mat := StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.14, 0.15, 0.17, 1.0)
	for col in range(-10, 11):
		var hx := float(col) * 0.0070
		for row_z in [-0.021, -0.015, -0.009, 0.009, 0.015, 0.021]:
			var h := MeshInstance3D.new()
			h.mesh = hole_mesh
			h.position = Vector3(hx, 0.0082, row_z)
			h.material_override = hole_mat
			bb_details.add_child(h)

	# Group B: Green FR-4 PCB Copper Traces & Silkscreen (visible when PCB mode selected)
	var pcb_details := Node3D.new()
	pcb_details.visible = false
	root.add_child(pcb_details)

	var trace_mat := StandardMaterial3D.new()
	trace_mat.albedo_color = Color(0.95, 0.78, 0.24, 1.0)
	trace_mat.metallic = 0.85
	trace_mat.roughness = 0.22
	trace_mat.emission_enabled = true
	trace_mat.emission = Color(0.35, 0.28, 0.05, 1.0)
	trace_mat.emission_energy_multiplier = 0.45

	var trace_segments := [
		[Vector3(-0.056, 0.0083, 0.018), Vector3(-0.056, 0.0083, -0.012), 0.0026],
		[Vector3(-0.056, 0.0083, -0.012), Vector3(-0.020, 0.0083, -0.012), 0.0026],
		[Vector3(-0.020, 0.0083, -0.012), Vector3(-0.020, 0.0083, 0.018), 0.0026],
		[Vector3(-0.020, 0.0083, -0.012), Vector3(0.018, 0.0083, -0.012), 0.0026],
		[Vector3(0.018, 0.0083, -0.012), Vector3(0.018, 0.0083, 0.018), 0.0026],
		[Vector3(0.018, 0.0083, -0.012), Vector3(0.056, 0.0083, -0.012), 0.0026],
		[Vector3(-0.068, 0.0083, 0.028), Vector3(0.068, 0.0083, 0.028), 0.0032]
	]
	for seg in trace_segments:
		var p_a: Vector3 = seg[0]
		var p_b: Vector3 = seg[1]
		var w: float = seg[2]
		var t_mesh := MeshInstance3D.new()
		var t_box := BoxMesh.new()
		var span := p_b - p_a
		t_box.size = Vector3(maxf(absf(span.x), w), 0.0008, maxf(absf(span.z), w))
		t_mesh.mesh = t_box
		t_mesh.position = (p_a + p_b) * 0.5
		t_mesh.material_override = trace_mat
		pcb_details.add_child(t_mesh)

	# Shared Electronic Components (8-Pin DIP IC, Resistor + Leads, Capacitor, Diode)
	var lead_mat := StandardMaterial3D.new()
	lead_mat.albedo_color = Color(0.84, 0.86, 0.90, 1.0)
	lead_mat.metallic = 0.90
	lead_mat.roughness = 0.20

	var ic := MeshInstance3D.new()
	var ic_box := BoxMesh.new()
	ic_box.size = Vector3(0.020, 0.0048, 0.013)
	ic.mesh = ic_box
	ic.position = Vector3(-0.020, 0.0106, 0.0)
	var ic_mat := StandardMaterial3D.new()
	ic_mat.albedo_color = Color(0.10, 0.11, 0.13, 1.0)
	ic_mat.roughness = 0.40
	ic.material_override = ic_mat
	root.add_child(ic)

	# Resistor R1 + visible metallic leads
	var r_lead := MeshInstance3D.new()
	var rl_box := BoxMesh.new()
	rl_box.size = Vector3(0.026, 0.0012, 0.0012)
	r_lead.mesh = rl_box
	r_lead.position = Vector3(-0.048, 0.0105, -0.012)
	r_lead.material_override = lead_mat
	root.add_child(r_lead)

	var res := MeshInstance3D.new()
	var res_cyl := CylinderMesh.new()
	res_cyl.top_radius = 0.0022
	res_cyl.bottom_radius = 0.0022
	res_cyl.height = 0.012
	res.mesh = res_cyl
	res.rotation.z = PI * 0.5
	res.position = Vector3(-0.048, 0.0112, -0.012)
	var res_mat := StandardMaterial3D.new()
	res_mat.albedo_color = Color(0.86, 0.68, 0.42, 1.0)
	res.material_override = res_mat
	root.add_child(res)

	# Electrolytic Capacitor C1
	var cap := MeshInstance3D.new()
	var cap_cyl := CylinderMesh.new()
	cap_cyl.top_radius = 0.0038
	cap_cyl.bottom_radius = 0.0038
	cap_cyl.height = 0.010
	cap.mesh = cap_cyl
	cap.position = Vector3(0.018, 0.0132, -0.012)
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.10, 0.25, 0.58, 1.0)
	cap.material_override = cap_mat
	root.add_child(cap)

	# Diode D1 + metallic leads
	var d_lead := MeshInstance3D.new()
	d_lead.mesh = rl_box
	d_lead.position = Vector3(0.048, 0.0105, -0.012)
	d_lead.material_override = lead_mat
	root.add_child(d_lead)

	var diode := MeshInstance3D.new()
	var d_cyl := CylinderMesh.new()
	d_cyl.top_radius = 0.0017
	d_cyl.bottom_radius = 0.0017
	d_cyl.height = 0.008
	diode.mesh = d_cyl
	diode.rotation.z = PI * 0.5
	diode.position = Vector3(0.048, 0.0110, -0.012)
	var d_mat := StandardMaterial3D.new()
	d_mat.albedo_color = Color(0.92, 0.30, 0.14, 1.0)
	diode.material_override = d_mat
	root.add_child(diode)

	# 4 Upright Gold Test-Point Pins (TP1, TP2, TP3, TP4 GND) with high-contrast label plaques
	var tp_specs := [
		{"key": "BB_TP1", "label": "TP1", "x": -0.056, "col": Color(1.0, 0.82, 0.18)},
		{"key": "BB_TP2", "label": "TP2", "x": -0.020, "col": Color(0.20, 0.96, 0.74)},
		{"key": "BB_TP3", "label": "TP3", "x": 0.018, "col": Color(0.32, 0.82, 1.0)},
		{"key": "BB_TP4", "label": "TP4 GND", "x": 0.056, "col": Color(0.30, 0.32, 0.36)}
	]

	for tp in tp_specs:
		var pin_root := Node3D.new()
		pin_root.position = Vector3(tp["x"], 0.008, 0.018)
		root.add_child(pin_root)

		var bead := MeshInstance3D.new()
		var b_cyl := CylinderMesh.new()
		b_cyl.top_radius = 0.0028
		b_cyl.bottom_radius = 0.0028
		b_cyl.height = 0.0055
		bead.mesh = b_cyl
		bead.position = Vector3(0, 0.0027, 0)
		var b_mat := StandardMaterial3D.new()
		b_mat.albedo_color = tp["col"]
		bead.material_override = b_mat
		pin_root.add_child(bead)

		var post := MeshInstance3D.new()
		var p_cyl := CylinderMesh.new()
		p_cyl.top_radius = 0.0010
		p_cyl.bottom_radius = 0.0010
		p_cyl.height = 0.016
		post.mesh = p_cyl
		post.position = Vector3(0, 0.010, 0)
		var p_mat := StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.96, 0.82, 0.32, 1.0)
		p_mat.metallic = 0.88
		p_mat.roughness = 0.20
		post.material_override = p_mat
		pin_root.add_child(post)

		# High-contrast dark silkscreen badge under label
		var badge := MeshInstance3D.new()
		var bg_box := BoxMesh.new()
		bg_box.size = Vector3(0.024, 0.0008, 0.009)
		badge.mesh = bg_box
		badge.position = Vector3(0, 0.0005, 0.0115)
		var bg_mat := StandardMaterial3D.new()
		bg_mat.albedo_color = Color(0.08, 0.10, 0.13, 1.0)
		badge.material_override = bg_mat
		pin_root.add_child(badge)

		var lbl := Label3D.new()
		lbl.text = tp["label"]
		lbl.pixel_size = 0.00028
		lbl.font_size = 18
		lbl.modulate = tp["col"]
		lbl.outline_size = 2
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		lbl.rotation.x = -PI * 0.5
		lbl.position = Vector3(0, 0.0012, 0.0115)
		pin_root.add_child(lbl)

		snap_targets[tp["key"]] = {
			"node": pin_root,
			"kind": "tip",
			"offset": Vector3(0.0, 0.018, 0.002),
			"vertical": true,
			"label": "Board " + tp["label"]
		}

	return {
		"root": root,
		"body_mat": body_mat,
		"bb_details": bb_details,
		"pcb_details": pcb_details
	}

static func set_board_style(bb_data: Dictionary, is_pcb: bool) -> void:
	if bb_data.is_empty():
		return
	var body_mat: StandardMaterial3D = bb_data["body_mat"]
	var bb_details: Node3D = bb_data["bb_details"]
	var pcb_details: Node3D = bb_data["pcb_details"]
	if is_pcb:
		body_mat.albedo_color = Color(0.05, 0.34, 0.16, 1.0) # Classic FR-4 Solder Mask Green
		body_mat.roughness = 0.35
		bb_details.visible = false
		pcb_details.visible = true
	else:
		body_mat.albedo_color = Color(0.95, 0.94, 0.90, 1.0) # High-contrast Cream Breadboard
		body_mat.roughness = 0.48
		bb_details.visible = true
		pcb_details.visible = false

static func generate_breadboard_signal(model_cfg: Dictionary, tp_key: String, sample_count: int, time_span: float, sim_time_offset: float) -> Dictionary:
	var times := PackedFloat64Array()
	var volts := PackedFloat64Array()
	times.resize(sample_count)
	volts.resize(sample_count)
	var dt := time_span / float(maxi(sample_count - 1, 1))
	var model_id := str(model_cfg.get("id", "RC_LPF"))

	for i in range(sample_count):
		var t := sim_time_offset + float(i) * dt
		times[i] = t
		var v := 0.0

		if tp_key == "BB_TP4":
			v = 0.0
		elif model_id == "RC_LPF" or model_id == "PROCEDURAL_MIX":
			var r_ohm := float(model_cfg.get("r_ohm", 1000.0))
			var c_f := float(model_cfg.get("c_farad", 100e-9))
			var v_amp := float(model_cfg.get("v_in_amp", 2.5))
			var freq := float(model_cfg.get("freq_hz", 1600.0))
			var omega := TAU * freq
			var rc := maxf(r_ohm * c_f, 1e-9)
			var gain := 1.0 / sqrt(1.0 + pow(omega * rc, 2.0))
			var phase := -atan(omega * rc)
			if tp_key == "BB_TP1":
				v = v_amp * sin(omega * t)
			elif tp_key == "BB_TP2":
				v = v_amp * gain * sin(omega * t + phase)
			elif tp_key == "BB_TP3":
				v = v_amp * sin(omega * t) - v_amp * gain * sin(omega * t + phase)
		elif model_id == "DIODE_RECT":
			var v_amp := float(model_cfg.get("v_in_amp", 3.0))
			var freq := float(model_cfg.get("freq_hz", 500.0))
			var ripple := float(model_cfg.get("ripple_v", 0.45))
			var v_ac := v_amp * sin(TAU * freq * t)
			var v_rect := maxf(v_ac - 0.65, 0.0)
			if tp_key == "BB_TP1":
				v = v_ac
			elif tp_key == "BB_TP2":
				v = v_rect
			elif tp_key == "BB_TP3":
				var period := 1.0 / maxf(freq, 1.0)
				var cycle_pos := fmod(t + period * 0.75, period) / period
				var v_peak := maxf(v_amp - 0.65, 0.0)
				v = maxf(v_peak - ripple * cycle_pos, v_rect)
		elif model_id == "ASTABLE_555":
			var vcc := float(model_cfg.get("vcc", 5.0))
			var freq := float(model_cfg.get("freq_hz", 1000.0))
			var phase := fmod(t * freq, 1.0)
			if phase < 0.0:
				phase += 1.0
			if tp_key == "BB_TP1":
				if phase < 0.60:
					v = lerpf(vcc / 3.0, 2.0 * vcc / 3.0, phase / 0.60)
				else:
					v = lerpf(2.0 * vcc / 3.0, vcc / 3.0, (phase - 0.60) / 0.40)
			elif tp_key == "BB_TP2":
				v = vcc if phase < 0.60 else 0.0
			elif tp_key == "BB_TP3":
				var div2_phase := fmod(t * (freq * 0.5), 1.0)
				if div2_phase < 0.0:
					div2_phase += 1.0
				v = vcc if div2_phase < 0.50 else 0.0

		volts[i] = v

	return {"times": times, "voltages": volts, "dt": dt}
