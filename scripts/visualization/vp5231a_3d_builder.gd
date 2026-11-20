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
	root.position = Vector3(-0.14, 0.0, 0.0) # Placed on left-center of ESD mat to make room for Func Gen
	parent.add_child(root)

	var interactables := {}

	# 1. Main Sheet-Metal Enclosure
	var cabinet_mat := _mat(COL_CABINET, 0.55, 0.25)
	_add_box(root, "Cabinet", Vector3(0.38, 0.19, 0.36), Vector3(0.0, 0.105, 0.0), cabinet_mat)

	var foot_mat := _mat(Color(0.10, 0.10, 0.10, 1.0), 0.85, 0.0)
	for fx in [-0.155, 0.155]:
		for fz in [-0.14, 0.14]:
			_add_cyl(root, "Foot", 0.014, 0.012, Vector3(fx, 0.006, fz), Vector3.ZERO, foot_mat)

	# Carrying Handle
	var handle_mat := _mat(Color(0.28, 0.27, 0.26, 1.0), 0.6, 0.3)
	_add_box(root, "HandleTop", Vector3(0.22, 0.012, 0.024), Vector3(0.0, 0.222, 0.02), handle_mat)
	_add_box(root, "HandleLeft", Vector3(0.014, 0.026, 0.024), Vector3(-0.103, 0.210, 0.02), handle_mat)
	_add_box(root, "HandleRight", Vector3(0.014, 0.026, 0.024), Vector3(0.103, 0.210, 0.02), handle_mat)

	# Front Faceplate
	var face_z := 0.181
	var face_mat := _mat(COL_FACEPLATE, 0.45, 0.35)
	_add_box(root, "Faceplate", Vector3(0.372, 0.182, 0.004), Vector3(0.0, 0.105, face_z), face_mat)

	# ==================== LEFT HALF: CREAM CRT BEZEL + LOWER STRIP ====================
	var bezel_x := -0.092
	var bezel_y := 0.124
	var bezel_z := face_z + 0.008
	var bezel_mat := _mat(COL_BEZEL_CREAM, 0.50, 0.05)

	_add_box(root, "BezelTop", Vector3(0.172, 0.022, 0.016), Vector3(bezel_x, bezel_y + 0.056, bezel_z), bezel_mat)
	_add_box(root, "BezelBot", Vector3(0.172, 0.014, 0.016), Vector3(bezel_x, bezel_y - 0.056, bezel_z), bezel_mat)
	_add_box(root, "BezelLeft", Vector3(0.016, 0.098, 0.016), Vector3(bezel_x - 0.078, bezel_y, bezel_z), bezel_mat)
	_add_box(root, "BezelRight", Vector3(0.016, 0.098, 0.016), Vector3(bezel_x + 0.078, bezel_y, bezel_z), bezel_mat)

	# Top Nameplate
	var badge_mat := _mat(Color(0.14, 0.13, 0.13, 1.0), 0.35, 0.4)
	_add_box(root, "Nameplate", Vector3(0.156, 0.011, 0.003), Vector3(bezel_x, bezel_y + 0.057, bezel_z + 0.008), badge_mat)
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

	# Lower CRT Control Strip
	var strip_y := 0.036
	_add_label_3d(root, "POWER", Vector3(-0.162, strip_y + 0.017, face_z + 0.003), 16, COL_SILKSCREEN)
	var pwr_btn := _add_push_button(root, "power_on", "POWER (ON/OFF)", Vector3(-0.162, strip_y + 0.002, face_z + 0.006), interactables)
	var led_mat := _mat(Color(1.0, 0.58, 0.10, 1.0), 0.2, 0.0)
	led_mat.emission_enabled = true
	led_mat.emission = Color(1.0, 0.55, 0.08, 1.0)
	led_mat.emission_energy_multiplier = 1.6
	_add_cyl(root, "PowerPilotLED", 0.0028, 0.004, Vector3(-0.162, strip_y - 0.011, face_z + 0.003), Vector3(PI * 0.5, 0, 0), led_mat)

	# Interactive CAL 1Vp-p Calibration Hook Loop!
	_add_label_3d(root, "CAL 1Vp-p", Vector3(-0.141, strip_y + 0.017, face_z + 0.003), 15, COL_SILKSCREEN)
	var cal_pos := Vector3(-0.141, strip_y + 0.001, face_z + 0.006)
	_add_interactive_terminal(root, "cal_terminal", "CAL 1Vp-p Terminal (Click to Clip Probe)", cal_pos, 0.006, interactables)

	# INTENSITY, FOCUS, SCALE ILLUM
	_add_rotary_knob_3d(root, "intensity", "INTENSITY", Vector3(-0.114, strip_y, face_z + 0.003), 0.0095, COL_KNOB_DARK, 0.1, 1.0, 0.05, 0.85, [], interactables)
	_add_rotary_knob_3d(root, "focus", "FOCUS", Vector3(-0.083, strip_y, face_z + 0.003), 0.0095, COL_KNOB_DARK, 0.1, 1.0, 0.05, 0.88, [], interactables)
	_add_rotary_knob_3d(root, "scale_illum", "SCALE ILLUM", Vector3(-0.052, strip_y, face_z + 0.003), 0.0095, COL_KNOB_DARK, 0.0, 1.0, 0.05, 0.65, [], interactables)

	# GND Jack
	_add_label_3d(root, "GND", Vector3(-0.023, strip_y + 0.016, face_z + 0.003), 15, COL_SILKSCREEN)
	var gnd_mat := _mat(Color(0.08, 0.08, 0.08, 1.0), 0.4, 0.2)
	_add_cyl(root, "GNDJack", 0.005, 0.010, Vector3(-0.023, strip_y - 0.001, face_z + 0.005), Vector3(PI * 0.5, 0, 0), gnd_mat)

	# ==================== RIGHT HALF: TRIGGER, TIME/DIV, CH1, CH2 ====================
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
	_add_rotary_knob_3d(root, "probe_compensation", "PROBE COMP", Vector3(0.062, 0.084, face_z + 0.003), 0.0080, COL_KNOB_BEIGE, 0.65, 1.35, 0.05, 0.72, [], interactables)
	_add_rotary_knob_3d(root, "volts_per_div", "VOLTS/DIV", Vector3(0.044, 0.052, face_z + 0.003), 0.014, COL_KNOB_RED, 0.0, 4.0, 1.0, 2.0, ["0.2V", "0.5V", "1V", "2V", "5V"], interactables)

	var ch1_bnc_pos := Vector3(0.022, 0.024, face_z + 0.006)
	_add_bnc_jack(root, "CH1_INPUT_BNC", ch1_bnc_pos, 0.90)
	_add_slide_switch_3d(root, "coupling", "AC-GND-DC", Vector3(0.062, 0.024, face_z + 0.003), ["DC", "AC", "GND"], 0, false, interactables)

	# CENTER MODE SWITCH
	_add_slide_switch_3d(root, "vert_mode", "MODE", Vector3(0.092, 0.065, face_z + 0.003), ["CH1", "ALT", "CH2"], 0, true, interactables)

	# VERTICAL CH 2
	_add_label_3d(root, "CH 2", Vector3(0.138, 0.103, face_z + 0.003), 18, COL_SILKSCREEN)
	_add_rotary_knob_3d(root, "ch2_var", "VARIABLE", Vector3(0.118, 0.084, face_z + 0.003), 0.0080, COL_KNOB_BEIGE, 0.0, 1.0, 0.1, 0.5, [], interactables)
	_add_rotary_knob_3d(root, "ch2_pos", "POSITION", Vector3(0.156, 0.084, face_z + 0.003), 0.0085, COL_KNOB_DARK, -4.0, 4.0, 0.2, 0.0, [], interactables)
	_add_rotary_knob_3d(root, "ch2_volts", "VOLTS/DIV", Vector3(0.138, 0.052, face_z + 0.003), 0.014, COL_KNOB_RED, 0.0, 4.0, 1.0, 2.0, ["0.2V", "0.5V", "1V", "2V", "5V"], interactables)
	_add_bnc_jack(root, "CH2_INPUT_BNC", Vector3(0.156, 0.024, face_z + 0.006), 0.90)
	_add_slide_switch_3d(root, "ch2_coupling", "AC-GND-DC", Vector3(0.118, 0.024, face_z + 0.003), ["DC", "AC", "GND"], 0, false, interactables)

	# ==================== 3D BENCH FUNCTION GENERATOR (RIGHT OF SCOPE) ====================
	var fg := Node3D.new()
	fg.name = "BenchFunctionGenerator"
	fg.position = Vector3(0.24, 0.0, 0.06)
	parent.add_child(fg)

	_add_box(fg, "FGCase", Vector3(0.24, 0.11, 0.24), Vector3(0.0, 0.058, 0.0), _mat(Color(0.22, 0.25, 0.28, 1.0), 0.5, 0.3))
	_add_box(fg, "FGFace", Vector3(0.232, 0.102, 0.004), Vector3(0.0, 0.058, 0.121), _mat(Color(0.82, 0.83, 0.84, 1.0), 0.4, 0.2))
	_add_box(fg, "FGLCD", Vector3(0.13, 0.036, 0.004), Vector3(-0.035, 0.075, 0.123), _mat(Color(0.06, 0.16, 0.14, 1.0), 0.2, 0.0))
	var fg_display_lbl := _add_label_3d(fg, "FG-2000  1000 Hz  4.0 Vpp", Vector3(-0.035, 0.075, 0.126), 18, Color(0.30, 1.0, 0.72))
	_add_label_3d(fg, "FUNCTION GENERATOR", Vector3(-0.035, 0.098, 0.124), 16, COL_SILKSCREEN)

	# Clickable Function Generator OUTPUT 50 Ohm BNC Terminal
	_add_label_3d(fg, "OUTPUT 50Ω", Vector3(0.072, 0.052, 0.124), 15, COL_SILKSCREEN)
	var fg_out_local := Vector3(0.072, 0.032, 0.126)
	_add_interactive_terminal(fg, "fg_terminal", "Function Gen OUTPUT 50Ω (Click to Connect Probe)", fg_out_local, 0.011, interactables)

	# ==================== 3D PASSIVE OSCILLOSCOPE PROBE & CABLE ====================
	var probe_grp := Node3D.new()
	probe_grp.name = "OscilloscopeProbeAssembly"
	parent.add_child(probe_grp)

	# BNC Plug attached to CH1_INPUT_BNC on Scope
	var scope_bnc_world := root.position + ch1_bnc_pos + Vector3(0.0, 0.0, 0.008)
	_add_cyl(probe_grp, "BNCPlugBody", 0.0065, 0.022, scope_bnc_world + Vector3(0, 0, 0.011), Vector3(PI * 0.5, 0, 0), _mat(Color(0.16, 0.16, 0.17, 1.0), 0.5, 0.2))

	# Switchable 1x / 10x Probe Handle Body (Moves dynamically to active target!)
	var probe_tip := Node3D.new()
	probe_tip.name = "ProbeTipHandle"
	probe_grp.add_child(probe_tip)

	var handle_body := _add_cyl(probe_tip, "Grip", 0.0055, 0.068, Vector3(0, 0, 0.038), Vector3(PI * 0.5, 0, 0), _mat(Color(0.18, 0.20, 0.22, 1.0), 0.45, 0.1))
	_add_cyl(probe_tip, "HookTip", 0.0022, 0.016, Vector3(0, 0, 0.004), Vector3(PI * 0.5, 0, 0), _mat(Color(0.92, 0.25, 0.20, 1.0), 0.3, 0.0))
	# Ground Alligator Clip Lead
	_add_cyl(probe_tip, "GndClip", 0.0025, 0.018, Vector3(0.012, -0.008, 0.014), Vector3(PI * 0.4, 0.3, 0), _mat(Color(0.10, 0.10, 0.10, 1.0), 0.5, 0.3))

	# Probe 1x / 10x Slide Switch right on the Probe Handle!
	_add_slide_switch_3d(probe_tip, "probe_attenuation_switch", "PROBE 1x/10x", Vector3(0.0, 0.007, 0.038), ["1x", "10x"], 0, false, interactables)

	# Coaxial Cable Mesh (Updated dynamically when probe moves)
	var cable_mesh := MeshInstance3D.new()
	cable_mesh.name = "ProbeCoaxCable"
	cable_mesh.material_override = _mat(Color(0.12, 0.12, 0.13, 1.0), 0.65, 0.05)
	probe_grp.add_child(cable_mesh)

	var anchors := {
		"scope_bnc": scope_bnc_world + Vector3(0, 0, 0.020),
		"fg_out": fg.position + fg_out_local + Vector3(0, 0, 0.008),
		"cal_hook": root.position + cal_pos + Vector3(0, 0, 0.006),
		"floating": Vector3(0.06, 0.010, 0.28)
	}

	return {
		"root": root,
		"crt_material": crt_mat,
		"power_led_material": led_mat,
		"power_button_mesh": pwr_btn,
		"probe_tip": probe_tip,
		"cable_mesh": cable_mesh,
		"anchors": anchors,
		"fg_display_lbl": fg_display_lbl,
		"interactables": interactables
	}

static func update_probe_placement(scope_data: Dictionary, target_mode: int) -> void:
	if scope_data.is_empty():
		return
	var probe_tip: Node3D = scope_data["probe_tip"]
	var cable_mesh: MeshInstance3D = scope_data["cable_mesh"]
	var anchors: Dictionary = scope_data["anchors"]
	var p_start: Vector3 = anchors["scope_bnc"]
	var p_end: Vector3 = anchors["fg_out"]

	if target_mode == AnalogScopeEngine.ProbeTarget.CAL_1VPP:
		p_end = anchors["cal_hook"]
		probe_tip.position = p_end
		probe_tip.rotation = Vector3(-0.18, 0.25, 0.0)
	elif target_mode == AnalogScopeEngine.ProbeTarget.FLOATING:
		p_end = anchors["floating"]
		probe_tip.position = p_end
		probe_tip.rotation = Vector3(0.0, -0.65, 0.0)
	else:
		p_end = anchors["fg_out"]
		probe_tip.position = p_end
		probe_tip.rotation = Vector3(-0.12, -0.15, 0.0)

	# Build curved multi-segment coaxial cable between scope BNC and probe tail
	var tail_pos := probe_tip.global_position + probe_tip.global_transform.basis.z * 0.072
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var steps := 24
	var radius := 0.0024
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var pt := p_start.lerp(tail_pos, t)
		# Natural gravity droop onto ESD mat
		pt.y = maxf(pt.y - sin(t * PI) * 0.045, 0.004)
		im.surface_add_vertex(pt + Vector3(0, radius, 0))
		im.surface_add_vertex(pt + Vector3(0, -radius, 0))
	im.surface_end()
	cable_mesh.mesh = im

static func _add_interactive_terminal(parent: Node3D, param_id: String, title: String, pos: Vector3, r: float, interactables: Dictionary) -> void:
	_add_bnc_jack(parent, "Term_" + param_id, pos, r / 0.0075)
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, 0, 0.006)
	parent.add_child(body)
	var col := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = r * 1.8
	col.shape = sp
	body.add_child(col)

	interactables[body.get_instance_id()] = {
		"type": "terminal",
		"param_id": param_id,
		"title": title,
		"focus_node": body,
		"ring_radius": r * 1.45
	}

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
	interactables: Dictionary
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

	var body_mat := _mat(COL_KNOB_DARK, 0.55, 0.1)
	_add_cyl(rotor, "Body", radius, 0.012, Vector3(0, 0, 0.006), Vector3(PI * 0.5, 0, 0), body_mat)

	var cap_mat := _mat(cap_color, 0.45, 0.15)
	_add_cyl(rotor, "Cap", radius * 0.62, 0.002, Vector3(0, 0, 0.0125), Vector3(PI * 0.5, 0, 0), cap_mat)

	var ptr_mat := _mat(Color(0.96, 0.95, 0.92, 1.0), 0.3, 0.0)
	_add_box(rotor, "Pointer", Vector3(0.0016, radius * 0.88, 0.0018), Vector3(0.0, radius * 0.44, 0.0132), ptr_mat)

	var norm := clampf((init_v - min_v) / maxf(max_v - min_v, 1e-6), 0.0, 1.0)
	rotor.rotation.z = lerpf(deg_to_rad(135.0), deg_to_rad(-135.0), norm)

	var body := StaticBody3D.new()
	body.name = "Collider_" + param_id
	holder.add_child(body)
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius * 1.45
	col.shape = sphere
	col.position = Vector3(0, 0, 0.008)
	body.add_child(col)

	interactables[body.get_instance_id()] = {
		"type": "knob",
		"param_id": param_id,
		"title": title,
		"rotor": rotor,
		"focus_node": rotor,
		"ring_radius": radius * 1.25,
		"min": min_v,
		"max": max_v,
		"step": step_v,
		"value": init_v,
		"labels": labels
	}
	return rotor

static func _add_slide_switch_3d(
	parent: Node3D,
	param_id: String,
	title: String,
	pos: Vector3,
	options: Array,
	init_idx: int,
	vertical: bool,
	interactables: Dictionary
) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Switch_" + param_id
	holder.position = pos
	parent.add_child(holder)

	_add_label_3d(holder, title, Vector3(0.0, 0.0135 if vertical else 0.0095, 0.001), 14, COL_SILKSCREEN)

	var slot_size := Vector3(0.006, 0.018, 0.002) if vertical else Vector3(0.022, 0.006, 0.002)
	var slot_mat := _mat(Color(0.14, 0.14, 0.14, 1.0), 0.8, 0.1)
	_add_box(holder, "Slot", slot_size, Vector3(0, 0, 0.001), slot_mat)

	var nub_mat := _mat(Color(0.28, 0.27, 0.26, 1.0), 0.4, 0.4)
	var nub := _add_box(holder, "Actuator", Vector3(0.0055, 0.0055, 0.0075), Vector3(0, 0, 0.004), nub_mat)

	var body := StaticBody3D.new()
	holder.add_child(body)
	var col := CollisionShape3D.new()
	var box_s := BoxShape3D.new()
	box_s.size = Vector3(0.018, 0.026, 0.016) if vertical else Vector3(0.030, 0.018, 0.016)
	col.shape = box_s
	col.position = Vector3(0, 0, 0.004)
	body.add_child(col)

	var meta := {
		"type": "switch",
		"param_id": param_id,
		"title": title,
		"actuator": nub,
		"focus_node": nub,
		"ring_radius": 0.011,
		"options": options,
		"index": init_idx,
		"vertical": vertical
	}
	update_switch_visual(meta)
	interactables[body.get_instance_id()] = meta
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

static func _add_push_button(parent: Node3D, param_id: String, title: String, pos: Vector3, interactables: Dictionary) -> MeshInstance3D:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)

	var btn_mat := _mat(Color(0.18, 0.17, 0.17, 1.0), 0.45, 0.2)
	var cap := _add_box(holder, "ButtonCap", Vector3(0.009, 0.009, 0.008), Vector3(0, 0, 0.003), btn_mat)

	var body := StaticBody3D.new()
	holder.add_child(body)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.018, 0.018, 0.016)
	col.shape = bs
	col.position = Vector3(0, 0, 0.004)
	body.add_child(col)

	interactables[body.get_instance_id()] = {
		"type": "button",
		"param_id": param_id,
		"title": title,
		"cap": cap,
		"focus_node": cap,
		"ring_radius": 0.009
	}
	return cap

static func _add_bnc_jack(parent: Node3D, jack_name: String, pos: Vector3, scale_f := 1.0) -> void:
	var holder := Node3D.new()
	holder.name = jack_name
	holder.position = pos
	parent.add_child(holder)

	var metal_mat := _mat(COL_METAL_BNC, 0.25, 0.85)
	var insulator_mat := _mat(Color(0.92, 0.92, 0.90, 1.0), 0.35, 0.0)
	_add_cyl(holder, "Flange", 0.0075 * scale_f, 0.003 * scale_f, Vector3(0, 0, 0.0015), Vector3(PI * 0.5, 0, 0), metal_mat)
	_add_cyl(holder, "Barrel", 0.0052 * scale_f, 0.012 * scale_f, Vector3(0, 0, 0.007 * scale_f), Vector3(PI * 0.5, 0, 0), metal_mat)
	_add_cyl(holder, "Dielectric", 0.0032 * scale_f, 0.0125 * scale_f, Vector3(0, 0, 0.0072 * scale_f), Vector3(PI * 0.5, 0, 0), insulator_mat)

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
