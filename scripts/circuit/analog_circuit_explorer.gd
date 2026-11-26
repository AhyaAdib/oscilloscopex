
class_name AnalogCircuitExplorer
extends HBoxContainer

var _arch_controller: ArchitectureController
var _arch_toolbar: ArchitectureToolbar
var _diagram_host: Control

const STAGES := [
	{
		"id": "N1_INPUT",
		"title": "1. INPUT BNC",
		"sub": "1MΩ // 25pF",
		"branch": "VERT",
		"pos": Vector2(0.08, 0.25),
		"equation": "v_in(t) = V_off + A·sin(2πft + φ) + n(t)",
		"desc": "Coaxial BNC input terminal with overvoltage clamp diodes and standard 1 MΩ || 25 pF input impedance."
	},
	{
		"id": "N2_COUPLING",
		"title": "2. COUPLING",
		"sub": "AC / DC / GND",
		"branch": "VERT",
		"pos": Vector2(0.24, 0.25),
		"equation": "DC: v_out = v_in  |  GND: 0V  |  AC: H(s) = sRC/(1+sRC), fc = 10 Hz",
		"desc": "Selects direct DC path, 0V ground reference, or series DC-blocking high-pass capacitor."
	},
	{
		"id": "N3_ATTENUATOR",
		"title": "3. ATTENUATOR",
		"sub": "1x / 10x Div",
		"branch": "VERT",
		"pos": Vector2(0.40, 0.25),
		"equation": "v_att(t) = v_coup(t) · R2 / (R1 + R2)",
		"desc": "Frequency-compensated resistive-capacitive divider protecting the vertical preamp from high voltages."
	},
	{
		"id": "N4_PREAMP",
		"title": "4. VERT PREAMP",
		"sub": "Av · Vin (±40V)",
		"branch": "VERT",
		"pos": Vector2(0.56, 0.25),
		"equation": "v_amp(t) = clamp(Av · v_att(t), -40V, +40V)",
		"desc": "Low-noise JFET differential preamplifier scaling the attenuated signal with supply rail saturation."
	},
	{
		"id": "N5_DELAY_LINE",
		"title": "5. DELAY LINE",
		"sub": "τ_delay = 50 µs",
		"branch": "VERT",
		"pos": Vector2(0.72, 0.25),
		"equation": "v_del(t) = v_amp(t - τ_d)",
		"desc": "Delays the vertical waveform so the trigger & sweep generator can start the beam before the triggering edge arrives."
	},
	{
		"id": "N6_VERT_DEFLECT",
		"title": "6. VERT DEFLECT",
		"sub": "Y-Plates + Pos",
		"branch": "VERT",
		"pos": Vector2(0.89, 0.25),
		"equation": "y(t) = K_y · (v_del(t) + V_pos)",
		"desc": "Push-pull high-voltage deflection amplifier driving the CRT vertical electrostatic plates."
	},
	{
		"id": "N7_TRIGGER",
		"title": "7. TRIGGER",
		"sub": "Schmitt Comp",
		"branch": "TRIG",
		"pos": Vector2(0.36, 0.68),
		"equation": "Rising: v[n-1] < V_T and v[n] ≥ V_T (with hysteresis)",
		"desc": "Taps post-coupling vertical signal and fires a synchronized gate pulse when crossing Trigger Level."
	},
	{
		"id": "N8_SWEEP",
		"title": "8. SWEEP & X-AMP",
		"sub": "Miller Ramp",
		"branch": "TRIG",
		"pos": Vector2(0.66, 0.68),
		"equation": "x(t) = x_0 + S_x · (t - t_trig)   [-5V → +5V]",
		"desc": "Constant-current Miller integrator generating a linear horizontal sawtooth ramp across the CRT X-plates."
	}
]

const WIRES := [
	["N1_INPUT", "N2_COUPLING", "VERT"],
	["N2_COUPLING", "N3_ATTENUATOR", "VERT"],
	["N3_ATTENUATOR", "N4_PREAMP", "VERT"],
	["N4_PREAMP", "N5_DELAY_LINE", "VERT"],
	["N5_DELAY_LINE", "N6_VERT_DEFLECT", "VERT"],
	["N2_COUPLING", "N7_TRIGGER", "TRIG"],
	["N7_TRIGGER", "N8_SWEEP", "TRIG"]
]

var _diagram_canvas: Control
var _probe_canvas: Control
var _title_lbl: Label
var _eq_lbl: Label
var _desc_lbl: Label
var _params_lbl: Label
var _metrics_lbl: Label
var _flow_phase := 0.0

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build_layout()
	_setup_milestone1_3d_layer()
	if has_node("/root/SimState"):
		SimState.state_updated.connect(_refresh_inspector)
		SimState.selected_node_changed.connect(func(_id: String) -> void: _refresh_inspector())
	_refresh_inspector()

func _process(delta: float) -> void:
	if has_node("/root/SimState") and SimState.view_config.get("power_on", true) and SimState.view_config.get("running", true):
		_flow_phase = fmod(_flow_phase + delta * 1.8, 1.0)
		if _diagram_canvas != null:
			_diagram_canvas.queue_redraw()

func _build_layout() -> void:
	# Left: Interactive Block Diagram
	var left_panel := PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 1.65
	var sb_left := StyleBoxFlat.new()
	sb_left.bg_color = Color(0.05, 0.07, 0.09, 1.0)
	sb_left.border_color = Color(0.20, 0.28, 0.34, 1.0)
	sb_left.set_border_width_all(2)
	sb_left.set_corner_radius_all(6)
	left_panel.add_theme_stylebox_override("panel", sb_left)
	add_child(left_panel)

	_diagram_canvas = Control.new()
	_diagram_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_diagram_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_diagram_canvas.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_diagram_canvas.draw.connect(_draw_block_diagram)
	_diagram_canvas.gui_input.connect(_on_diagram_input)
	left_panel.add_child(_diagram_canvas)

	# Right: Node Probe & Equation Inspector
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 1.0
	var sb_right := StyleBoxFlat.new()
	sb_right.bg_color = Color(0.07, 0.09, 0.12, 1.0)
	sb_right.border_color = Color(0.22, 0.32, 0.38, 1.0)
	sb_right.set_border_width_all(2)
	sb_right.set_corner_radius_all(6)
	right_panel.add_theme_stylebox_override("panel", sb_right)
	add_child(right_panel)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	right_panel.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	pad.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "INTERNAL NODE PROBE INSPECTOR"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0, 1.0))
	vbox.add_child(hdr)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 17)
	_title_lbl.add_theme_color_override("font_color", Color(0.30, 1.0, 0.72, 1.0))
	vbox.add_child(_title_lbl)

	_eq_lbl = Label.new()
	_eq_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_eq_lbl.add_theme_font_size_override("font_size", 12)
	_eq_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35, 1.0))
	vbox.add_child(_eq_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.add_theme_font_size_override("font_size", 12)
	_desc_lbl.add_theme_color_override("font_color", Color(0.76, 0.82, 0.88, 1.0))
	vbox.add_child(_desc_lbl)

	vbox.add_child(HSeparator.new())

	_params_lbl = Label.new()
	_params_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_params_lbl.add_theme_font_size_override("font_size", 12)
	_params_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95, 1.0))
	vbox.add_child(_params_lbl)

	_metrics_lbl = Label.new()
	_metrics_lbl.add_theme_font_size_override("font_size", 13)
	_metrics_lbl.add_theme_color_override("font_color", Color(0.35, 0.98, 0.75, 1.0))
	vbox.add_child(_metrics_lbl)

	# Live Node Probe Mini-Oscilloscope
	_probe_canvas = Control.new()
	_probe_canvas.custom_minimum_size = Vector2(240, 180)
	_probe_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_probe_canvas.draw.connect(_draw_node_probe_waveform)
	vbox.add_child(_probe_canvas)

func _get_stage_rect(stage: Dictionary, canvas_size: Vector2) -> Rect2:
	var box_w := clampf(canvas_size.x * 0.135, 92.0, 145.0)
	var box_h := 66.0
	var center := Vector2(stage["pos"].x * canvas_size.x, stage["pos"].y * canvas_size.y)
	return Rect2(center - Vector2(box_w * 0.5, box_h * 0.5), Vector2(box_w, box_h))

func _on_diagram_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var sz := _diagram_canvas.size
			for stage in STAGES:
				if _get_stage_rect(stage, sz).has_point(mb.position):
					if has_node("/root/SimState"):
						SimState.select_circuit_node(stage["id"])
					break

func _draw_block_diagram() -> void:
	var sz := _diagram_canvas.size
	if sz.x < 40.0 or sz.y < 40.0:
		return
	var font := ThemeDB.fallback_font


  # Section Titles
	_diagram_canvas.draw_string(font, Vector2(18, 26), "NATIONAL VP-5231A — INTERNAL ANALOG SIGNAL & TIMEBASE ARCHITECTURE (Click Any Block to Probe)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.75, 0.86, 0.92, 1.0))
	_diagram_canvas.draw_string(font, Vector2(18, sz.y * 0.10), "VERTICAL SIGNAL PATH (Y-DEFLECTION)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.30, 0.95, 0.72, 0.85))
	_diagram_canvas.draw_string(font, Vector2(18, sz.y * 0.53), "TRIGGER & HORIZONTAL TIMEBASE PATH (X-DEFLECTION)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.76, 0.28, 0.85))

	var stage_rects := {}
	for stage in STAGES:
		stage_rects[stage["id"]] = _get_stage_rect(stage, sz)

	var power_on := true
	var selected_id := "N3_ATTENUATOR"
	if has_node("/root/SimState"):
		power_on = bool(SimState.view_config.get("power_on", true))
		selected_id = SimState.selected_circuit_node

	# Draw Connecting Wires & Animated Signal Pulses
	for wire in WIRES:
		var r_from: Rect2 = stage_rects[wire[0]]
		var r_to: Rect2 = stage_rects[wire[1]]
		var branch: String = wire[2]
		var p1 := Vector2(r_from.end.x, r_from.get_center().y)
		var p2 := Vector2(r_to.position.x, r_to.get_center().y)
		if wire[0] == "N2_COUPLING" and wire[1] == "N7_TRIGGER":
			p1 = Vector2(r_from.get_center().x, r_from.end.y)
			p2 = Vector2(r_to.position.x, r_to.get_center().y)

		var base_col := Color(0.22, 0.75, 0.58, 0.75) if branch == "VERT" else Color(0.88, 0.65, 0.22, 0.75)
		if not power_on:
			base_col = Color(0.25, 0.28, 0.30, 0.45)

		if wire[0] == "N2_COUPLING" and wire[1] == "N7_TRIGGER":
			var elbow := Vector2(p1.x, p2.y)
			_diagram_canvas.draw_line(p1, elbow, base_col, 2.0)
			_diagram_canvas.draw_line(elbow, p2, base_col, 2.0)
			if power_on:
				var pulse_pos := p1.lerp(elbow, _flow_phase * 2.0) if _flow_phase < 0.5 else elbow.lerp(p2, (_flow_phase - 0.5) * 2.0)
				_diagram_canvas.draw_circle(pulse_pos, 4.0, Color(1.0, 0.85, 0.35, 1.0))
		else:
			_diagram_canvas.draw_line(p1, p2, base_col, 2.2)
			# Arrowhead
			_diagram_canvas.draw_colored_polygon(PackedVector2Array([
				p2,
				p2 + Vector2(-7, -4),
				p2 + Vector2(-7, 4)
			]), base_col)
			if power_on:
				var pulse_pos := p1.lerp(p2, _flow_phase)
				var dot_col := Color(0.45, 1.0, 0.82, 1.0) if branch == "VERT" else Color(1.0, 0.85, 0.35, 1.0)
				_diagram_canvas.draw_circle(pulse_pos, 4.0, dot_col)

	# Draw Stage Blocks with Live Vpp Readout
	for stage in STAGES:
		var id: String = stage["id"]
		var r: Rect2 = stage_rects[id]
		var is_sel := (id == selected_id)
		var is_vert: bool = (stage["branch"] == "VERT")

		var fill_col := Color(0.11, 0.16, 0.20, 1.0) if not is_sel else Color(0.14, 0.26, 0.30, 1.0)
		var border_col := (Color(0.30, 1.0, 0.72, 1.0) if is_vert else Color(1.0, 0.78, 0.28, 1.0)) if is_sel else Color(0.30, 0.40, 0.48, 0.9)

		_diagram_canvas.draw_rect(r, fill_col, true)
		_diagram_canvas.draw_rect(r, border_col, false, 2.5 if is_sel else 1.3)

		_diagram_canvas.draw_string(font, r.position + Vector2(6, 17), stage["title"], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, 11, Color(0.92, 0.95, 0.98, 1.0))
		_diagram_canvas.draw_string(font, r.position + Vector2(6, 33), stage["sub"], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, 10, Color(0.65, 0.75, 0.82, 1.0))

		if has_node("/root/SimState"):
			var stats := SimState.get_node_stats(id)
			var vpp_str := "Vpp: %.2f V" % stats["v_pp"]
			var val_col := Color(0.35, 1.0, 0.75, 1.0) if is_vert else Color(1.0, 0.82, 0.35, 1.0)
			_diagram_canvas.draw_string(font, r.position + Vector2(6, 54), vpp_str, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, 11, val_col)

	# Draw Schematic CRT Tube Symbol on Far Right
	var crt_rect := Rect2(Vector2(sz.x * 0.83, sz.y * 0.56), Vector2(clampf(sz.x * 0.13, 95.0, 140.0), 86.0))
	_diagram_canvas.draw_rect(crt_rect, Color(0.10, 0.34, 0.42, 1.0) if power_on else Color(0.08, 0.14, 0.16, 1.0), true)
	_diagram_canvas.draw_rect(crt_rect, Color(0.55, 0.85, 0.92, 0.9), false, 2.0)
	_diagram_canvas.draw_string(font, crt_rect.position + Vector2(8, 22), "CRT TUBE", HORIZONTAL_ALIGNMENT_LEFT, crt_rect.size.x - 12, 11, Color.WHITE)
	_diagram_canvas.draw_string(font, crt_rect.position + Vector2(8, 40), "Y + X Plates", HORIZONTAL_ALIGNMENT_LEFT, crt_rect.size.x - 12, 10, Color(0.80, 0.95, 0.92, 1.0))

func _refresh_inspector() -> void:
	if not has_node("/root/SimState") or _title_lbl == null:
		return
	var sel_id := SimState.selected_circuit_node
	var active_stage := STAGES[0]
	for s in STAGES:
		if s["id"] == sel_id:
			active_stage = s
			break

	_title_lbl.text = active_stage["title"]
	_eq_lbl.text = "Equation:  " + active_stage["equation"]
	_desc_lbl.text = active_stage["desc"]

	var coup_name: String = AnalogScopeEngine.COUPLING_NAMES[SimState.analog_config["coupling"]]
	var probe_x: int = int(SimState.analog_config["probe_attenuation"])
	var trig_lvl: float = SimState.analog_config["trigger_level"]
	var v_pos: float = SimState.analog_config["vert_pos_div"]
	_params_lbl.text = "Active State:  Coupling = %s  |  Probe = %dx  |  Trig = %.2f V  |  V-Pos = %.1f div" % [
		coup_name, probe_x, trig_lvl, v_pos
	]

	var stats := SimState.get_node_stats(sel_id)
	_metrics_lbl.text = "Vpp: %.3f V   |   Vrms: %.3f V   |   Min/Max: %.2fV / %.2fV" % [
		stats["v_pp"], stats["v_rms"], stats["v_min"], stats["v_max"]
	]
	if _diagram_canvas != null:
		_diagram_canvas.queue_redraw()
	if _probe_canvas != null:
		_probe_canvas.queue_redraw()

func _draw_node_probe_waveform() -> void:
	var sz := _probe_canvas.size
	if sz.x < 20.0 or sz.y < 20.0:
		return
	_probe_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.05, 0.07, 1.0), true)
	_probe_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.22, 0.34, 0.42, 1.0), false, 1.5)

	# Zero-volt midline
	var mid_y := sz.y * 0.5
	_probe_canvas.draw_line(Vector2(0.0, mid_y), Vector2(sz.x, mid_y), Color(0.20, 0.30, 0.36, 0.9), 1.0)

	if not has_node("/root/SimState"):
		return
	var stats := SimState.get_node_stats(SimState.selected_circuit_node)
	var buf: PackedFloat64Array = stats["buffer"]
	var n := buf.size()
	if n < 2:
		return

	# Auto-scale vertical preview cleanly around 0V so small attenuated or large rail signals remain clear
	var peak_abs := maxf(maxf(absf(stats["v_min"]), absf(stats["v_max"])) * 1.25, 0.5)
	var px_per_v := (sz.y * 0.46) / peak_abs
	var step_x := sz.x / float(n - 1)

	var pts := PackedVector2Array()
	pts.resize(n)
	for i in range(n):
		pts[i] = Vector2(float(i) * step_x, mid_y - float(buf[i]) * px_per_v)

	var is_trig_branch := (SimState.selected_circuit_node == "N7_TRIGGER" or SimState.selected_circuit_node == "N8_SWEEP")
	var trace_col := Color(1.0, 0.80, 0.30, 1.0) if is_trig_branch else Color(0.30, 1.0, 0.72, 1.0)
	_probe_canvas.draw_polyline(pts, trace_col, 2.0, true)

	var font := ThemeDB.fallback_font
	_probe_canvas.draw_string(font, Vector2(8, 16), "LIVE NODE PROBE (±%.2f V full-scale)" % peak_abs, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.85, 0.90, 0.9))

func _setup_milestone1_3d_layer() -> void:
	if get_child_count() < 1:
		return
	var left_node := get_child(0)
	if left_node == null:
		return

	_arch_toolbar = ArchitectureToolbar.new()
	_arch_toolbar.name = "ArchitectureViewToolbar"
	if left_node is PanelContainer:
		var inner_vbox := VBoxContainer.new()
		inner_vbox.name = "LeftArchitectureVBox"
		inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var existing_children: Array[Node] = []
		for ch in left_node.get_children():
			existing_children.append(ch)
		for ch in existing_children:
			left_node.remove_child(ch)
		left_node.add_child(inner_vbox)
		inner_vbox.add_child(_arch_toolbar)
		for ch in existing_children:
			if ch is Control:
				(ch as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
			inner_vbox.add_child(ch)

		_diagram_host = Control.new()
		_diagram_host.name = "Arch3DHostOverlay"
		_diagram_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_diagram_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_diagram_host.visible = false
		_diagram_host.mouse_filter = Control.MOUSE_FILTER_PASS
		inner_vbox.add_child(_diagram_host)

		_arch_controller = ArchitectureController.new()
		_diagram_host.add_child(_arch_controller)
		var view_3d := _arch_controller.build_3d_layer(_diagram_host)
		view_3d.mouse_filter = Control.MOUSE_FILTER_PASS

		_arch_toolbar.view_mode_changed.connect(func(is_3d: bool) -> void:
			_diagram_host.visible = is_3d
			if get_child_count() > 1 and get_child(1) is CanvasItem:
				(get_child(1) as CanvasItem).visible = not is_3d
			if _arch_controller != null:
				_arch_controller.set_active(is_3d)
			for ch in existing_children:
				if ch is CanvasItem:
					(ch as CanvasItem).visible = not is_3d
		)
		_arch_toolbar.signal_flow_toggled.connect(func(vis: bool) -> void:
			if _arch_controller != null:
				_arch_controller.set_signal_flow_visible(vis)
		)
		_arch_toolbar.explosion_changed.connect(func(factor: float) -> void:
			if _arch_controller != null:
				_arch_controller.set_explosion_factor(factor)
		)
		_arch_toolbar.render_style_changed.connect(func(is_bp: bool) -> void:
			if _arch_controller != null:
				_arch_controller.set_render_style(is_bp)
		)
		_arch_toolbar.camera_preset_selected.connect(func(preset_key: String) -> void:
			if _arch_controller != null:
				_arch_controller.set_camera_preset(preset_key)
		)
		_arch_toolbar.callouts_toggled.connect(func(vis: bool) -> void:
			if _arch_controller != null:
				_arch_controller.set_callouts_visible(vis)
		)
		_arch_toolbar.guides_toggled.connect(func(vis: bool) -> void:
			if _arch_controller != null:
				_arch_controller.set_guides_visible(vis)
		)
		_arch_toolbar.isolate_toggled.connect(func(iso: bool) -> void:
			if _arch_controller != null:
				_arch_controller.set_isolate_selected(iso)
		)
		_arch_toolbar.drawer_toggled.connect(func(vis: bool) -> void:
			if _arch_controller != null:
				_arch_controller.set_drawer_visible(vis)
		)
		_arch_controller.drawer_visibility_changed.connect(func(vis: bool) -> void:
			if _arch_toolbar != null and _arch_toolbar.btn_drawer != null:
				_arch_toolbar.btn_drawer.set_pressed_no_signal(vis)
		)
		_arch_toolbar.shell_toggled.connect(func(show_shell: bool) -> void:
			if _arch_controller != null:
				_arch_controller.set_ghost_shell_visible(show_shell)
		)
		_arch_toolbar.reset_camera_requested.connect(func() -> void:
			if _arch_controller != null:
				_arch_controller.reset_camera()
		)
