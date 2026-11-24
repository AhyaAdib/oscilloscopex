class_name Workbench3D
extends SubViewportContainer

const VOLTS_STEPS := [0.2, 0.5, 1.0, 2.0, 5.0]
const TIME_STEPS := [0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005]

const CAMERA_PRESETS := [
	{"name": "1: Full Bench", "pos": Vector3(0.0, 0.28, 0.66), "target": Vector3(0.0, 0.08, 0.12)},
	{"name": "2: Scope Knobs", "pos": Vector3(0.09, 0.14, 0.35), "target": Vector3(0.09, 0.10, 0.14)},
	{"name": "3: CRT + CAL Hook", "pos": Vector3(-0.09, 0.13, 0.33), "target": Vector3(-0.09, 0.10, 0.14)},
	{"name": "4: Siglent Gen", "pos": Vector3(-0.22, 0.14, 0.34), "target": Vector3(-0.34, 0.06, 0.08)},
	{"name": "5: Breadboard + PSU", "pos": Vector3(0.08, 0.16, 0.44), "target": Vector3(0.06, 0.03, 0.22)}
]

var _main_vp: SubViewport
var _crt_vp: SubViewport
var _camera: Camera3D
var _scope_data := {}
var _env_data := {}
var _world_env: WorldEnvironment
var _key_light: DirectionalLight3D
var _hover_ring: MeshInstance3D
var _ring_mat: StandardMaterial3D

var _hovered_ctrl := {}
var _active_knob := {}
var _dragging_probe_kind := "" # "bnc" or "tip"
var _dragging_probe_idx := 1
var _drag_plane := Plane(Vector3.BACK, 0.20)
var _drag_grab_offset := Vector3.ZERO
var _drag_current_world := Vector3.ZERO
var _drag_target_world := Vector3.ZERO
var _drag_start_y := 0.0
var _drag_start_val := 0.0

# Smooth damped camera state
var _orbiting := false
var _panning := false
var _yaw := 0.0
var _pitch := -0.22
var _dist := 0.50
var _cam_target := Vector3(0.02, 0.09, 0.14)

var _goal_yaw := 0.0
var _goal_pitch := -0.22
var _goal_dist := 0.50
var _goal_target := Vector3(0.02, 0.09, 0.14)

var _pulse_time := 0.0
var _hud_label: Label
var _checklist_panel: PanelContainer
var _checklist_lbl: Label
var _mission_card: PanelContainer
var _m_timer_lbl: Label
var _m_title_lbl: Label
var _m_desc_lbl: Label
var _m_vpp_spin: SpinBox
var _m_freq_spin: SpinBox
var _m_off_spin: SpinBox
var _m_res_lbl: Label
var _preset_buttons: Array[Button] = []

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

func _process(delta: float) -> void:
	_pulse_time += delta

	# 1. Smoothly glide camera toward target preset / orbit / pan / zoom
	var cam_blend := 1.0 - exp(-11.0 * delta)
	_yaw = lerpf(_yaw, _goal_yaw, cam_blend)
	_pitch = lerpf(_pitch, _goal_pitch, cam_blend)
	_dist = lerpf(_dist, _goal_dist, cam_blend)
	_cam_target = _cam_target.lerp(_goal_target, cam_blend)
	_update_camera_transform()

	# 2. Smoothly follow cursor while dragging a probe
	if _dragging_probe_kind != "":
		var probe_blend := 1.0 - exp(-26.0 * delta)
		_drag_current_world = _drag_current_world.lerp(_drag_target_world, probe_blend)
		var p_key := "probe1" if _dragging_probe_idx == 1 else "probe2"
		var p_data: Dictionary = _scope_data[p_key]
		var snaps: Dictionary = _scope_data.get("snap_targets", {})
		var cur_bnc := str(SimState.analog_config.get(p_key + "_bnc", "UNPLUGGED"))
		var cur_tip := str(SimState.analog_config.get(p_key + "_tip", "FLOATING"))
		VP5231A3DBuilder.update_single_probe(p_data, snaps, cur_bnc, cur_tip, _dragging_probe_kind, _drag_current_world)

	# 2b. Live update Timed Mission Card on 3D Bench
	if _mission_card != null and has_node("/root/SimState"):
		var show_card := SimState.active_challenge_running or (SimState.last_mission_report != "")
		_mission_card.visible = show_card
		if show_card:
			var t_rem := float(SimState.active_time_remaining)
			var mins := int(t_rem) / 60
			var secs := int(t_rem) % 60
			_m_timer_lbl.text = ("⏱ TIME LEFT: %02d:%02d  [ACTIVE]" % [mins, secs]) if SimState.active_challenge_running else "✓ MISSION SUBMITTED"
			_m_title_lbl.text = str(SimState.active_mission_data.get("title", ""))
			_m_desc_lbl.text = str(SimState.active_mission_data.get("description", ""))
			if SimState.last_mission_report != "":
				_m_res_lbl.text = SimState.last_mission_report

	LabEnvironmentBuilder.animate_lab_life(_env_data, delta)
	LabEnvironmentBuilder.update_view_occlusion(_env_data, _camera)

	# 3. Subtle pulsing glow on the active cyan-blue selection ring
	if _hover_ring != null and _hover_ring.visible and _ring_mat != null:
		_ring_mat.emission_energy_multiplier = 2.4 + sin(_pulse_time * 6.5) * 0.8

func _build_3d_scene() -> void:
	_crt_vp = SubViewport.new()
	_crt_vp.size = Vector2i(480, 345)
	_crt_vp.msaa_3d = Viewport.MSAA_DISABLED
	_crt_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_crt_vp)

	var crt_canvas := WaveformCanvas.new()
	crt_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_crt_vp.add_child(crt_canvas)

	_main_vp = SubViewport.new()
	_main_vp.size = Vector2i(1024, 540)
	_main_vp.own_world_3d = true
	_main_vp.use_occlusion_culling = true
	_main_vp.msaa_3d = Viewport.MSAA_DISABLED
	_main_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_main_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_main_vp)

	_world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.10, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.69, 1.0)
	env.ambient_light_energy = 0.95
	_world_env.environment = env
	_main_vp.add_child(_world_env)

	var key_light := DirectionalLight3D.new()
	self._key_light = key_light
	key_light.look_at_from_position(Vector3(0.4, 0.9, 0.85), Vector3(0.0, 0.1, 0.15), Vector3.UP)
	key_light.light_energy = 1.15
	_main_vp.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-0.35, 0.35, 0.55)
	fill_light.light_energy = 0.70
	fill_light.omni_range = 2.5
	_main_vp.add_child(fill_light)

	_env_data = LabEnvironmentBuilder.build_studio_workbench(_main_vp)

	_scope_data = VP5231A3DBuilder.build_oscilloscope(_main_vp, _crt_vp.get_texture())

	_hover_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.80
	torus.outer_radius = 1.0
	_hover_ring.mesh = torus
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = Color(0.22, 0.78, 1.0, 1.0)
	_ring_mat.emission_enabled = true
	_ring_mat.emission = Color(0.25, 0.82, 1.0, 1.0)
	_ring_mat.emission_energy_multiplier = 2.8
	_ring_mat.no_depth_test = true
	_hover_ring.material_override = _ring_mat
	_hover_ring.rotation.x = PI * 0.5
	_hover_ring.visible = false
	_main_vp.add_child(_hover_ring)

	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.near = 0.02
	_camera.far = 10.0
	_main_vp.add_child(_camera)
	_apply_camera_preset(0, true)

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
	_hud_label.text = "Left-Drag: Knob/Probe | Ctrl+Left-Drag or Mid-Drag: Pan | Right-Drag: Orbit | Wheel: Zoom/Turn"
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
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		var idx := i
		btn.pressed.connect(func() -> void: _apply_camera_preset(idx, false))
		preset_bar.add_child(btn)
		_preset_buttons.append(btn)

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

	# Active Timed Mission & Reading Submission Card (visible when a Challenge starts)
	_mission_card = PanelContainer.new()
	_mission_card.custom_minimum_size = Vector2(360, 0)
	_mission_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_mission_card.visible = false
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.06, 0.09, 0.13, 0.93)
	msb.border_color = Color(1.0, 0.76, 0.22, 0.95)
	msb.set_border_width_all(2)
	msb.set_corner_radius_all(6)
	_mission_card.add_theme_stylebox_override("panel", msb)
	vbox.add_child(_mission_card)

	var m_pad := MarginContainer.new()
	m_pad.add_theme_constant_override("margin_left", 12)
	m_pad.add_theme_constant_override("margin_right", 12)
	m_pad.add_theme_constant_override("margin_top", 8)
	m_pad.add_theme_constant_override("margin_bottom", 8)
	_mission_card.add_child(m_pad)

	var m_vb := VBoxContainer.new()
	m_vb.add_theme_constant_override("separation", 5)
	m_pad.add_child(m_vb)

	_m_timer_lbl = Label.new()
	_m_timer_lbl.text = "⏱ TIME LEFT: 02:00"
	_m_timer_lbl.add_theme_font_size_override("font_size", 15)
	_m_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 1.0))
	m_vb.add_child(_m_timer_lbl)

	_m_title_lbl = Label.new()
	_m_title_lbl.add_theme_font_size_override("font_size", 12)
	_m_title_lbl.add_theme_color_override("font_color", Color(0.45, 0.95, 0.78, 1.0))
	m_vb.add_child(_m_title_lbl)

	_m_desc_lbl = Label.new()
	_m_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_m_desc_lbl.custom_minimum_size = Vector2(330, 0)
	_m_desc_lbl.add_theme_font_size_override("font_size", 11)
	_m_desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96, 1.0))
	m_vb.add_child(_m_desc_lbl)

	var m_grid := GridContainer.new()
	m_grid.columns = 2
	m_grid.add_theme_constant_override("h_separation", 8)
	m_grid.add_theme_constant_override("v_separation", 4)
	m_vb.add_child(m_grid)

	var ml1 := Label.new(); ml1.text = "Measured Vpp (V):"; ml1.add_theme_font_size_override("font_size", 11); m_grid.add_child(ml1)
	_m_vpp_spin = SpinBox.new(); _m_vpp_spin.min_value = 0.0; _m_vpp_spin.max_value = 20.0; _m_vpp_spin.step = 0.05; _m_vpp_spin.value = 1.0; m_grid.add_child(_m_vpp_spin)

	var ml2 := Label.new(); ml2.text = "Measured Freq (Hz):"; ml2.add_theme_font_size_override("font_size", 11); m_grid.add_child(ml2)
	_m_freq_spin = SpinBox.new(); _m_freq_spin.min_value = 10.0; _m_freq_spin.max_value = 20000.0; _m_freq_spin.step = 10.0; _m_freq_spin.value = 1000.0; m_grid.add_child(_m_freq_spin)

	var ml3 := Label.new(); ml3.text = "DC Offset (V):"; ml3.add_theme_font_size_override("font_size", 11); m_grid.add_child(ml3)
	_m_off_spin = SpinBox.new(); _m_off_spin.min_value = -10.0; _m_off_spin.max_value = 10.0; _m_off_spin.step = 0.05; _m_off_spin.value = 0.0; m_grid.add_child(_m_off_spin)

	var m_sub_btn := Button.new()
	m_sub_btn.text = "✓ SUBMIT READING & CALIBRATION"
	m_sub_btn.pressed.connect(func() -> void:
		var res := ChallengeManager.evaluate_submission(SimState.active_mission_data, _m_vpp_spin.value, _m_freq_spin.value, _m_off_spin.value, SimState.active_time_remaining)
		SimState.submission_attempts += 1
		if not res["passed"]:
			SimState.failed_attempts += 1
		if res["passed"] or SimState.active_time_remaining <= 0.0:
			SimState.active_challenge_running = false
			SimState.last_mission_report = "FINAL: %d/100 (%s) | Attempts: %d (Fails: %d) | True: %.2fVpp, %.0fHz, %.2fV" % [res["total_score"], "PASS" if res["passed"] else "TIME UP", SimState.submission_attempts, SimState.failed_attempts, res["true_vpp"], res["true_freq"], res["true_offset"]]
		else:
			SimState.last_mission_report = "Score: %d/100 — KEEP GOING! | Attempts: %d (Fails: %d)\nHint: Route:%s | Comp:%s | Trig:%s | Vpp:%s | Freq:%s" % [res["total_score"], SimState.submission_attempts, SimState.failed_attempts, "OK" if res["routing_ok"] else "NO", "OK" if res["comp_ok"] else "OFF", "OK" if res["trig_ok"] else "NO", "OK" if res["vpp_ok"] else "ERR", "OK" if res["freq_ok"] else "ERR"]
		_m_res_lbl.text = SimState.last_mission_report
	)
	m_vb.add_child(m_sub_btn)

	_m_res_lbl = Label.new()
	_m_res_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_m_res_lbl.custom_minimum_size = Vector2(330, 0)
	_m_res_lbl.add_theme_font_size_override("font_size", 11)
	_m_res_lbl.add_theme_color_override("font_color", Color(0.45, 0.96, 0.78, 1.0))
	m_vb.add_child(_m_res_lbl)

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

func _apply_camera_preset(idx: int, instant := false) -> void:
	var clamped := clampi(idx, 0, CAMERA_PRESETS.size() - 1)
	for i in range(_preset_buttons.size()):
		_preset_buttons[i].set_pressed_no_signal(i == clamped)

	var preset: Dictionary = CAMERA_PRESETS[clamped]
	var p: Vector3 = preset["pos"]
	var t: Vector3 = preset["target"]
	_goal_target = t
	var offset := p - t
	_goal_dist = offset.length()
	_goal_yaw = atan2(offset.x, offset.z)
	_goal_pitch = clampf(asin(-offset.y / maxf(_goal_dist, 1e-4)), -1.2, 0.1)

	if instant:
		_cam_target = _goal_target
		_dist = _goal_dist
		_yaw = _goal_yaw
		_pitch = _goal_pitch
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

func _project_cursor_to_drag_world(local_pos: Vector2) -> Vector3:
	var ray := _screen_to_vp_ray(local_pos)
	var hit: Variant = _drag_plane.intersects_ray(ray["origin"], ray["dir"])
	var pt: Vector3 = hit if hit != null else _drag_target_world
	pt += _drag_grab_offset
	pt.x = clampf(pt.x, -0.45, 0.50)
	pt.y = clampf(pt.y, 0.011, 0.28)
	pt.z = clampf(pt.z, 0.16, 0.34)
	return pt

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _camera == null:
		return
	var local_pos := get_local_mouse_position()
	var rect := Rect2(Vector2.ZERO, size)
	if not rect.has_point(local_pos) and _active_knob.is_empty() and _dragging_probe_kind == "" and not _orbiting and not _panning:
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

		if _panning:
			var cam_right := _camera.global_transform.basis.x
			var cam_up := _camera.global_transform.basis.y
			var pan_speed := _goal_dist * 0.0015
			_goal_target -= cam_right * (mm.relative.x * pan_speed)
			_goal_target += cam_up * (mm.relative.y * pan_speed)
			_goal_target.x = clampf(_goal_target.x, -0.45, 0.50)
			_goal_target.y = clampf(_goal_target.y, 0.02, 0.32)
			_goal_target.z = clampf(_goal_target.z, -0.15, 0.35)
			get_viewport().set_input_as_handled()
			return

		if _orbiting:
			_goal_yaw = clampf(_goal_yaw - mm.relative.x * 0.007, -1.35, 1.35)
			_goal_pitch = clampf(_goal_pitch - mm.relative.y * 0.007, -1.15, 0.05)
			get_viewport().set_input_as_handled()
			return

		_pick_hovered_control(local_pos)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
			mouse_default_cursor_shape = Control.CURSOR_MOVE if mb.pressed else Control.CURSOR_ARROW
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mb.pressed
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_pick_hovered_control(local_pos)
			if not _hovered_ctrl.is_empty() and _hovered_ctrl["type"] == "knob":
				_set_knob_3d_value(_hovered_ctrl, float(_hovered_ctrl["value"]) + float(_hovered_ctrl["step"]))
			else:
				_goal_dist = clampf(_goal_dist - 0.04, 0.16, 1.05)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_pick_hovered_control(local_pos)
			if not _hovered_ctrl.is_empty() and _hovered_ctrl["type"] == "knob":
				_set_knob_3d_value(_hovered_ctrl, float(_hovered_ctrl["value"]) - float(_hovered_ctrl["step"]))
			else:
				_goal_dist = clampf(_goal_dist + 0.04, 0.16, 1.05)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if Input.is_key_pressed(KEY_CTRL):
					_panning = true
					mouse_default_cursor_shape = Control.CURSOR_MOVE
					get_viewport().set_input_as_handled()
					return
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
					elif t == "draggable_tip" or t == "draggable_bnc":
						_dragging_probe_kind = "tip" if t == "draggable_tip" else "bnc"
						_dragging_probe_idx = int(_hovered_ctrl["probe_idx"])
						var p_key := "probe1" if _dragging_probe_idx == 1 else "probe2"
						var probe_root: Node3D = _scope_data[p_key]["probe_tip" if _dragging_probe_kind == "tip" else "bnc_plug"]
						var cam_fwd := -_camera.global_transform.basis.z
						_drag_plane = Plane(-cam_fwd, probe_root.global_position)
						var ray := _screen_to_vp_ray(local_pos)
						var initial_hit: Variant = _drag_plane.intersects_ray(ray["origin"], ray["dir"])
						_drag_grab_offset = (probe_root.global_position - initial_hit) if initial_hit != null else Vector3.ZERO
						_drag_current_world = probe_root.global_position
						_drag_target_world = probe_root.global_position
						mouse_default_cursor_shape = Control.CURSOR_DRAG
						_handle_probe_drag(local_pos)
					get_viewport().set_input_as_handled()
			else:
				if _panning:
					_panning = false
					mouse_default_cursor_shape = Control.CURSOR_ARROW
					get_viewport().set_input_as_handled()
				if _dragging_probe_kind != "":
					_finish_probe_drop(local_pos)
					_dragging_probe_kind = ""
					mouse_default_cursor_shape = Control.CURSOR_ARROW
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
		var mode_names: Array[String] = ["CH1 ONLY", "ALT (BOTH)", "CH2 ONLY"]
		var m_str: String = mode_names[clampi(int(SimState.analog_config.get("vert_mode", 1)), 0, 2)]
		_hud_label.text = "MODE:%s | P1[%s→%s] P2[%s→%s] | Ctrl+Drag: Pan | Right-Drag: Orbit" % [m_str, p1_b, p1_t, p2_b, p2_t]

func _handle_probe_drag(local_pos: Vector2) -> void:
	var world_pt := _project_cursor_to_drag_world(local_pos)

	var snaps: Dictionary = _scope_data.get("snap_targets", {})
	var nearest_key := ""
	var nearest_dist := 0.060
	for key in snaps.keys():
		var info: Dictionary = snaps[key]
		if info["kind"] != _dragging_probe_kind:
			continue
		var target_node: Node3D = info["node"]
		var snap_pos: Vector3 = target_node.global_position + info["offset"]
		var d := world_pt.distance_to(snap_pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest_key = key

	if nearest_key != "":
		var info: Dictionary = snaps[nearest_key]
		var target_node: Node3D = info["node"]
		_hover_ring.visible = true
		_hover_ring.global_position = target_node.global_position + Vector3(0, 0, 0.010)
		_hover_ring.scale = Vector3(0.017, 0.017, 0.017)
		_hud_label.text = "[RELEASE TO PLUG PROBE %d INTO] %s" % [_dragging_probe_idx, info["label"]]
		_drag_target_world = target_node.global_position + info["offset"]
	else:
		_hover_ring.visible = false
		_hud_label.text = "Dragging Probe %d %s — Move over any jack to snap, or release on mat to unplug" % [_dragging_probe_idx, _dragging_probe_kind.to_upper()]
		_drag_target_world = world_pt

func _finish_probe_drop(local_pos: Vector2) -> void:
	var world_pt := _project_cursor_to_drag_world(local_pos)

	var snaps: Dictionary = _scope_data.get("snap_targets", {})
	var nearest_key := ""
	var nearest_dist := 0.060
	for key in snaps.keys():
		var info: Dictionary = snaps[key]
		if info["kind"] != _dragging_probe_kind:
			continue
		var target_node: Node3D = info["node"]
		var snap_pos: Vector3 = target_node.global_position + info["offset"]
		var d := world_pt.distance_to(snap_pos)
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
		"psu_voltage_coarse", "psu_voltage_fine":
			SimState.set_analog_param(pid, snapped_v)
			var psu_d: Dictionary = _scope_data.get("psu", {})
			if psu_d.has("show_amps"):
				psu_d["show_amps"] = false
		"psu_current_limit":
			SimState.set_analog_param(pid, snapped_v)
			var psu_d: Dictionary = _scope_data.get("psu", {})
			if psu_d.has("show_amps"):
				psu_d["show_amps"] = true

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
		"probe2_attenuation_switch":
			SimState.set_analog_param("probe2_attenuation", 10.0 if next_idx == 1 else 1.0)

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
	elif pid == "psu_power_on":
		var next_psu := not bool(SimState.analog_config.get("psu_power_on", true))
		SimState.set_analog_param("psu_power_on", next_psu)
		_update_hover_hud(ctrl)

func _sync_visuals() -> void:
	# Sync GW Instek GPS-3030D LED Readout & VOLTS/AMPS Indicators
	var psu_dict: Dictionary = _scope_data.get("psu", {})
	if not psu_dict.is_empty() and psu_dict.has("readout_lbl"):
		var r_lbl: Label3D = psu_dict["readout_lbl"]
		var p_on := bool(SimState.analog_config.get("psu_power_on", true))
		var show_a := bool(psu_dict.get("show_amps", false))
		var v_tot := clampf(float(SimState.analog_config.get("psu_voltage_coarse", 12.0)) + float(SimState.analog_config.get("psu_voltage_fine", 0.0)), 0.0, 30.0)
		var i_lim := float(SimState.analog_config.get("psu_current_limit", 1.5))
		if not p_on:
			r_lbl.text = " OFF "
		elif show_a:
			r_lbl.text = "%.2f A" % i_lim
		else:
			r_lbl.text = "%.2f V" % v_tot
		if psu_dict.has("volts_led") and psu_dict.has("amps_led"):
			(psu_dict["volts_led"] as MeshInstance3D).visible = p_on and not show_a
			(psu_dict["amps_led"] as MeshInstance3D).visible = p_on and show_a

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

	Breadboard3DBuilder.set_board_style(_scope_data.get("breadboard", {}), SimState.board_is_pcb)
	Breadboard3DBuilder.set_active_model(_scope_data.get("breadboard", {}), SimState.breadboard_model_idx)
	LabEnvironmentBuilder.apply_theme(_env_data, _world_env, _key_light, SimState.lab_theme_idx)
	var snaps: Dictionary = _scope_data["snap_targets"]
	if _dragging_probe_kind == "":
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

	for ctrl in _scope_data.get("interactables", []):
		var pid: String = ctrl.get("param_id", "")
		if ctrl["type"] == "knob":
			var target_v := float(ctrl["value"])
			if SimState.analog_config.has(pid):
				target_v = float(SimState.analog_config[pid])
			elif pid == "ch2_pos":
				target_v = float(SimState.analog_config.get("ch2_vert_pos_div", 0.0))
			elif pid == "volts_per_div":
				var v_cur := float(SimState.view_config["volts_per_div"])
				for i in range(VOLTS_STEPS.size()):
					if absf(VOLTS_STEPS[i] - v_cur) < 1e-4:
						target_v = float(i)
			elif pid == "ch2_volts":
				var v2_cur := float(SimState.view_config.get("ch2_volts_per_div", 1.0))
				for i in range(VOLTS_STEPS.size()):
					if absf(VOLTS_STEPS[i] - v2_cur) < 1e-4:
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
			if pid == "vert_mode":
				ctrl["index"] = int(SimState.analog_config.get("vert_mode", 1))
			elif pid == "coupling":
				ctrl["index"] = int(SimState.analog_config["coupling"])
			elif pid == "ch2_coupling":
				ctrl["index"] = int(SimState.analog_config.get("ch2_coupling", 0))
			elif pid == "trigger_slope":
				ctrl["index"] = int(SimState.analog_config["trigger_slope"])
			elif pid == "probe_attenuation_switch":
				ctrl["index"] = 1 if float(SimState.analog_config["probe_attenuation"]) > 1.5 else 0
			elif pid == "probe2_attenuation_switch":
				ctrl["index"] = 1 if float(SimState.analog_config.get("probe2_attenuation", 1.0)) > 1.5 else 0
			VP5231A3DBuilder.update_switch_visual(ctrl)

	var wf_lbl: Label3D = _scope_data.get("fg_wf_lbl")
	var freq_lbl: Label3D = _scope_data.get("fg_freq_lbl")
	var amp_lbl: Label3D = _scope_data.get("fg_amp_lbl")
	if wf_lbl != null:
		var wf_name: String = SignalGenerator.WAVEFORM_NAMES[int(SimState.signal_params["waveform"])]
		wf_lbl.text = "EDIT CH%d: %s  [ON]" % [SimState.fg_selected_channel, wf_name.to_upper()]
		freq_lbl.text = "Freq: %.0f Hz" % SimState.signal_params["frequency"]
		amp_lbl.text = "Ampl: %.2f Vpp" % (SimState.signal_params["amplitude"] * 2.0)

	if _checklist_panel != null:
		var is_cal_mode := (SimState.lab_mode == "CALIBRATION") and (not SimState.active_challenge_running)
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


func _clear_camera_preset_buttons() -> void:
	if "_preset_buttons" in self:
		for btn in _preset_buttons:
			if is_instance_valid(btn) and "button_pressed" in btn:
				btn.button_pressed = false
