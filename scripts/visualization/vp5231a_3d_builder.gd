class_name VP5231A3DBuilder
extends RefCounted

const COL_CABINET := Color(0.58, 0.56, 0.52, 1.0)
const COL_FACEPLATE := Color(0.78, 0.76, 0.72, 1.0)
const COL_BEZEL_CREAM := Color(0.85, 0.79, 0.68, 1.0)
const COL_KNOB_DARK := Color(0.15, 0.14, 0.14, 1.0)
const COL_KNOB_BEIGE := Color(0.76, 0.71, 0.61, 1.0)
const COL_KNOB_RED := Color(0.68, 0.20, 0.18, 1.0)
const COL_METAL_BNC := Color(0.82, 0.84, 0.86, 1.0)
const COL_SILKSCREEN := Color(0.10, 0.10, 0.09, 1.0)

static func build_oscilloscope(parent: Node, crt_texture: ViewportTexture) -> Dictionary:
	var root := Node3D.new()
	root.name = "National_VP5231A"
	root.position = Vector3(-0.17, 0.0, 0.0)
	parent.add_child(root)

	var interactables: Array[Dictionary] = []
	var snap_targets := {}

	# ==================== 1. NATIONAL VP-5231A OSCILLOSCOPE ====================
	_add_box(root, "Cabinet", Vector3(0.38, 0.19, 0.36), Vector3(0.0, 0.105, 0.0), _mat(COL_CABINET, 0.55, 0.25))

	var foot_mat := _mat(Color(0.10, 0.10, 0.10, 1.0), 0.85, 0.0)
	for fx in [-0.155, 0.155]:
		for fz in [-0.14, 0.14]:
			_add_cyl(root, "Foot", 0.014, 0.012, Vector3(fx, 0.006, fz), Vector3.ZERO, foot_mat)

	var handle_mat := _mat(Color(0.28, 0.27, 0.26, 1.0), 0.6, 0.3)
	_add_box(root, "HandleTop", Vector3(0.22, 0.012, 0.024), Vector3(0.0, 0.222, 0.02), handle_mat)
	_add_box(root, "HandleLeft", Vector3(0.014, 0.026, 0.024), Vector3(-0.103, 0.210, 0.02), handle_mat)
	_add_box(root, "HandleRight", Vector3(0.014, 0.026, 0.024), Vector3(0.103, 0.210, 0.02), handle_mat)

	var face_z := 0.181
	_add_box(root, "Faceplate", Vector3(0.372, 0.182, 0.004), Vector3(0.0, 0.105, face_z), _mat(COL_FACEPLATE, 0.45, 0.35))

	# Cream CRT Bezel
	var bezel_x := -0.092
	var bezel_y := 0.124
	var bezel_z := face_z + 0.008
	var bezel_mat := _mat(COL_BEZEL_CREAM, 0.50, 0.05)

	_add_box(root, "BezelTop", Vector3(0.172, 0.022, 0.016), Vector3(bezel_x, bezel_y + 0.056, bezel_z), bezel_mat)
	_add_box(root, "BezelBot", Vector3(0.172, 0.014, 0.016), Vector3(bezel_x, bezel_y - 0.056, bezel_z), bezel_mat)
	_add_box(root, "BezelLeft", Vector3(0.016, 0.098, 0.016), Vector3(bezel_x - 0.078, bezel_y, bezel_z), bezel_mat)
	_add_box(root, "BezelRight", Vector3(0.016, 0.098, 0.016), Vector3(bezel_x + 0.078, bezel_y, bezel_z), bezel_mat)

	_add_box(root, "Nameplate", Vector3(0.156, 0.011, 0.003), Vector3(bezel_x, bezel_y + 0.057, bezel_z + 0.008), _mat(Color(0.14, 0.13, 0.13, 1.0), 0.35, 0.4))
	_add_label_3d(root, "National", Vector3(bezel_x - 0.056, bezel_y + 0.057, bezel_z + 0.010), 22, Color(0.96, 0.94, 0.90))
	_add_label_3d(root, "OSCILLOSCOPE VP-5231A 30", Vector3(bezel_x + 0.024, bezel_y + 0.057, bezel_z + 0.010), 16, Color(0.92, 0.89, 0.82))

	# Live CRT Glass Screen
	var crt_mesh := QuadMesh.new()
	crt_mesh.size = Vector2(0.140, 0.100)
	var crt_mat := StandardMaterial3D.new()
	crt_mat.albedo_texture = crt_texture
	crt_mat.emission_enabled = true
	crt_mat.emission_texture = crt_texture
	crt_mat.emission_energy_multiplier = 0.85
	crt_mat.roughness = 0.15
	var crt_inst := MeshInstance3D.new()
	crt_inst.name = "CRTScreenMesh"
	crt_inst.mesh = crt_mesh
	crt_inst.material_override = crt_mat
	crt_inst.position = Vector3(bezel_x, bezel_y - 0.003, face_z + 0.005)
	root.add_child(crt_inst)

	# Lower CRT Strip
	var strip_y := 0.036
	_add_label_3d(root, "POWER", Vector3(-0.162, strip_y + 0.017, face_z + 0.003), 16, COL_SILKSCREEN)
	var pwr_btn := _add_push_button(root, "power_on", "POWER (ON/OFF)", Vector3(-0.162, strip_y + 0.002, face_z + 0.006), interactables)
	var led_mat := _mat(Color(1.0, 0.58, 0.10, 1.0), 0.2, 0.0)
	led_mat.emission_enabled = true
	led_mat.emission = Color(1.0, 0.55, 0.08, 1.0)
	led_mat.emission_energy_multiplier = 1.6
	_add_cyl(root, "PowerPilotLED", 0.0028, 0.004, Vector3(-0.162, strip_y - 0.011, face_z + 0.003), Vector3(PI * 0.5, 0, 0), led_mat)

	# CAL 1Vp-p Terminal (Snap Target for Probe Tip)
	_add_label_3d(root, "CAL 1Vp-p", Vector3(-0.141, strip_y + 0.017, face_z + 0.003), 15, COL_SILKSCREEN)
	var cal_node := _add_bnc_jack(root, "CAL_HOOK", Vector3(-0.141, strip_y + 0.001, face_z + 0.006), 0.72)
	snap_targets["CAL_1VPP"] = {"node": cal_node, "kind": "tip", "label": "Scope CAL 1Vp-p (1 kHz Square)", "offset": Vector3(0, 0, 0.008)}

	_add_rotary_knob_3d(root, "intensity", "INTENSITY", Vector3(-0.114, strip_y, face_z + 0.003), 0.0095, COL_KNOB_DARK, 0.1, 1.0, 0.05, 0.85, [], interactables)
	_add_rotary_knob_3d(root, "focus", "FOCUS", Vector3(-0.083, strip_y, face_z + 0.003), 0.0095, COL_KNOB_DARK, 0.1, 1.0, 0.05, 0.88, [], interactables)
	_add_rotary_knob_3d(root, "scale_illum", "SCALE ILLUM", Vector3(-0.052, strip_y, face_z + 0.003), 0.0095, COL_KNOB_DARK, 0.0, 1.0, 0.05, 0.65, [], interactables)

	_add_label_3d(root, "GND", Vector3(-0.023, strip_y + 0.016, face_z + 0.003), 15, COL_SILKSCREEN)
	_add_cyl(root, "GNDJack", 0.005, 0.010, Vector3(-0.023, strip_y - 0.001, face_z + 0.005), Vector3(PI * 0.5, 0, 0), _mat(Color(0.08, 0.08, 0.08, 1.0), 0.4, 0.2))

	# Divider Lines
	var ink_mat := _mat(Color(0.25, 0.24, 0.23, 1.0), 0.8, 0.0)
	_add_box(root, "DivH", Vector3(0.180, 0.0012, 0.001), Vector3(0.092, 0.110, face_z + 0.0022), ink_mat)
	_add_box(root, "DivVTop", Vector3(0.0012, 0.078, 0.001), Vector3(0.084, 0.150, face_z + 0.0022), ink_mat)
	_add_box(root, "DivVBot", Vector3(0.0012, 0.088, 0.001), Vector3(0.092, 0.064, face_z + 0.0022), ink_mat)

	# TRIGGER
	_add_label_3d(root, "TRIGGER", Vector3(0.036, 0.186, face_z + 0.003), 18, COL_SILKSCREEN)
	_add_rotary_knob_3d(root, "trigger_level", "LEVEL", Vector3(0.022, 0.158, face_z + 0.003), 0.010, COL_KNOB_BEIGE, -4.0, 4.0, 0.1, 0.0, [], interactables)
	_add_slide_switch_3d(root, "trigger_slope", "SLOPE", Vector3(0.056, 0.160, face_z + 0.003), ["+ RISE", "- FALL"], 0, true, interactables)
	_add_slide_switch_3d(root, "persist_toggle", "PERSIST", Vector3(0.075, 0.160, face_z + 0.003), ["OFF", "MED", "HIGH"], 1, true, interactables)

	# HORIZONTAL / TIME/DIV
	_add_label_3d(root, "TIME / DIV", Vector3(0.142, 0.186, face_z + 0.003), 18, COL_SILKSCREEN)
	_add_rotary_knob_3d(root, "time_per_div", "TIME/DIV", Vector3(0.145, 0.155, face_z + 0.003), 0.0145, COL_KNOB_RED, 0.0, 5.0, 1.0, 2.0, ["0.1ms", "0.2ms", "0.5ms", "1ms", "2ms", "5ms"], interactables)
	_add_rotary_knob_3d(root, "horiz_pos_div", "POSITION", Vector3(0.112, 0.123, face_z + 0.003), 0.0085, COL_KNOB_BEIGE, -5.0, 5.0, 0.2, 0.0, [], interactables)
	_add_label_3d(root, "EXT TRIG", Vector3(0.156, 0.130, face_z + 0.003), 14, COL_SILKSCREEN)
	_add_bnc_jack(root, "EXT_TRIG_BNC", Vector3(0.156, 0.118, face_z + 0.006), 0.85)

	# VERTICAL CH 1
	_add_label_3d(root, "CH 1", Vector3(0.042, 0.103, face_z + 0.003), 18, COL_SILKSCREEN)
	_add_rotary_knob_3d(root, "vert_pos_div", "POSITION", Vector3(0.024, 0.084, face_z + 0.003), 0.0085, COL_KNOB_DARK, -4.0, 4.0, 0.2, 0.0, [], interactables)
	_add_rotary_knob_3d(root, "probe_compensation", "PROBE COMP", Vector3(0.062, 0.084, face_z + 0.003), 0.0080, COL_KNOB_BEIGE, 0.65, 1.35, 0.05, 1.0, [], interactables)
	_add_rotary_knob_3d(root, "volts_per_div", "VOLTS/DIV", Vector3(0.044, 0.052, face_z + 0.003), 0.014, COL_KNOB_RED, 0.0, 4.0, 1.0, 2.0, ["0.2V", "0.5V", "1V", "2V", "5V"], interactables)

	var ch1_bnc_node := _add_bnc_jack(root, "CH1_INPUT_BNC", Vector3(0.022, 0.024, face_z + 0.006), 0.92)
	snap_targets["CH1"] = {"node": ch1_bnc_node, "kind": "bnc", "label": "VP-5231A CH 1 INPUT BNC", "offset": Vector3(0, 0, 0.012)}
	_add_slide_switch_3d(root, "coupling", "AC-GND-DC", Vector3(0.062, 0.024, face_z + 0.003), ["DC", "AC", "GND"], 0, false, interactables)

	# VERTICAL MODE
	_add_slide_switch_3d(root, "vert_mode", "MODE", Vector3(0.092, 0.065, face_z + 0.003), ["CH1", "ALT", "CH2"], 0, true, interactables)

	# VERTICAL CH 2
	_add_label_3d(root, "CH 2", Vector3(0.138, 0.103, face_z + 0.003), 18, COL_SILKSCREEN)
	_add_rotary_knob_3d(root, "ch2_var", "VARIABLE", Vector3(0.118, 0.084, face_z + 0.003), 0.0080, COL_KNOB_BEIGE, 0.0, 1.0, 0.1, 0.5, [], interactables)
	_add_rotary_knob_3d(root, "ch2_pos", "POSITION", Vector3(0.156, 0.084, face_z + 0.003), 0.0085, COL_KNOB_DARK, -4.0, 4.0, 0.2, 0.0, [], interactables)
	_add_rotary_knob_3d(root, "ch2_volts", "VOLTS/DIV", Vector3(0.138, 0.052, face_z + 0.003), 0.014, COL_KNOB_RED, 0.0, 4.0, 1.0, 2.0, ["0.2V", "0.5V", "1V", "2V", "5V"], interactables)
	var ch2_bnc_node := _add_bnc_jack(root, "CH2_INPUT_BNC", Vector3(0.156, 0.024, face_z + 0.006), 0.92)
	snap_targets["CH2"] = {"node": ch2_bnc_node, "kind": "bnc", "label": "VP-5231A CH 2 INPUT BNC", "offset": Vector3(0, 0, 0.012)}
	_add_slide_switch_3d(root, "ch2_coupling", "AC-GND-DC", Vector3(0.118, 0.024, face_z + 0.003), ["DC", "AC", "GND"], 0, false, interactables)

	# ==================== 2. SIGLENT SDG1032X WAVEFORM GENERATOR ====================
	var fg := Node3D.new()
	fg.name = "Siglent_SDG1032X"
	fg.position = Vector3(0.24, 0.0, 0.04)
	parent.add_child(fg)

	_add_box(fg, "FGChassis", Vector3(0.26, 0.115, 0.28), Vector3(0.0, 0.062, 0.0), _mat(Color(0.76, 0.77, 0.79, 1.0), 0.45, 0.2))
	var bumper_mat := _mat(Color(0.36, 0.38, 0.41, 1.0), 0.75, 0.05)
	_add_box(fg, "BumperFront", Vector3(0.272, 0.125, 0.026), Vector3(0.0, 0.063, 0.132), bumper_mat)
	_add_box(fg, "BumperBack", Vector3(0.272, 0.125, 0.026), Vector3(0.0, 0.063, -0.132), bumper_mat)

	var fg_z := 0.145
	_add_box(fg, "FGFrontPanel", Vector3(0.252, 0.106, 0.004), Vector3(0.0, 0.063, fg_z), _mat(Color(0.24, 0.25, 0.27, 1.0), 0.5, 0.25))

	_add_label_3d(fg, "SIGLENT", Vector3(-0.095, 0.106, fg_z + 0.003), 18, Color(0.95, 0.96, 0.98))
	_add_label_3d(fg, "SDG1032X  30MHz Arbitrary Waveform Generator", Vector3(0.025, 0.106, fg_z + 0.003), 13, Color(0.75, 0.80, 0.85))

	_add_box(fg, "LCDBezel", Vector3(0.112, 0.068, 0.004), Vector3(-0.062, 0.064, fg_z + 0.003), _mat(Color(0.10, 0.11, 0.13, 1.0), 0.3, 0.1))
	var lcd_screen := _add_box(fg, "LCDScreen", Vector3(0.102, 0.058, 0.002), Vector3(-0.062, 0.064, fg_z + 0.005), _mat(Color(0.04, 0.12, 0.18, 1.0), 0.15, 0.0))
	var lcd_mat: StandardMaterial3D = lcd_screen.material_override
	lcd_mat.emission_enabled = true
	lcd_mat.emission = Color(0.05, 0.16, 0.24, 1.0)
	lcd_mat.emission_energy_multiplier = 1.1

	var fg_wf_lbl := _add_label_3d(fg, "CH1: SINE  [ON]", Vector3(-0.062, 0.082, fg_z + 0.007), 16, Color(1.0, 0.85, 0.25))
	var fg_freq_lbl := _add_label_3d(fg, "Freq: 1000 Hz", Vector3(-0.062, 0.065, fg_z + 0.007), 16, Color(0.35, 1.0, 0.78))
	var fg_amp_lbl := _add_label_3d(fg, "Ampl: 4.00 Vpp", Vector3(-0.062, 0.048, fg_z + 0.007), 16, Color(0.45, 0.85, 1.0))

	for k in range(5):
		var kx := -0.102 + float(k) * 0.020
		_add_box(fg, "SoftKey" + str(k), Vector3(0.014, 0.006, 0.004), Vector3(kx, 0.023, fg_z + 0.003), _mat(Color(0.75, 0.77, 0.80, 1.0), 0.4, 0.2))

	_add_push_button(fg, "fg_waveform", "FG WAVEFORM", Vector3(0.016, 0.086, fg_z + 0.004), interactables)
	_add_label_3d(fg, "WAVE", Vector3(0.016, 0.097, fg_z + 0.003), 12, Color(0.9, 0.9, 0.92))

	_add_push_button(fg, "fg_sel_ch1", "SELECT FG CH1 (Yellow)", Vector3(0.056, 0.086, fg_z + 0.004), interactables)
	_add_label_3d(fg, "CH1", Vector3(0.056, 0.097, fg_z + 0.003), 12, Color(1.0, 0.85, 0.25))

	_add_push_button(fg, "fg_sel_ch2", "SELECT FG CH2 (Cyan)", Vector3(0.092, 0.086, fg_z + 0.004), interactables)
	_add_label_3d(fg, "CH2", Vector3(0.092, 0.097, fg_z + 0.003), 12, Color(0.45, 0.85, 1.0))

	_add_rotary_knob_3d(fg, "fg_frequency", "FG FREQ", Vector3(0.018, 0.056, fg_z + 0.003), 0.011, COL_KNOB_BEIGE, 100.0, 5000.0, 100.0, 1000.0, [], interactables)
	_add_rotary_knob_3d(fg, "fg_amplitude", "FG AMPL", Vector3(0.058, 0.056, fg_z + 0.003), 0.010, COL_KNOB_DARK, 0.2, 8.0, 0.2, 2.0, [], interactables)
	_add_rotary_knob_3d(fg, "fg_offset", "FG OFFSET", Vector3(0.098, 0.056, fg_z + 0.003), 0.009, COL_KNOB_DARK, -3.0, 3.0, 0.2, 0.0, [], interactables)

	# CH1 OUT & CH2 OUT BNC Connectors (BOTH registered as valid snap targets!)
	_add_label_3d(fg, "CH1 OUT", Vector3(0.048, 0.036, fg_z + 0.003), 13, Color(1.0, 0.85, 0.25))
	var fg_ch1_node := _add_bnc_jack(fg, "FG_CH1_OUT", Vector3(0.048, 0.022, fg_z + 0.006), 0.90)
	snap_targets["FG_CH1"] = {"node": fg_ch1_node, "kind": "tip", "label": "Siglent SDG1032X CH1 OUT (50Ω)", "offset": Vector3(0, 0, 0.010)}

	_add_label_3d(fg, "CH2 OUT", Vector3(0.095, 0.036, fg_z + 0.003), 13, Color(0.45, 0.85, 1.0))
	var fg_ch2_node := _add_bnc_jack(fg, "FG_CH2_OUT", Vector3(0.095, 0.022, fg_z + 0.006), 0.90)
	snap_targets["FG_CH2"] = {"node": fg_ch2_node, "kind": "tip", "label": "Siglent SDG1032X CH2 OUT (+90°)", "offset": Vector3(0, 0, 0.010)}

	# ==================== 3. DUAL P6100 PASSIVE OSCILLOSCOPE PROBES (YELLOW & RED) ====================
	var probe1 := _build_p6100_probe(parent, 1, "Probe 1 (Yellow)", Color(0.95, 0.80, 0.15, 1.0), interactables, true)
	var probe2 := _build_p6100_probe(parent, 2, "Probe 2 (Red)", Color(0.90, 0.22, 0.20, 1.0), interactables, false)

	return {
		"root": root,
		"crt_material": crt_mat,
		"power_led_material": led_mat,
		"power_button_mesh": pwr_btn,
		"probe1": probe1,
		"probe2": probe2,
		"snap_targets": snap_targets,
		"fg_wf_lbl": fg_wf_lbl,
		"fg_freq_lbl": fg_freq_lbl,
		"fg_amp_lbl": fg_amp_lbl,
		"interactables": interactables
	}

static func _build_p6100_probe(parent: Node, idx: int, label_prefix: String, ring_color: Color, interactables: Array[Dictionary], has_atten_switch: bool) -> Dictionary:
	var asm := Node3D.new()
	asm.name = "P6100_Probe_" + str(idx)
	parent.add_child(asm)

	var grey_body_mat := _mat(Color(0.32, 0.34, 0.36, 1.0), 0.45, 0.15)
	var dark_boot_mat := _mat(Color(0.14, 0.14, 0.15, 1.0), 0.65, 0.05)
	var id_ring_mat := _mat(ring_color, 0.35, 0.05)
	var metal_mat := _mat(COL_METAL_BNC, 0.22, 0.85)

	# 1. BNC Connector End (Metallic locking collar + grey housing + color ID ring + ribbed strain relief)
	var bnc_plug := Node3D.new()
	bnc_plug.name = "BNCPlug_" + str(idx)
	asm.add_child(bnc_plug)
	_add_cyl(bnc_plug, "MetalCollar", 0.0072, 0.014, Vector3(0, 0, 0.007), Vector3(PI * 0.5, 0, 0), metal_mat)
	_add_cyl(bnc_plug, "GreyHousing", 0.0076, 0.018, Vector3(0, 0, 0.022), Vector3(PI * 0.5, 0, 0), grey_body_mat)
	_add_cyl(bnc_plug, "ColorRingBNC", 0.0079, 0.003, Vector3(0, 0, 0.032), Vector3(PI * 0.5, 0, 0), id_ring_mat)
	_add_cyl(bnc_plug, "StrainBoot", 0.0048, 0.022, Vector3(0, 0, 0.044), Vector3(PI * 0.5, 0, 0), dark_boot_mat)

	interactables.append({
		"type": "draggable_bnc",
		"probe_idx": idx,
		"title": "%s BNC Plug (Drag to Scope CH1 or CH2 INPUT)" % label_prefix,
		"focus_node": bnc_plug,
		"hit_radius": 0.018,
		"ring_radius": 0.016
	})

	# 2. P6100 Hook Probe Barrel (Hook tip + tapered nose + finger guard + color ID ring + red 1x/10x switch + GND alligator clip)
	var probe_tip := Node3D.new()
	probe_tip.name = "ProbeHandle_" + str(idx)
	asm.add_child(probe_tip)

	_add_cyl(probe_tip, "HookPin", 0.0016, 0.016, Vector3(0, 0, 0.004), Vector3(PI * 0.5, 0, 0), metal_mat)
	_add_cyl(probe_tip, "HookSheath", 0.0032, 0.022, Vector3(0, 0, 0.018), Vector3(PI * 0.5, 0, 0), grey_body_mat)
	_add_cyl(probe_tip, "FingerGuard", 0.0085, 0.003, Vector3(0, 0, 0.030), Vector3(PI * 0.5, 0, 0), grey_body_mat)
	_add_cyl(probe_tip, "MainBarrel", 0.0058, 0.052, Vector3(0, 0, 0.056), Vector3(PI * 0.5, 0, 0), grey_body_mat)
	_add_cyl(probe_tip, "ColorRingTip", 0.0061, 0.003, Vector3(0, 0, 0.078), Vector3(PI * 0.5, 0, 0), id_ring_mat)
	_add_cyl(probe_tip, "TailBoot", 0.0040, 0.018, Vector3(0, 0, 0.090), Vector3(PI * 0.5, 0, 0), dark_boot_mat)

	# Ground Alligator Clip Lead branching off collar
	_add_cyl(probe_tip, "GndWire", 0.0014, 0.038, Vector3(0.016, -0.006, 0.044), Vector3(PI * 0.45, 0.42, 0), dark_boot_mat)
	_add_box(probe_tip, "AlligatorClip", Vector3(0.005, 0.005, 0.018), Vector3(0.026, -0.009, 0.064), dark_boot_mat)

	interactables.append({
		"type": "draggable_tip",
		"probe_idx": idx,
		"title": "%s Hook Tip (Drag to FG CH1/CH2 OUT or CAL 1Vp-p)" % label_prefix,
		"focus_node": probe_tip,
		"hit_radius": 0.022,
		"ring_radius": 0.018
	})

	if has_atten_switch:
		_add_slide_switch_3d(probe_tip, "probe_attenuation_switch", "1x / 10x", Vector3(0.0, 0.007, 0.056), ["1x", "10x"], 0, false, interactables)

	# 28-Segment Solid 3D Cylindrical Coaxial Cable
	var cable_segments: Array[MeshInstance3D] = []
	var cable_mat := _mat(Color(0.11, 0.11, 0.12, 1.0), 0.55, 0.05)
	for s in range(28):
		var seg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0024
		cm.bottom_radius = 0.0024
		cm.height = 1.0
		cm.radial_segments = 10
		seg.mesh = cm
		seg.material_override = cable_mat
		asm.add_child(seg)
		cable_segments.append(seg)

	return {
		"idx": idx,
		"bnc_plug": bnc_plug,
		"probe_tip": probe_tip,
		"cable_segments": cable_segments
	}

static func update_single_probe(probe_data: Dictionary, snaps: Dictionary, bnc_ch: String, tip_tgt: String, dragging_kind := "", drag_world := Vector3.ZERO) -> void:
	if probe_data.is_empty():
		return
	var idx: int = int(probe_data["idx"])
	var bnc_plug: Node3D = probe_data["bnc_plug"]
	var probe_tip: Node3D = probe_data["probe_tip"]

	# Position BNC Plug
	if dragging_kind == "bnc":
		bnc_plug.global_position = drag_world
		bnc_plug.rotation = Vector3(0.15, 0.0, 0.0)
	elif snaps.has(bnc_ch):
		var info: Dictionary = snaps[bnc_ch]
		var n: Node3D = info["node"]
		bnc_plug.global_position = n.global_position + info["offset"]
		bnc_plug.rotation = Vector3.ZERO
	else:
		# Rest neatly on ESD mat in front of Scope
		var rest_x := -0.22 if idx == 1 else -0.10
		bnc_plug.global_position = Vector3(rest_x, 0.011, 0.25)
		bnc_plug.rotation = Vector3(0.0, 0.25, 0.0)

	# Position Probe Tip
	if dragging_kind == "tip":
		probe_tip.global_position = drag_world
		probe_tip.rotation = Vector3(-0.20, 0.0, 0.0)
	elif snaps.has(tip_tgt):
		var info: Dictionary = snaps[tip_tgt]
		var n: Node3D = info["node"]
		var offset_v: Vector3 = info["offset"]
		# Slight offset if both probes clip onto the same CAL terminal
		if idx == 2 and tip_tgt == "CAL_1VPP":
			offset_v += Vector3(0.008, -0.005, 0.0)
		probe_tip.global_position = n.global_position + offset_v
		probe_tip.rotation = Vector3(-0.12, 0.20 if tip_tgt == "CAL_1VPP" else -0.15, 0.0)
	else:
		# Rest neatly on ESD mat in front of Function Generator
		var rest_tx := 0.05 if idx == 1 else 0.16
		probe_tip.global_position = Vector3(rest_tx, 0.011, 0.27)
		probe_tip.rotation = Vector3(0.0, -0.45, 0.0)

	# Update 28-Segment 3D Coaxial Cable (scale applied AFTER look_at!)
	var p0 := bnc_plug.global_position + bnc_plug.global_transform.basis.z * 0.052
	var p1 := probe_tip.global_position + probe_tip.global_transform.basis.z * 0.096
	var segs: Array = probe_data["cable_segments"]
	var count := segs.size()

	var pts: Array[Vector3] = []
	for i in range(count + 1):
		var t := float(i) / float(count)
		var pt := p0.lerp(p1, t)
		pt.z += sin(t * PI) * (0.065 if idx == 1 else 0.090)
		pt.y = maxf(pt.y - sin(t * PI) * 0.045, 0.004)
		pts.append(pt)

	for i in range(count):
		var a := pts[i]
		var b := pts[i + 1]
		var seg: MeshInstance3D = segs[i]
		var diff := b - a
		var length := maxf(diff.length(), 1e-4)
		var mid := (a + b) * 0.5
		var up_dir := diff / length
		if absf(up_dir.dot(Vector3.UP)) > 0.99:
			seg.look_at_from_position(mid, b, Vector3.FORWARD)
		else:
			seg.look_at_from_position(mid, b, Vector3.UP)
		seg.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		seg.scale = Vector3(1.0, length, 1.0)

static func _add_rotary_knob_3d(
	parent: Node3D,
	param_id: String,
	title: String,
	pos: Vector3,
	radius: float,
	cap_color: Color,
	min_v: float,
	max_v: float,
	step_v: float,
	init_v: float,
	labels: Array,
	interactables: Array[Dictionary]
) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Knob_" + param_id
	holder.position = pos
	parent.add_child(holder)

	_add_label_3d(holder, title, Vector3(0.0, radius + 0.0065, 0.001), 15, COL_SILKSCREEN)

	var skirt_mat := _mat(Color(0.86, 0.84, 0.80, 1.0), 0.4, 0.2)
	_add_cyl(holder, "Skirt", radius * 1.12, 0.003, Vector3(0, 0, 0.0015), Vector3(PI * 0.5, 0, 0), skirt_mat)

	var rotor := Node3D.new()
	rotor.name = "Rotor"
	rotor.position = Vector3(0, 0, 0.003)
	holder.add_child(rotor)

	_add_cyl(rotor, "Body", radius, 0.012, Vector3(0, 0, 0.006), Vector3(PI * 0.5, 0, 0), _mat(COL_KNOB_DARK, 0.55, 0.1))
	_add_cyl(rotor, "Cap", radius * 0.62, 0.002, Vector3(0, 0, 0.0125), Vector3(PI * 0.5, 0, 0), _mat(cap_color, 0.45, 0.15))
	_add_box(rotor, "Pointer", Vector3(0.0018, radius * 0.88, 0.0020), Vector3(0.0, radius * 0.44, 0.0132), _mat(Color(0.96, 0.95, 0.92, 1.0), 0.3, 0.0))

	var norm := clampf((init_v - min_v) / maxf(max_v - min_v, 1e-6), 0.0, 1.0)
	rotor.rotation.z = lerpf(deg_to_rad(135.0), deg_to_rad(-135.0), norm)

	interactables.append({
		"type": "knob",
		"param_id": param_id,
		"title": title,
		"rotor": rotor,
		"focus_node": rotor,
		"hit_radius": maxf(radius * 1.65, 0.014),
		"ring_radius": radius * 1.35,
		"min": min_v,
		"max": max_v,
		"step": step_v,
		"value": init_v,
		"labels": labels
	})
	return rotor

static func _add_slide_switch_3d(
	parent: Node3D,
	param_id: String,
	title: String,
	pos: Vector3,
	options: Array,
	init_idx: int,
	vertical: bool,
	interactables: Array[Dictionary]
) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Switch_" + param_id
	holder.position = pos
	parent.add_child(holder)

	_add_label_3d(holder, title, Vector3(0.0, 0.0135 if vertical else 0.0095, 0.001), 14, COL_SILKSCREEN)

	var slot_size := Vector3(0.006, 0.018, 0.002) if vertical else Vector3(0.022, 0.006, 0.002)
	_add_box(holder, "Slot", slot_size, Vector3(0, 0, 0.001), _mat(Color(0.14, 0.14, 0.14, 1.0), 0.8, 0.1))

	var nub := _add_box(holder, "Actuator", Vector3(0.0055, 0.0055, 0.0075), Vector3(0, 0, 0.004), _mat(Color(0.85, 0.22, 0.18, 1.0) if param_id == "probe_attenuation_switch" else Color(0.28, 0.27, 0.26, 1.0), 0.4, 0.3))

	var meta := {
		"type": "switch",
		"param_id": param_id,
		"title": title,
		"actuator": nub,
		"focus_node": nub,
		"hit_radius": 0.014,
		"ring_radius": 0.012,
		"options": options,
		"index": init_idx,
		"vertical": vertical
	}
	update_switch_visual(meta)
	interactables.append(meta)
	return nub

static func update_switch_visual(meta: Dictionary) -> void:
	var nub: Node3D = meta["actuator"]
	var count: int = maxi(meta["options"].size(), 2)
	var idx: int = clampi(int(meta["index"]), 0, count - 1)
	var frac := float(idx) / float(count - 1)
	var offset := lerpf(-0.006, 0.006, frac)
	if meta["vertical"]:
		nub.position.y = -offset
	else:
		nub.position.x = offset

static func _add_push_button(parent: Node3D, param_id: String, title: String, pos: Vector3, interactables: Array[Dictionary]) -> MeshInstance3D:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)

	var cap := _add_box(holder, "ButtonCap", Vector3(0.010, 0.010, 0.008), Vector3(0, 0, 0.003), _mat(Color(0.18, 0.17, 0.17, 1.0), 0.45, 0.2))

	interactables.append({
		"type": "button",
		"param_id": param_id,
		"title": title,
		"cap": cap,
		"focus_node": cap,
		"hit_radius": 0.013,
		"ring_radius": 0.010
	})
	return cap

static func _add_bnc_jack(parent: Node3D, jack_name: String, pos: Vector3, scale_f := 1.0) -> Node3D:
	var holder := Node3D.new()
	holder.name = jack_name
	holder.position = pos
	parent.add_child(holder)

	var metal_mat := _mat(COL_METAL_BNC, 0.25, 0.85)
	var insulator_mat := _mat(Color(0.92, 0.92, 0.90, 1.0), 0.35, 0.0)
	_add_cyl(holder, "Flange", 0.0075 * scale_f, 0.003 * scale_f, Vector3(0, 0, 0.0015), Vector3(PI * 0.5, 0, 0), metal_mat)
	_add_cyl(holder, "Barrel", 0.0052 * scale_f, 0.012 * scale_f, Vector3(0, 0, 0.007 * scale_f), Vector3(PI * 0.5, 0, 0), metal_mat)
	_add_cyl(holder, "Dielectric", 0.0032 * scale_f, 0.0125 * scale_f, Vector3(0, 0, 0.0072 * scale_f), Vector3(PI * 0.5, 0, 0), insulator_mat)
	return holder

static func _add_box(parent: Node3D, node_name: String, sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, node_name: String, r: float, h: float, pos: Vector3, rot: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 24
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_label_3d(parent: Node3D, text: String, pos: Vector3, px_size: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = 0.00024
	l.font_size = px_size
	l.outline_size = 0
	l.modulate = col
	l.no_depth_test = false
	l.shaded = false
	l.position = pos
	parent.add_child(l)
	return l

static func _mat(col: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m
