class_name Workbench3D
extends SubViewportContainer

const VOLTS_STEPS := [0.2, 0.5, 1.0, 2.0, 5.0]
const TIME_STEPS := [0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005]

const CAMERA_PRESETS := [
	{"name": "1: Full Bench", "pos": Vector3(0.03, 0.25, 0.62), "target": Vector3(0.02, 0.09, 0.14)},
	{"name": "2: Scope Knobs", "pos": Vector3(-0.07, 0.14, 0.39), "target": Vector3(-0.08, 0.10, 0.18)},
	{"name": "3: CRT + CAL Hook", "pos": Vector3(-0.26, 0.13, 0.37), "target": Vector3(-0.26, 0.10, 0.18)},
	{"name": "4: Siglent Gen", "pos": Vector3(0.24, 0.14, 0.38), "target": Vector3(0.24, 0.06, 0.14)}
]

var _main_vp: SubViewport
var _crt_vp: SubViewport
var _camera: Camera3D
var _scope_data := {}
var _hover_ring: MeshInstance3D

var _hovered_ctrl := {}
var _active_knob := {}
var _dragging_probe_kind := "" # "bnc" or "tip"
var _dragging_probe_idx := 1
var _drag_start_y := 0.0
var _drag_start_val := 0.0

var _orbiting := false
var _yaw := 0.0
var _pitch := -0.22
var _dist := 0.50
var _cam_target := Vector3(0.02, 0.09, 0.14)

var _hud_label: Label
var _checklist_panel: PanelContainer
var _checklist_lbl: Label

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
	_main_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_main_vp)

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.10, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.69, 1.0)
	env.ambient_light_energy = 0.95
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
	desk_box.size = Vector3(1.55, 0.04, 0.95)
	desk_mesh.mesh = desk_box
	desk_mesh.position = Vector3(0.0, -0.02, 0.05)
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.22, 0.20, 0.18, 1.0)
	desk_mat.roughness = 0.75
	desk_mesh.material_override = desk_mat
	_main_vp.add_child(desk_mesh)

	var esd_mesh := MeshInstance3D.new()
	var esd_box := BoxMesh.new()
	esd_box.size = Vector3(1.10, 0.003, 0.65)
	esd_mesh.mesh = esd_box
	esd_mesh.position = Vector3(0.02, 0.0015, 0.10)
	var esd_mat := StandardMaterial3D.new()
	esd_mat.albedo_color = Color(0.11, 0.24, 0.32, 1.0)
	esd_mat.roughness = 0.65
	esd_mesh.material_override = esd_mat
	_main_vp.add_child(esd_mesh)

	_scope_data = VP5231A3DBuilder.build_oscilloscope(_main_vp, _crt_vp.get_texture())

	# Glowing Cyan-Blue 3D Hover Selection Ring
	_hover_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.80
	torus.outer_radius = 1.0
	_hover_ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.22, 0.78, 1.0, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.25, 0.82, 1.0, 1.0)
	ring_mat.emission_energy_multiplier = 2.8
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

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hbox)

	_hud_label = Label.new()
	_hud_label.text = "3D BENCH: Hover knob/switch/probe (blue ring) | Drag/Wheel to turn | Drag Probe Tip or BNC to plug"
	_hud_label.add_theme_font_size_override("font_size", 13)
	_hud_label.add_theme_color_override("font_color", Color(0.45, 0.96, 0.78, 1.0))
	_hud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_hud_label)

	var preset_bar := HBoxContainer.new()
	preset_bar.add_theme_constant_override("separation", 6)
	hbox.add_child(preset_bar)

	for i in range(CAMERA_PRESETS.size()):
		var btn := Button.new()
		btn.text = CAMERA_PRESETS[i]["name"]
		var idx := i
		btn.pressed.connect(func() -> void: _apply_camera_preset(idx))
		preset_bar.add_child(btn)

	# Calibration Lab Practicum Checklist Panel (visible in Calibration Lab Mode)
	_checklist_panel = PanelContainer.new()
	_checklist_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_checklist_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.12, 0.88)
	sb.border_color = Color(1.0, 0.76, 0.25, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	_checklist_panel.add_theme_stylebox_override("panel", sb)
	vbox.add_child(_checklist_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_checklist_panel.add_child(margin)

	_checklist_lbl = Label.new()
	_checklist_lbl.add_theme_font_size_override("font_size", 12)
	_checklist_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82, 1.0))
	margin.add_child(_checklist_lbl)

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

func _screen_to_vp_ray(local_pos: Vector2) -> Dictionary:
	var vp_pos := Vector2(
		local_pos.x * (float(_main_vp.size.x) / maxf(size.x, 1.0)),
		local_pos.y * (float(_main_vp.size.y) / maxf(size.y, 1.0))
	)
	return {
		"origin": _camera.project_ray_origin(vp_pos),
		"dir": _camera.project_ray_normal(vp_pos)
	}

func _ray_sphere_dist(ray_origin: Vector3, ray_dir: Vector3, center: Vector3, radius: float) -> float:
	var oc := ray_origin - center
	var b := oc.dot(ray_dir)
	var c := oc.dot(oc) - radius * radius
	var disc := b * b - c
	if disc < 0.0:
		return -1.0
	var t := -b - sqrt(disc)
	return t if t >= 0.0 else (-b + sqrt(disc))

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _camera == null:
		return
	var local_pos := get_local_mouse_position()
	var rect := Rect2(Vector2.ZERO, size)
	if not rect.has_point(local_pos) and _active_knob.is_empty() and _dragging_probe_kind == "" and not _orbiting:
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if not _active_knob.is_empty():
			var dy := _drag_start_y - local_pos.y
			var span: float = maxf(float(_active_knob["max"]) - float(_active_knob["min"]), 1e-6)
			_set_knob_3d_value(_active_knob, _drag_start_val + (dy / 95.0) * span)
			get_viewport().set_input_as_handled()
			return

		if _dragging_probe_kind != "":
			_handle_probe_drag(local_pos)
			get_viewport().set_input_as_handled()
			return

		if _orbiting:
			_yaw = clampf(_yaw - mm.relative.x * 0.007, -1.35, 1.35)
			_pitch = clampf(_pitch - mm.relative.y * 0.007, -1.15, 0.05)
			_update_camera_transform()
			get_viewport().set_input_as_handled()
			return

		_pick_hovered_control(local_pos)

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
				_pick_hovered_control(local_pos)
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
					elif t == "draggable_tip":
						_dragging_probe_kind = "tip"
						_dragging_probe_idx = int(_hovered_ctrl["probe_idx"])
					elif t == "draggable_bnc":
						_dragging_probe_kind = "bnc"
						_dragging_probe_idx = int(_hovered_ctrl["probe_idx"])
					get_viewport().set_input_as_handled()
			else:
				if _dragging_probe_kind != "":
					_finish_probe_drop(local_pos)
					_dragging_probe_kind = ""
					get_viewport().set_input_as_handled()
				_active_knob = {}

func _pick_hovered_control(local_pos: Vector2) -> void:
	var ray := _screen_to_vp_ray(local_pos)
	var origin: Vector3 = ray["origin"]
	var dir: Vector3 = ray["dir"]
	var items: Array = _scope_data.get("interactables", [])

	var best_t := 1e9
	var best_ctrl := {}
	for ctrl in items:
		var node: Node3D = ctrl.get("focus_node")
		if node == null:
			continue
		var r: float = float(ctrl.get("hit_radius", 0.014))
		var t := _ray_sphere_dist(origin, dir, node.global_position, r)
		if t > 0.0 and t < best_t:
			best_t = t
			best_ctrl = ctrl

	if not best_ctrl.is_empty():
		_hovered_ctrl = best_ctrl
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_update_hover_ring(_hovered_ctrl)
		_update_hover_hud(_hovered_ctrl)
	else:
		_hovered_ctrl = {}
		_hover_ring.visible = false
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		var p1_b := str(SimState.analog_config.get("probe1_bnc", "CH1"))
		var p1_t := str(SimState.analog_config.get("probe1_tip", "FG_CH1"))
		var p2_b := str(SimState.analog_config.get("probe2_bnc", "CH2"))
		var p2_t := str(SimState.analog_config.get("probe2_tip", "FG_CH2"))
		_hud_label.text = "P1[%s→%s]  P2[%s→%s]  |  Hover knob/switch/probe (blue ring) | Drag Probe Tip or BNC to plug" % [p1_b, p1_t, p2_b, p2_t]

func _handle_probe_drag(local_pos: Vector2) -> void:
	var ray := _screen_to_vp_ray(local_pos)
	var origin: Vector3 = ray["origin"]
	var dir: Vector3 = ray["dir"]

	var plane_z := 0.21
	var t_plane := (plane_z - origin.z) / (dir.z if absf(dir.z) > 1e-4 else -1e-4)
	var world_pt := origin + dir * clampf(t_plane, 0.1, 1.5)
	world_pt.y = maxf(world_pt.y, 0.012)

	var snaps: Dictionary = _scope_data.get("snap_targets", {})
	var nearest_key := ""
	var nearest_dist := 0.055
	for key in snaps.keys():
		var info: Dictionary = snaps[key]
		if info["kind"] != _dragging_probe_kind:
			continue
		var target_node: Node3D = info["node"]
		var d := world_pt.distance_to(target_node.global_position + info["offset"])
		if d < nearest_dist:
			nearest_dist = d
			nearest_key = key

	var p_key := "probe1" if _dragging_probe_idx == 1 else "probe2"
	var p_data: Dictionary = _scope_data[p_key]
	var cur_bnc := str(SimState.analog_config.get(p_key + "_bnc", "UNPLUGGED"))
	var cur_tip := str(SimState.analog_config.get(p_key + "_tip", "FLOATING"))

	if nearest_key != "":
		var info: Dictionary = snaps[nearest_key]
		var target_node: Node3D = info["node"]
		_hover_ring.visible = true
		_hover_ring.global_position = target_node.global_position + Vector3(0, 0, 0.010)
		_hover_ring.scale = Vector3(0.017, 0.017, 0.017)
		_hud_label.text = "[RELEASE TO PLUG PROBE %d INTO] %s" % [_dragging_probe_idx, info["label"]]
		VP5231A3DBuilder.update_single_probe(p_data, snaps, cur_bnc, cur_tip, _dragging_probe_kind, target_node.global_position + info["offset"])
	else:
		_hover_ring.visible = false
		_hud_label.text = "Dragging Probe %d %s — Drop onto any glowing BNC/CAL terminal (or drop on mat to unplug)" % [_dragging_probe_idx, _dragging_probe_kind.to_upper()]
		VP5231A3DBuilder.update_single_probe(p_data, snaps, cur_bnc, cur_tip, _dragging_probe_kind, world_pt)

func _finish_probe_drop(local_pos: Vector2) -> void:
	var ray := _screen_to_vp_ray(local_pos)
	var origin: Vector3 = ray["origin"]
	var dir: Vector3 = ray["dir"]
	var plane_z := 0.21
	var t_plane := (plane_z - origin.z) / (dir.z if absf(dir.z) > 1e-4 else -1e-4)
	var world_pt := origin + dir * clampf(t_plane, 0.1, 1.5)
	world_pt.y = maxf(world_pt.y, 0.012)

	var snaps: Dictionary = _scope_data.get("snap_targets", {})
	var nearest_key := ""
	var nearest_dist := 0.055
	for key in snaps.keys():
		var info: Dictionary = snaps[key]
		if info["kind"] != _dragging_probe_kind:
			continue
		var target_node: Node3D = info["node"]
		var d := world_pt.distance_to(target_node.global_position + info["offset"])
		if d < nearest_dist:
			nearest_dist = d
			nearest_key = key

	_hover_ring.visible = false
	var prefix := "probe1_" if _dragging_probe_idx == 1 else "probe2_"
	if _dragging_probe_kind == "bnc":
		SimState.set_analog_param(prefix + "bnc", nearest_key if nearest_key != "" else "UNPLUGGED")
	elif _dragging_probe_kind == "tip":
		SimState.set_analog_param(prefix + "tip", nearest_key if nearest_key != "" else "FLOATING")

func _update_hover_ring(ctrl: Dictionary) -> void:
	var focus_node: Node3D = ctrl.get("focus_node")
	if focus_node == null:
		_hover_ring.visible = false
		return
	var r: float = float(ctrl.get("ring_radius", 0.014))
	_hover_ring.visible = true
	_hover_ring.global_position = focus_node.global_position + Vector3(0.0, 0.0, 0.010)
	_hover_ring.scale = Vector3(r, r, r)

func _update_hover_hud(ctrl: Dictionary) -> void:
	var t: String = ctrl["type"]
	if t == "knob":
		var labels: Array = ctrl["labels"]
		var val_str := "%.2f" % float(ctrl["value"])
		if labels.size() > 0:
			var idx := clampi(int(round(float(ctrl["value"]))), 0, labels.size() - 1)
			val_str = str(labels[idx])
		_hud_label.text = "[KNOB] %s = %s  —  Left-Drag Up/Down or Scroll Wheel to Turn" % [ctrl["title"], val_str]
	elif t == "switch":
		var opts: Array = ctrl["options"]
		_hud_label.text = "[SWITCH] %s = %s  —  Left-Click to Toggle" % [ctrl["title"], str(opts[int(ctrl["index"])])]
	elif t == "button":
		_hud_label.text = "[BUTTON] %s  —  Left-Click to Press" % ctrl["title"]
	elif t == "draggable_tip" or t == "draggable_bnc":
		_hud_label.text = "[DRAGGABLE] %s" % ctrl["title"]

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
		"ch2_pos":
			SimState.set_analog_param("ch2_vert_pos_div", snapped_v)
		"volts_per_div":
			var idx := clampi(int(round(snapped_v)), 0, VOLTS_STEPS.size() - 1)
			SimState.set_view_param("volts_per_div", VOLTS_STEPS[idx])
		"ch2_volts":
			var idx := clampi(int(round(snapped_v)), 0, VOLTS_STEPS.size() - 1)
			SimState.set_view_param("ch2_volts_per_div", VOLTS_STEPS[idx])
		"time_per_div":
			var idx := clampi(int(round(snapped_v)), 0, TIME_STEPS.size() - 1)
			SimState.set_view_param("time_per_div", TIME_STEPS[idx])
		"fg_frequency":
			SimState.set_signal_param("frequency", snapped_v)
		"fg_amplitude":
			SimState.set_signal_param("amplitude", snapped_v)
		"fg_offset":
			SimState.set_signal_param("dc_offset", snapped_v)

func _cycle_switch_3d(ctrl: Dictionary) -> void:
	var opts: Array = ctrl["options"]
	var next_idx := (int(ctrl["index"]) + 1) % opts.size()
	ctrl["index"] = next_idx
	VP5231A3DBuilder.update_switch_visual(ctrl)
	_update_hover_hud(ctrl)

	var pid: String = ctrl["param_id"]
	match pid:
		"vert_mode":
			SimState.set_analog_param("vert_mode", next_idx)
		"coupling":
			SimState.set_analog_param("coupling", next_idx)
		"ch2_coupling":
			SimState.set_analog_param("ch2_coupling", next_idx)
		"trigger_slope":
			SimState.set_analog_param("trigger_slope", next_idx)
		"persist_toggle":
			var p_vals := [0.0, 0.35, 0.85]
			SimState.set_analog_param("persistence", p_vals[next_idx])
		"probe_attenuation_switch":
			SimState.set_analog_param("probe_attenuation", 10.0 if next_idx == 1 else 1.0)

func _toggle_button_3d(ctrl: Dictionary) -> void:
	var pid: String = ctrl["param_id"]
	if pid == "power_on":
		var next_on := not bool(SimState.view_config.get("power_on", true))
		SimState.set_view_param("power_on", next_on)
		_update_hover_hud(ctrl)
	elif pid == "fg_waveform":
		var next_wf := (int(SimState.signal_params["waveform"]) + 1) % SignalGenerator.WAVEFORM_NAMES.size()
		SimState.set_signal_param("waveform", next_wf)
		_update_hover_hud(ctrl)
	elif pid == "fg_sel_ch1":
		SimState.select_fg_channel(1)
		_update_hover_hud(ctrl)
	elif pid == "fg_sel_ch2":
		SimState.select_fg_channel(2)
		_update_hover_hud(ctrl)

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

	var snaps: Dictionary = _scope_data["snap_targets"]
	VP5231A3DBuilder.update_single_probe(
		_scope_data["probe1"], snaps,
		str(SimState.analog_config.get("probe1_bnc", "CH1")),
		str(SimState.analog_config.get("probe1_tip", "FG_CH1"))
	)
	VP5231A3DBuilder.update_single_probe(
		_scope_data["probe2"], snaps,
		str(SimState.analog_config.get("probe2_bnc", "CH2")),
		str(SimState.analog_config.get("probe2_tip", "FG_CH2"))
	)

	# Sync 3D rotor angles & switch positions when changed from 2D panel or Lab Mode reset
	for ctrl in _scope_data.get("interactables", []):
		var pid: String = ctrl.get("param_id", "")
		if ctrl["type"] == "knob":
			var target_v := float(ctrl["value"])
			if SimState.analog_config.has(pid):
				target_v = float(SimState.analog_config[pid])
			elif pid == "volts_per_div":
				var v_cur := float(SimState.view_config["volts_per_div"])
				for i in range(VOLTS_STEPS.size()):
					if absf(VOLTS_STEPS[i] - v_cur) < 1e-4:
						target_v = float(i)
			elif pid == "time_per_div":
				var t_cur := float(SimState.view_config["time_per_div"])
				for i in range(TIME_STEPS.size()):
					if absf(TIME_STEPS[i] - t_cur) < 1e-6:
						target_v = float(i)
			elif pid == "fg_frequency":
				target_v = float(SimState.signal_params["frequency"])
			elif pid == "fg_amplitude":
				target_v = float(SimState.signal_params["amplitude"])
			elif pid == "fg_offset":
				target_v = float(SimState.signal_params["dc_offset"])
			ctrl["value"] = target_v
			var norm := clampf((target_v - float(ctrl["min"])) / maxf(float(ctrl["max"]) - float(ctrl["min"]), 1e-6), 0.0, 1.0)
			ctrl["rotor"].rotation.z = lerpf(deg_to_rad(135.0), deg_to_rad(-135.0), norm)
		elif ctrl["type"] == "switch":
			if pid == "coupling":
				ctrl["index"] = int(SimState.analog_config["coupling"])
			elif pid == "trigger_slope":
				ctrl["index"] = int(SimState.analog_config["trigger_slope"])
			elif pid == "probe_attenuation_switch":
				ctrl["index"] = 1 if float(SimState.analog_config["probe_attenuation"]) > 1.5 else 0
			VP5231A3DBuilder.update_switch_visual(ctrl)

	var wf_lbl: Label3D = _scope_data.get("fg_wf_lbl")
	var freq_lbl: Label3D = _scope_data.get("fg_freq_lbl")
	var amp_lbl: Label3D = _scope_data.get("fg_amp_lbl")
	if wf_lbl != null:
		var wf_name: String = SignalGenerator.WAVEFORM_NAMES[int(SimState.signal_params["waveform"])]
		wf_lbl.text = "EDIT CH%d: %s  [ON]" % [SimState.fg_selected_channel, wf_name.to_upper()]
		freq_lbl.text = "Freq: %.0f Hz" % SimState.signal_params["frequency"]
		amp_lbl.text = "Ampl: %.2f Vpp" % (SimState.signal_params["amplitude"] * 2.0)

	# Update Calibration Checklist HUD if in Calibration Lab Mode
	if _checklist_panel != null:
		var is_cal_mode := (SimState.lab_mode == "CALIBRATION")
		_checklist_panel.visible = is_cal_mode
		if is_cal_mode:
			var steps := SimState.get_calibration_checklist()
			var done_count := 0
			var lines: Array[String] = ["CALIBRATION PRACTICUM (Scrambled Bench — Calibrate VP-5231A):"]
			for s in steps:
				if s["done"]:
					done_count += 1
					lines.append("  [✓] " + s["text"])
				else:
					lines.append("  [ ] " + s["text"])
			if done_count == steps.size():
				lines.append("  >>> SCOPE CALIBRATED! Now drag Probe Tip to Siglent CH1 OUT or CH2 OUT! <<<")
			_checklist_lbl.text = "\n".join(lines)
