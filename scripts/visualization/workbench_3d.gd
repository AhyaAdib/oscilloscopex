class_name Workbench3D
extends SubViewportContainer

const VOLTS_STEPS := [0.2, 0.5, 1.0, 2.0, 5.0]
const TIME_STEPS := [0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005]

const CAMERA_PRESETS := [
	{"name": "1: Full Workbench", "pos": Vector3(0.04, 0.27, 0.58), "target": Vector3(0.02, 0.09, 0.14)},
	{"name": "2: Scope Knobs", "pos": Vector3(-0.04, 0.14, 0.38), "target": Vector3(-0.05, 0.10, 0.18)},
	{"name": "3: CRT + CAL Hook", "pos": Vector3(-0.23, 0.13, 0.36), "target": Vector3(-0.23, 0.10, 0.18)},
	{"name": "4: Func Gen + Probe", "pos": Vector3(0.24, 0.15, 0.36), "target": Vector3(0.24, 0.06, 0.16)}
]

var _main_vp: SubViewport
var _crt_vp: SubViewport
var _camera: Camera3D
var _scope_data := {}
var _hover_ring: MeshInstance3D

var _hovered_ctrl := {}
var _active_knob := {}
var _drag_start_y := 0.0
var _drag_start_val := 0.0

var _orbiting := false
var _yaw := 0.0
var _pitch := -0.22
var _dist := 0.48
var _cam_target := Vector3(0.02, 0.09, 0.14)

var _hud_label: Label
var _probe_btn_fg: Button
var _probe_btn_cal: Button
var _probe_btn_float: Button

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_3d_scene()
	_build_overlay_hud()
	if has_node("/root/SimState"):
		SimState.state_updated.connect(_sync_visuals)
	_sync_visuals()

func _build_3d_scene() -> void:
	_crt_vp = SubViewport.new()
	_crt_vp.size = Vector2i(640, 460)
	_crt_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_crt_vp)

	var crt_canvas := WaveformCanvas.new()
	crt_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_crt_vp.add_child(crt_canvas)

	_main_vp = SubViewport.new()
	_main_vp.size = Vector2i(1200, 620)
	_main_vp.own_world_3d = true
	_main_vp.physics_object_picking = true
	_main_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_main_vp)

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.10, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.60, 0.63, 0.67, 1.0)
	env.ambient_light_energy = 0.90
	world_env.environment = env
	_main_vp.add_child(world_env)

	var key_light := DirectionalLight3D.new()
	key_light.look_at_from_position(Vector3(0.4, 0.9, 0.85), Vector3(0.0, 0.1, 0.15), Vector3.UP)
	key_light.light_energy = 1.15
	_main_vp.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-0.35, 0.35, 0.55)
	fill_light.light_energy = 0.70
	fill_light.omni_range = 2.5
	_main_vp.add_child(fill_light)

	# Workbench Desk + Blue ESD Anti-Static Mat
	var desk_mesh := MeshInstance3D.new()
	var desk_box := BoxMesh.new()
	desk_box.size = Vector3(1.50, 0.04, 0.95)
	desk_mesh.mesh = desk_box
	desk_mesh.position = Vector3(0.0, -0.02, 0.05)
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.22, 0.20, 0.18, 1.0)
	desk_mat.roughness = 0.75
	desk_mesh.material_override = desk_mat
	_main_vp.add_child(desk_mesh)

	var esd_mesh := MeshInstance3D.new()
	var esd_box := BoxMesh.new()
	esd_box.size = Vector3(1.05, 0.003, 0.65)
	esd_mesh.mesh = esd_box
	esd_mesh.position = Vector3(0.02, 0.0015, 0.10)
	var esd_mat := StandardMaterial3D.new()
	esd_mat.albedo_color = Color(0.11, 0.24, 0.32, 1.0)
	esd_mat.roughness = 0.65
	esd_mesh.material_override = esd_mat
	_main_vp.add_child(esd_mesh)

	# Build VP-5231A + Bench Function Generator + Coaxial Probe
	_scope_data = VP5231A3DBuilder.build_oscilloscope(_main_vp, _crt_vp.get_texture())

	# Glowing Blue 3D Hover Selection Ring (TorusMesh)
	_hover_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	_hover_ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.20, 0.72, 1.0, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.22, 0.78, 1.0, 1.0)
	ring_mat.emission_energy_multiplier = 2.4
	ring_mat.no_depth_test = true
	_hover_ring.material_override = ring_mat
	_hover_ring.rotation.x = PI * 0.5
	_hover_ring.visible = false
	_main_vp.add_child(_hover_ring)

	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.near = 0.02
	_camera.far = 10.0
	_main_vp.add_child(_camera)
	_apply_camera_preset(0)

func _build_overlay_hud() -> void:
	var top_overlay := MarginContainer.new()
	top_overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_overlay.add_theme_constant_override("margin_left", 14)
	top_overlay.add_theme_constant_override("margin_right", 14)
	top_overlay.add_theme_constant_override("margin_top", 8)
	top_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_overlay)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_overlay.add_child(vbox)

	# Row 1: Hover Status + Camera Presets
	var row1 := HBoxContainer.new()
	row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(row1)

	_hud_label = Label.new()
	_hud_label.text = "3D BENCH: Hover any knob/switch/terminal (blue ring) | Left-Drag / Wheel to adjust | Right-Drag to orbit"
	_hud_label.add_theme_font_size_override("font_size", 13)
	_hud_label.add_theme_color_override("font_color", Color(0.45, 0.96, 0.78, 1.0))
	_hud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(_hud_label)

	var preset_bar := HBoxContainer.new()
	preset_bar.add_theme_constant_override("separation", 6)
	row1.add_child(preset_bar)

	for i in range(CAMERA_PRESETS.size()):
		var btn := Button.new()
		btn.text = CAMERA_PRESETS[i]["name"]
		var idx := i
		btn.pressed.connect(func() -> void: _apply_camera_preset(idx))
		preset_bar.add_child(btn)

	# Row 2: Probe Connection & Calibration Quick Actions
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(row2)

	var probe_lbl := Label.new()
	probe_lbl.text = "CH 1 PROBE CONNECTION:"
	probe_lbl.add_theme_font_size_override("font_size", 12)
	probe_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95, 1.0))
	row2.add_child(probe_lbl)

	_probe_btn_fg = Button.new()
	_probe_btn_fg.text = "1. Clip to Func Gen OUT"
	_probe_btn_fg.toggle_mode = true
	_probe_btn_fg.pressed.connect(func() -> void: SimState.set_analog_param("probe_target", AnalogScopeEngine.ProbeTarget.FUNC_GEN))
	row2.add_child(_probe_btn_fg)

	_probe_btn_cal = Button.new()
	_probe_btn_cal.text = "2. Clip to Scope CAL (1 Vp-p)"
	_probe_btn_cal.toggle_mode = true
	_probe_btn_cal.pressed.connect(func() -> void: SimState.set_analog_param("probe_target", AnalogScopeEngine.ProbeTarget.CAL_1VPP))
	row2.add_child(_probe_btn_cal)

	_probe_btn_float = Button.new()
	_probe_btn_float.text = "3. Disconnect (Floating)"
	_probe_btn_float.toggle_mode = true
	_probe_btn_float.pressed.connect(func() -> void: SimState.set_analog_param("probe_target", AnalogScopeEngine.ProbeTarget.FLOATING))
	row2.add_child(_probe_btn_float)

func _apply_camera_preset(idx: int) -> void:
	var preset: Dictionary = CAMERA_PRESETS[clampi(idx, 0, CAMERA_PRESETS.size() - 1)]
	var p: Vector3 = preset["pos"]
	var t: Vector3 = preset["target"]
	_cam_target = t
	var offset := p - t
	_dist = offset.length()
	_yaw = atan2(offset.x, offset.z)
	_pitch = clampf(asin(-offset.y / maxf(_dist, 1e-4)), -1.2, 0.1)
	_update_camera_transform()

func _update_camera_transform() -> void:
	if _camera == null:
		return
	var dir := Vector3(
		sin(_yaw) * cos(_pitch),
		-sin(_pitch),
		cos(_yaw) * cos(_pitch)
	)
	_camera.look_at_from_position(_cam_target + dir * _dist, _cam_target, Vector3.UP)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _camera == null:
		return
	var local_pos := get_local_mouse_position()
	var rect := Rect2(Vector2.ZERO, size)
	if not rect.has_point(local_pos) and _active_knob.is_empty() and not _orbiting:
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if not _active_knob.is_empty():
			var dy := _drag_start_y - local_pos.y
			var span: float = maxf(float(_active_knob["max"]) - float(_active_knob["min"]), 1e-6)
			_set_knob_3d_value(_active_knob, _drag_start_val + (dy / 100.0) * span)
			get_viewport().set_input_as_handled()
			return
		if _orbiting:
			_yaw = clampf(_yaw - mm.relative.x * 0.007, -1.35, 1.35)
			_pitch = clampf(_pitch - mm.relative.y * 0.007, -1.15, 0.05)
			_update_camera_transform()
			get_viewport().set_input_as_handled()
			return
		_raycast_hover(local_pos)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mb.pressed
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			if not _hovered_ctrl.is_empty() and _hovered_ctrl["type"] == "knob":
				_set_knob_3d_value(_hovered_ctrl, float(_hovered_ctrl["value"]) + float(_hovered_ctrl["step"]))
			else:
				_dist = clampf(_dist - 0.035, 0.20, 0.95)
				_update_camera_transform()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			if not _hovered_ctrl.is_empty() and _hovered_ctrl["type"] == "knob":
				_set_knob_3d_value(_hovered_ctrl, float(_hovered_ctrl["value"]) - float(_hovered_ctrl["step"]))
			else:
				_dist = clampf(_dist + 0.035, 0.20, 0.95)
				_update_camera_transform()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_raycast_hover(local_pos)
				if not _hovered_ctrl.is_empty():
					var t: String = _hovered_ctrl["type"]
					if t == "knob":
						_active_knob = _hovered_ctrl
						_drag_start_y = local_pos.y
						_drag_start_val = float(_active_knob["value"])
					elif t == "switch":
						_cycle_switch_3d(_hovered_ctrl)
					elif t == "button":
						_toggle_button_3d(_hovered_ctrl)
					elif t == "terminal":
						_connect_terminal_3d(_hovered_ctrl)
					get_viewport().set_input_as_handled()
			else:
				_active_knob = {}

func _raycast_hover(screen_pos: Vector2) -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var w3d := _main_vp.get_world_3d()
	if w3d == null or w3d.direct_space_state == null:
		return
	# Scale screen_pos from SubViewportContainer size to SubViewport resolution
	var vp_pos := Vector2(
		screen_pos.x * (float(_main_vp.size.x) / size.x),
		screen_pos.y * (float(_main_vp.size.y) / size.y)
	)
	var from := _camera.project_ray_origin(vp_pos)
	var to := from + _camera.project_ray_normal(vp_pos) * 3.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit := w3d.direct_space_state.intersect_ray(query)
	var interactables: Dictionary = _scope_data.get("interactables", {})

	if not hit.is_empty() and hit.has("collider_id") and interactables.has(hit["collider_id"]):
		_hovered_ctrl = interactables[hit["collider_id"]]
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_update_hover_ring(_hovered_ctrl)
		_update_hover_hud(_hovered_ctrl)
	else:
		_hovered_ctrl = {}
		_hover_ring.visible = false
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		_hud_label.text = "3D BENCH: Hover any knob/switch/terminal (blue ring) | Left-Drag / Wheel to adjust | Right-Drag to orbit"

func _update_hover_ring(ctrl: Dictionary) -> void:
	var focus_node: Node3D = ctrl.get("focus_node")
	if focus_node == null:
		_hover_ring.visible = false
		return
	var r: float = float(ctrl.get("ring_radius", 0.012))
	_hover_ring.visible = true
	_hover_ring.global_position = focus_node.global_position + Vector3(0.0, 0.0, 0.008)
	_hover_ring.scale = Vector3(r, r, r)

func _update_hover_hud(ctrl: Dictionary) -> void:
	var t: String = ctrl["type"]
	if t == "knob":
		var labels: Array = ctrl["labels"]
		var val_str := "%.2f" % float(ctrl["value"])
		if labels.size() > 0:
			var idx := clampi(int(round(float(ctrl["value"]))), 0, labels.size() - 1)
			val_str = str(labels[idx])
		_hud_label.text = "[SELECTED KNOB] %s = %s  —  Drag Up/Down or Scroll Wheel to Turn" % [ctrl["title"], val_str]
	elif t == "switch":
		var opts: Array = ctrl["options"]
		_hud_label.text = "[SELECTED SWITCH] %s = %s  —  Left-Click to Toggle" % [ctrl["title"], str(opts[int(ctrl["index"])])]
	elif t == "button":
		var p_state := "ON" if SimState.view_config.get("power_on", true) else "OFF"
		_hud_label.text = "[SELECTED BUTTON] %s = %s  —  Left-Click to Toggle" % [ctrl["title"], p_state]
	elif t == "terminal":
		_hud_label.text = "[TERMINAL] %s" % ctrl["title"]

func _set_knob_3d_value(ctrl: Dictionary, raw_val: float) -> void:
	var min_v: float = float(ctrl["min"])
	var max_v: float = float(ctrl["max"])
	var step_v: float = float(ctrl["step"])
	var snapped_v := snappedf(clampf(raw_val, min_v, max_v), step_v)
	ctrl["value"] = snapped_v

	var norm := clampf((snapped_v - min_v) / maxf(max_v - min_v, 1e-6), 0.0, 1.0)
	var rotor: Node3D = ctrl["rotor"]
	rotor.rotation.z = lerpf(deg_to_rad(135.0), deg_to_rad(-135.0), norm)
	_update_hover_hud(ctrl)

	var pid: String = ctrl["param_id"]
	match pid:
		"intensity", "focus", "scale_illum", "trigger_level", "horiz_pos_div", "vert_pos_div", "probe_compensation":
			SimState.set_analog_param(pid, snapped_v)
		"volts_per_div":
			var idx := clampi(int(round(snapped_v)), 0, VOLTS_STEPS.size() - 1)
			SimState.set_view_param("volts_per_div", VOLTS_STEPS[idx])
		"time_per_div":
			var idx := clampi(int(round(snapped_v)), 0, TIME_STEPS.size() - 1)
			SimState.set_view_param("time_per_div", TIME_STEPS[idx])

func _cycle_switch_3d(ctrl: Dictionary) -> void:
	var opts: Array = ctrl["options"]
	var next_idx := (int(ctrl["index"]) + 1) % opts.size()
	ctrl["index"] = next_idx
	VP5231A3DBuilder.update_switch_visual(ctrl)
	_update_hover_hud(ctrl)

	var pid: String = ctrl["param_id"]
	match pid:
		"coupling":
			SimState.set_analog_param("coupling", next_idx)
		"trigger_slope":
			SimState.set_analog_param("trigger_slope", next_idx)
		"persist_toggle":
			var p_vals := [0.0, 0.35, 0.85]
			SimState.set_analog_param("persistence", p_vals[next_idx])
		"probe_attenuation_switch":
			SimState.set_analog_param("probe_attenuation", 10.0 if next_idx == 1 else 1.0)

func _toggle_button_3d(ctrl: Dictionary) -> void:
	if ctrl["param_id"] == "power_on":
		var next_on := not bool(SimState.view_config.get("power_on", true))
		SimState.set_view_param("power_on", next_on)
		_update_hover_hud(ctrl)

func _connect_terminal_3d(ctrl: Dictionary) -> void:
	var pid: String = ctrl["param_id"]
	if pid == "cal_terminal":
		SimState.set_analog_param("probe_target", AnalogScopeEngine.ProbeTarget.CAL_1VPP)
	elif pid == "fg_terminal":
		SimState.set_analog_param("probe_target", AnalogScopeEngine.ProbeTarget.FUNC_GEN)

func _sync_visuals() -> void:
	if _scope_data.is_empty() or not has_node("/root/SimState"):
		return
	var is_on := bool(SimState.view_config.get("power_on", true))
	var crt_mat: StandardMaterial3D = _scope_data["crt_material"]
	var led_mat: StandardMaterial3D = _scope_data["power_led_material"]
	var cap: Node3D = _scope_data["power_button_mesh"]

	crt_mat.emission_enabled = is_on
	led_mat.emission_enabled = is_on
	led_mat.albedo_color = Color(1.0, 0.58, 0.10, 1.0) if is_on else Color(0.28, 0.20, 0.15, 1.0)
	cap.position.z = 0.0015 if is_on else 0.0035

	var target: int = int(SimState.analog_config.get("probe_target", AnalogScopeEngine.ProbeTarget.FUNC_GEN))
	VP5231A3DBuilder.update_probe_placement(_scope_data, target)

	if _probe_btn_fg != null:
		_probe_btn_fg.button_pressed = (target == AnalogScopeEngine.ProbeTarget.FUNC_GEN)
		_probe_btn_cal.button_pressed = (target == AnalogScopeEngine.ProbeTarget.CAL_1VPP)
		_probe_btn_float.button_pressed = (target == AnalogScopeEngine.ProbeTarget.FLOATING)

	var fg_lbl: Label3D = _scope_data.get("fg_display_lbl")
	if fg_lbl != null:
		var freq: float = SimState.signal_params["frequency"]
		var vpp: float = SimState.signal_params["amplitude"] * 2.0
		fg_lbl.text = "FG-2000  %.0f Hz  %.1f Vpp" % [freq, vpp]
