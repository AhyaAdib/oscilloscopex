extends Control

var _canvas: WaveformCanvas
var _animate_check: CheckButton
var _power_led: ColorRect
var _pwr_btn: Button
var _workbench_3d: Workbench3D
var _instrument_view: Control
var _circuit_view: AnalogCircuitExplorer
var _challenge_view: ChallengePanel
var _btn_3d_mode: Button
var _btn_inst_mode: Button
var _btn_arch_mode: Button
var _btn_chal_mode: Button
var _popup_panel: PanelContainer
var _popup_timer_lbl: Label
var _popup_desc_lbl: Label
var _popup_vpp: SpinBox
var _popup_freq: SpinBox
var _popup_off: SpinBox
var _popup_res_lbl: Label

# Two-way synced 2D controls
var _knobs_2d := {}
var _slope_opt: OptionButton
var _coup_opt: OptionButton
var _probe_opt: OptionButton
var _wf_opt: OptionButton
var _gen_sliders := {}
var _syncing_ui := false

const CHASSIS_GREY := Color(0.77, 0.75, 0.72, 1.0)
const CHASSIS_DARK := Color(0.24, 0.23, 0.22, 1.0)
const BEZEL_CREAM := Color(0.85, 0.79, 0.69, 1.0)
const BEZEL_INNER := Color(0.68, 0.62, 0.53, 1.0)
const SILKSCREEN_INK := Color(0.14, 0.14, 0.13, 1.0)

const VOLTS_STEPS := [0.2, 0.5, 1.0, 2.0, 5.0]
const VOLTS_LABELS: Array[String] = ["0.2V", "0.5V", "1V", "2V", "5V"]
const TIME_STEPS := [0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005]
const TIME_LABELS: Array[String] = ["0.1ms", "0.2ms", "0.5ms", "1ms", "2ms", "5ms"]

func _ready() -> void:
	print("[Oscilloscope Lab] Milestone 4/5 Synced Boot | Renderer: ", RenderingServer.get_video_adapter_name())
	_build_workspace()
	SimState.state_updated.connect(func(_dt := 0.0): _sync_selector_states())
	SimState.state_updated.connect(_sync_2d_from_state)
	_sync_2d_from_state()

func _process(delta: float) -> void:
	if _animate_check != null and _animate_check.button_pressed:
		SimState.advance_time(delta)

func _make_panel_style(bg: Color, border: Color, border_w := 2, radius := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	return sb

func _set_active_mode(mode_idx: int) -> void:
	var views: Array[Control] = [_workbench_3d, _instrument_view, _circuit_view, _challenge_view]
	for i in range(views.size()):
		var v := views[i]
		var active := (i == mode_idx)
		v.visible = active
		if active:
			v.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(v, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_btn_3d_mode.button_pressed = (mode_idx == 0)
	_btn_inst_mode.button_pressed = (mode_idx == 1)
	_btn_arch_mode.button_pressed = (mode_idx == 2)
	_btn_chal_mode.button_pressed = (mode_idx == 3)

func _sync_2d_from_state() -> void:
	if _syncing_ui:
		return
	_syncing_ui = true

	var on: bool = bool(SimState.view_config.get("power_on", true))
	if _pwr_btn != null:
		_pwr_btn.set_pressed_no_signal(on)
	if _power_led != null:
		_power_led.color = Color(1.0, 0.58, 0.12, 1.0) if on else Color(0.28, 0.20, 0.15, 1.0)

	# Sync Analog Knobs
	for key in ["intensity", "focus", "scale_illum", "trigger_level", "horiz_pos_div", "vert_pos_div", "persistence"]:
		if _knobs_2d.has(key):
			_knobs_2d[key].value = float(SimState.analog_config[key])

	# Sync Discrete Stepped Knobs (VOLTS/DIV and TIME/DIV)
	if _knobs_2d.has("volts_per_div"):
		var v_cur: float = float(SimState.view_config["volts_per_div"])
		var best_v := 2
		for i in range(VOLTS_STEPS.size()):
			if absf(VOLTS_STEPS[i] - v_cur) < 1e-4:
				best_v = i
				break
		_knobs_2d["volts_per_div"].value = float(best_v)

	if _knobs_2d.has("time_per_div"):
		var t_cur: float = float(SimState.view_config["time_per_div"])
		var best_t := 2
		for i in range(TIME_STEPS.size()):
			if absf(TIME_STEPS[i] - t_cur) < 1e-6:
				best_t = i
				break
		_knobs_2d["time_per_div"].value = float(best_t)

	# Sync OptionButtons
	if _slope_opt != null:
		_slope_opt.selected = int(SimState.analog_config["trigger_slope"])
	if _coup_opt != null:
		_coup_opt.selected = int(SimState.analog_config["coupling"])
	if _probe_opt != null:
		_probe_opt.selected = 1 if float(SimState.analog_config["probe_attenuation"]) > 1.5 else 0
	if _wf_opt != null:
		_wf_opt.selected = int(SimState.signal_params["waveform"])

	# Sync Bottom Function Generator Sliders
	for s_key in _gen_sliders.keys():
		var entry: Dictionary = _gen_sliders[s_key]
		var val: float = float(SimState.signal_params[s_key])
		var slider: HSlider = entry["slider"]
		var lbl: Label = entry["label"]
		slider.set_value_no_signal(val)
		lbl.text = "%.1f" % val

	_syncing_ui = false

func _build_workspace() -> void:
	var bench := ColorRect.new()
	bench.color = Color(0.09, 0.10, 0.12, 1.0)
	bench.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bench)

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 14)
	outer_margin.add_theme_constant_override("margin_right", 14)
	outer_margin.add_theme_constant_override("margin_top", 10)
	outer_margin.add_theme_constant_override("margin_bottom", 12)
	add_child(outer_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	outer_margin.add_child(root_vbox)

	# ==================== TOP MODE NAVIGATION BAR ====================
	var nav_bar := HBoxContainer.new()
	nav_bar.add_theme_constant_override("separation", 8)
	root_vbox.add_child(nav_bar)

	var app_title := Label.new()
	app_title.text = "OSCILLOSCOPE LAB  //  NATIONAL VP-5231A"
	app_title.add_theme_font_size_override("font_size", 15)
	app_title.add_theme_color_override("font_color", Color(0.35, 0.96, 0.72, 1.0))
	app_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_bar.add_child(app_title)

	var mode_opt := OptionButton.new()
	mode_opt.add_item("Mode: Normal Sandbox")
	mode_opt.add_item("Mode: Calibration Test (Scrambled)")
	mode_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_lab_mode("CALIBRATION" if idx == 1 else "NORMAL")
	)
	nav_bar.add_child(mode_opt)

	var theme_opt := OptionButton.new()
	for t_cfg in LabEnvironmentBuilder.LAB_THEMES:
		theme_opt.add_item(t_cfg["name"])
	theme_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_lab_theme(idx)
	)
	nav_bar.add_child(theme_opt)

	_btn_3d_mode = Button.new()
	_btn_3d_mode.text = " [1] 3D Lab Workbench "
	_btn_3d_mode.toggle_mode = true
	_btn_3d_mode.button_pressed = true
	_btn_3d_mode.pressed.connect(func() -> void: _set_active_mode(0))
	nav_bar.add_child(_btn_3d_mode)

	_btn_inst_mode = Button.new()
	_btn_inst_mode.text = " [2] 2D Front Panel "
	_btn_inst_mode.toggle_mode = true
	_btn_inst_mode.button_pressed = false
	_btn_inst_mode.pressed.connect(func() -> void: _set_active_mode(1))
	nav_bar.add_child(_btn_inst_mode)

	_btn_arch_mode = Button.new()
	_btn_arch_mode.text = " [3] Internal Architecture "
	_btn_arch_mode.toggle_mode = true
	_btn_arch_mode.button_pressed = false
	_btn_arch_mode.pressed.connect(func() -> void: _set_active_mode(2))
	nav_bar.add_child(_btn_arch_mode)

	_btn_chal_mode = Button.new()
	_btn_chal_mode.text = " [4] Practicum Challenge "
	_btn_chal_mode.toggle_mode = true
	_btn_chal_mode.button_pressed = false
	_btn_chal_mode.pressed.connect(func() -> void: _set_active_mode(3))
	nav_bar.add_child(_btn_chal_mode)

	# ==================== VIEW 1: 3D LAB WORKBENCH ====================
	_workbench_3d = Workbench3D.new()
	_workbench_3d.visible = true
	root_vbox.add_child(_workbench_3d)

	# ==================== VIEW 2: 2D NATIONAL VP-5231A CHASSIS ====================
	var casing := PanelContainer.new()
	casing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	casing.visible = false
	casing.add_theme_stylebox_override("panel", _make_panel_style(CHASSIS_GREY, CHASSIS_DARK, 4, 6))
	root_vbox.add_child(casing)
	_instrument_view = casing

	var casing_pad := MarginContainer.new()
	casing_pad.add_theme_constant_override("margin_left", 12)
	casing_pad.add_theme_constant_override("margin_right", 12)
	casing_pad.add_theme_constant_override("margin_top", 10)
	casing_pad.add_theme_constant_override("margin_bottom", 10)
	casing.add_child(casing_pad)

	var face_hbox := HBoxContainer.new()
	face_hbox.add_theme_constant_override("separation", 12)
	casing_pad.add_child(face_hbox)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.15
	left_col.add_theme_constant_override("separation", 8)
	face_hbox.add_child(left_col)

	var bezel := PanelContainer.new()
	bezel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bezel.add_theme_stylebox_override("panel", _make_panel_style(BEZEL_CREAM, BEZEL_INNER, 3, 6))
	left_col.add_child(bezel)

	var bezel_pad := MarginContainer.new()
	bezel_pad.add_theme_constant_override("margin_left", 16)
	bezel_pad.add_theme_constant_override("margin_right", 16)
	bezel_pad.add_theme_constant_override("margin_top", 8)
	bezel_pad.add_theme_constant_override("margin_bottom", 16)
	bezel.add_child(bezel_pad)

	var bezel_vbox := VBoxContainer.new()
	bezel_vbox.add_theme_constant_override("separation", 6)
	bezel_pad.add_child(bezel_vbox)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _make_panel_style(Color(0.18, 0.17, 0.16, 1.0), Color(0.10, 0.10, 0.10, 1.0), 1, 2))
	bezel_vbox.add_child(badge)

	var badge_hbox := HBoxContainer.new()
	badge.add_child(badge_hbox)

	var brand_lbl := Label.new()
	brand_lbl.text = "  National"
	brand_lbl.add_theme_font_size_override("font_size", 15)
	brand_lbl.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85, 1.0))
	brand_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_hbox.add_child(brand_lbl)

	var model_lbl := Label.new()
	model_lbl.text = "OSCILLOSCOPE  VP-5231A   [ 30 MHz ]  "
	model_lbl.add_theme_font_size_override("font_size", 13)
	model_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.78, 1.0))
	badge_hbox.add_child(model_lbl)

	_canvas = WaveformCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bezel_vbox.add_child(_canvas)

	var bottom_strip := PanelContainer.new()
	bottom_strip.add_theme_stylebox_override("panel", _make_panel_style(Color(0.73, 0.71, 0.68, 1.0), Color(0.45, 0.44, 0.42, 1.0), 1, 3))
	left_col.add_child(bottom_strip)

	var strip_hbox := HBoxContainer.new()
	strip_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_strip.add_child(strip_hbox)

	var pwr_box := VBoxContainer.new()
	pwr_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pwr_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_hbox.add_child(pwr_box)

	var pwr_lbl := _silk_label("POWER", 10)
	pwr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pwr_box.add_child(pwr_lbl)

	_pwr_btn = Button.new()
	_pwr_btn.text = "ON / OFF"
	_pwr_btn.toggle_mode = true
	_pwr_btn.button_pressed = true
	_pwr_btn.toggled.connect(func(on: bool) -> void:
		if not _syncing_ui:
			SimState.set_view_param("power_on", on)
	)
	pwr_box.add_child(_pwr_btn)

	_power_led = ColorRect.new()
	_power_led.custom_minimum_size = Vector2(14, 14)
	_power_led.color = Color(1.0, 0.58, 0.12, 1.0)
	_power_led.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pwr_box.add_child(_power_led)

	_add_knob(strip_hbox, "intensity", "INTENSITY", 0.1, 1.0, 0.05, 0.85, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("intensity", v)
	)
	_add_knob(strip_hbox, "focus", "FOCUS", 0.1, 1.0, 0.05, 0.88, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("focus", v)
	)
	_add_knob(strip_hbox, "scale_illum", "SCALE ILLUM", 0.0, 1.0, 0.05, 0.65, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("scale_illum", v)
	)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.0
	right_col.add_theme_constant_override("separation", 8)
	face_hbox.add_child(right_col)

	var top_controls := HBoxContainer.new()
	top_controls.add_theme_constant_override("separation", 8)
	right_col.add_child(top_controls)

	var trig_box := _make_section_box(top_controls, "TRIGGER")
	var trig_row := HBoxContainer.new()
	trig_row.alignment = BoxContainer.ALIGNMENT_CENTER
	trig_box.add_child(trig_row)

	_add_knob(trig_row, "trigger_level", "LEVEL", -4.0, 4.0, 0.1, 0.0, Color(0.76, 0.72, 0.64, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("trigger_level", v)
	)
	_add_knob(trig_row, "probe_compensation", "PROBE COMP", 0.65, 1.35, 0.01, 1.0, Color(0.76, 0.72, 0.64, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("probe_compensation", v)
	)

	var slope_col := VBoxContainer.new()
	slope_col.alignment = BoxContainer.ALIGNMENT_CENTER
	slope_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trig_row.add_child(slope_col)
	slope_col.add_child(_silk_label("SLOPE", 10))
	_slope_opt = OptionButton.new()
	_slope_opt.add_item("+ RISING")
	_slope_opt.add_item("- FALLING")
	_slope_opt.item_selected.connect(func(idx: int) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("trigger_slope", idx)
	)
	slope_col.add_child(_slope_opt)

	var time_box := _make_section_box(top_controls, "HORIZONTAL  /  TIME/DIV")
	var time_row := HBoxContainer.new()
	time_row.alignment = BoxContainer.ALIGNMENT_CENTER
	time_box.add_child(time_row)

	_add_knob(time_row, "time_per_div", "TIME/DIV", 0.0, float(TIME_STEPS.size() - 1), 1.0, 2.0, Color(0.22, 0.21, 0.20, 1.0), TIME_LABELS, func(v: float) -> void:
		if not _syncing_ui:
			var idx := clampi(int(round(v)), 0, TIME_STEPS.size() - 1)
			SimState.set_view_param("time_per_div", TIME_STEPS[idx])
	)
	_add_knob(time_row, "horiz_pos_div", "POSITION", -5.0, 5.0, 0.2, 0.0, Color(0.76, 0.72, 0.64, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("horiz_pos_div", v)
	)

	var vert_controls := HBoxContainer.new()
	vert_controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vert_controls.add_theme_constant_override("separation", 8)
	right_col.add_child(vert_controls)

	var ch1_box := _make_section_box(vert_controls, "VERTICAL  CH 1  (1MΩ // 25pF)")
	var ch1_knobs := HBoxContainer.new()
	ch1_knobs.alignment = BoxContainer.ALIGNMENT_CENTER
	ch1_box.add_child(ch1_knobs)

	_add_knob(ch1_knobs, "vert_pos_div", "POSITION", -4.0, 4.0, 0.2, 0.0, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("vert_pos_div", v)
	)
	_add_knob(ch1_knobs, "volts_per_div", "VOLTS/DIV", 0.0, float(VOLTS_STEPS.size() - 1), 1.0, 2.0, Color(0.68, 0.22, 0.20, 1.0), VOLTS_LABELS, func(v: float) -> void:
		if not _syncing_ui:
			var idx := clampi(int(round(v)), 0, VOLTS_STEPS.size() - 1)
			SimState.set_view_param("volts_per_div", VOLTS_STEPS[idx])
	)

	var coup_row := HBoxContainer.new()
	coup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coup_row.add_theme_constant_override("separation", 6)
	ch1_box.add_child(coup_row)
	coup_row.add_child(_silk_label("INPUT COUPLING:", 10))
	_coup_opt = OptionButton.new()
	_coup_opt.add_item("DC")
	_coup_opt.add_item("AC")
	_coup_opt.add_item("GND")
	_coup_opt.item_selected.connect(func(idx: int) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("coupling", idx)
	)
	coup_row.add_child(_coup_opt)

	var aux_box := _make_section_box(vert_controls, "PROBE & PHOSPHOR")
	var aux_knobs := HBoxContainer.new()
	aux_knobs.alignment = BoxContainer.ALIGNMENT_CENTER
	aux_box.add_child(aux_knobs)

	_add_knob(aux_knobs, "persistence", "PERSISTENCE", 0.0, 0.95, 0.05, 0.30, Color(0.76, 0.72, 0.64, 1.0), [], func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("persistence", v)
	)

	var probe_col := VBoxContainer.new()
	probe_col.alignment = BoxContainer.ALIGNMENT_CENTER
	probe_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aux_knobs.add_child(probe_col)
	probe_col.add_child(_silk_label("PROBE", 10))
	_probe_opt = OptionButton.new()
	_probe_opt.add_item("1x")
	_probe_opt.add_item("10x")
	_probe_opt.item_selected.connect(func(idx: int) -> void:
		if not _syncing_ui:
			SimState.set_analog_param("probe_attenuation", 10.0 if idx == 1 else 1.0)
	)
	probe_col.add_child(_probe_opt)

	# ==================== VIEW 3: ANALOG INTERNAL ARCHITECTURE EXPLORER ====================
	_circuit_view = AnalogCircuitExplorer.new()
	_circuit_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_circuit_view.visible = false
	root_vbox.add_child(_circuit_view)

	_challenge_view = ChallengePanel.new()
	_challenge_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_challenge_view.visible = false
	_challenge_view.jump_to_3d_requested.connect(func() -> void: _set_active_mode(0))
	_challenge_view.mission_started.connect(func(m: Dictionary) -> void:
		_set_active_mode(0)
	)
	root_vbox.add_child(_challenge_view)

	# ==================== BOTTOM BENCH BAR: FUNCTION GENERATOR SOURCE ====================
	var gen_bar := PanelContainer.new()
	gen_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.15, 0.17, 0.20, 1.0), Color(0.30, 0.34, 0.38, 1.0), 1, 4))
	root_vbox.add_child(gen_bar)

	var gen_pad := MarginContainer.new()
	gen_pad.add_theme_constant_override("margin_left", 12)
	gen_pad.add_theme_constant_override("margin_right", 12)
	gen_pad.add_theme_constant_override("margin_top", 6)
	gen_pad.add_theme_constant_override("margin_bottom", 6)
	gen_bar.add_child(gen_pad)

	var gen_hbox := HBoxContainer.new()
	gen_hbox.add_theme_constant_override("separation", 14)
	gen_pad.add_child(gen_hbox)

	var gen_title := Label.new()
	gen_title.text = "SIGLENT SDG1032X:"
	gen_title.add_theme_font_size_override("font_size", 12)
	gen_title.add_theme_color_override("font_color", Color(0.45, 0.90, 0.75, 1.0))
	gen_hbox.add_child(gen_title)

	var fg_ch_opt := OptionButton.new()
	fg_ch_opt.add_item("CH1 Out")
	fg_ch_opt.add_item("CH2 Out")
	fg_ch_opt.item_selected.connect(func(idx: int) -> void:
		SimState.select_fg_channel(idx + 1)
	)
	gen_hbox.add_child(fg_ch_opt)

	var bb_opt := OptionButton.new()
	for m in Breadboard3DBuilder.CIRCUIT_MODELS:
		bb_opt.add_item(m["name"])
	bb_opt.item_selected.connect(func(idx: int) -> void:
		SimState.select_breadboard_model(idx, idx == 3)
	)
	gen_hbox.add_child(bb_opt)

	var board_style_opt := OptionButton.new()
	board_style_opt.add_item("Board: Breadboard")
	board_style_opt.add_item("Board: Green FR-4 PCB")
	board_style_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_board_is_pcb(idx == 1)
	)
	gen_hbox.add_child(board_style_opt)

	SimState.state_updated.connect(func() -> void:
		if bb_opt.selected != SimState.breadboard_model_idx:
			bb_opt.select(SimState.breadboard_model_idx)
		var want_pcb := 1 if SimState.board_is_pcb else 0
		if board_style_opt.selected != want_pcb:
			board_style_opt.select(want_pcb)
	)

	_wf_opt = OptionButton.new()
	for wf_name in SignalGenerator.WAVEFORM_NAMES:
		_wf_opt.add_item(wf_name)
	_wf_opt.item_selected.connect(func(idx: int) -> void:
		if not _syncing_ui:
			SimState.set_signal_param("waveform", idx)
	)
	gen_hbox.add_child(_wf_opt)

	_add_compact_slider(gen_hbox, "amplitude", "Amp (V)", 0.2, 8.0, 0.2, 2.0, func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_signal_param("amplitude", v)
	)
	_add_compact_slider(gen_hbox, "frequency", "Freq (Hz)", 100.0, 5000.0, 100.0, 1000.0, func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_signal_param("frequency", v)
	)
	_add_compact_slider(gen_hbox, "dc_offset", "DC Off (V)", -3.0, 3.0, 0.2, 0.0, func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_signal_param("dc_offset", v)
	)
	_add_compact_slider(gen_hbox, "noise_rms", "Noise (V)", 0.0, 0.6, 0.05, 0.0, func(v: float) -> void:
		if not _syncing_ui:
			SimState.set_signal_param("noise_rms", v)
	)

	_animate_check = CheckButton.new()
	_animate_check.text = "Sweep"
	_animate_check.button_pressed = true
	gen_hbox.add_child(_animate_check)

func _make_section_box(parent: Control, header_text: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.74, 0.72, 0.69, 1.0), Color(0.32, 0.31, 0.30, 1.0), 1, 3))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var lbl := _silk_label(header_text, 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	return vbox

func _silk_label(text: String, font_sz: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", SILKSCREEN_INK)
	return lbl

func _add_knob(parent: Control, param_key: String, label_txt: String, min_v: float, max_v: float, step_v: float, init_v: float, cap_col: Color, labels: Array[String], cb: Callable) -> void:
	var knob := RotaryKnob.new()
	knob.label_text = label_txt
	knob.min_value = min_v
	knob.max_value = max_v
	knob.step = step_v
	knob.value = init_v
	knob.accent_cap_color = cap_col
	knob.discrete_labels = labels
	knob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	knob.value_changed.connect(cb)
	parent.add_child(knob)
	_knobs_2d[param_key] = knob

func _add_compact_slider(parent: Control, param_key: String, name_txt: String, min_v: float, max_v: float, step_v: float, init_v: float, cb: Callable) -> void:
	var box := HBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)

	var lbl := Label.new()
	lbl.text = "%s:" % name_txt
	lbl.add_theme_font_size_override("font_size", 11)
	box.add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.text = "%.1f" % init_v
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.add_theme_color_override("font_color", Color(0.45, 0.95, 0.78, 1.0))
	box.add_child(val_lbl)

	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step_v
	s.value = init_v
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void:
		val_lbl.text = "%.1f" % v
		cb.call(v)
	)
	box.add_child(s)
	_gen_sliders[param_key] = {"slider": s, "label": val_lbl}


func _sync_selector_states() -> void:
	if SimState == null:
		return
	var mode_opt := find_child("ModeOption", true, false) as OptionButton
	if mode_opt:
		mode_opt.select(1 if SimState.app_mode == SimState.AppMode.CALIBRATION else 0)
	var theme_opt := find_child("ThemeOption", true, false) as OptionButton
	if theme_opt:
		for i in range(theme_opt.item_count):
			if theme_opt.get_item_metadata(i) == SimState.lab_theme:
				theme_opt.select(i)
				break
	var fg_ch_opt := find_child("FgChOption", true, false) as OptionButton
	if fg_ch_opt:
		var ch_idx := clampi(int(SimState.fg_active_ch) - 1, 0, fg_ch_opt.item_count - 1)
		fg_ch_opt.select(ch_idx)
