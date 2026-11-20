
extends Control

var _canvas: WaveformCanvas
var _animate_check: CheckButton
var _power_led: ColorRect

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
	print("[Oscilloscope Lab] National VP-5231A Chassis Boot | Renderer: ", RenderingServer.get_video_adapter_name())
	_build_vp5231a_chassis()

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

func _build_vp5231a_chassis() -> void:
	# Dark lab bench background
	var bench := ColorRect.new()
	bench.color = Color(0.10, 0.11, 0.13, 1.0)
	bench.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bench)

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 18)
	outer_margin.add_theme_constant_override("margin_right", 18)
	outer_margin.add_theme_constant_override("margin_top", 14)
	outer_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(outer_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	outer_margin.add_child(root_vbox)

	# Outer Metallic Oscilloscope Casing
	var casing := PanelContainer.new()
	casing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	casing.add_theme_stylebox_override("panel", _make_panel_style(CHASSIS_GREY, CHASSIS_DARK, 4, 6))
	root_vbox.add_child(casing)

	var casing_pad := MarginContainer.new()
	casing_pad.add_theme_constant_override("margin_left", 12)
	casing_pad.add_theme_constant_override("margin_right", 12)
	casing_pad.add_theme_constant_override("margin_top", 10)
	casing_pad.add_theme_constant_override("margin_bottom", 10)
	casing.add_child(casing_pad)

	var face_hbox := HBoxContainer.new()
	face_hbox.add_theme_constant_override("separation", 12)
	casing_pad.add_child(face_hbox)

	# ==================== LEFT COLUMN: CRT BEZEL + POWER/BEAM STRIP ====================
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.15
	left_col.add_theme_constant_override("separation", 8)
	face_hbox.add_child(left_col)

	# Cream Bezel Frame
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

	# Top Badge: National | OSCILLOSCOPE VP-5231A [30]
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

	# Cyan-Blue CRT Display
	_canvas = WaveformCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bezel_vbox.add_child(_canvas)

	# Bottom Strip: POWER + INTENSITY + FOCUS + SCALE ILLUM
	var bottom_strip := PanelContainer.new()
	bottom_strip.add_theme_stylebox_override("panel", _make_panel_style(Color(0.73, 0.71, 0.68, 1.0), Color(0.45, 0.44, 0.42, 1.0), 1, 3))
	left_col.add_child(bottom_strip)

	var strip_hbox := HBoxContainer.new()
	strip_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_strip.add_child(strip_hbox)

	# Power Button + Pilot Lamp
	var pwr_box := VBoxContainer.new()
	pwr_box.alignment = BoxContainer.ALIGNMENT_CENTER
	strip_hbox.add_child(pwr_box)

	var pwr_lbl := _silk_label("POWER", 10)
	pwr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pwr_box.add_child(pwr_lbl)

	var pwr_btn := Button.new()
	pwr_btn.text = "ON / OFF"
	pwr_btn.toggle_mode = true
	pwr_btn.button_pressed = true
	pwr_btn.toggled.connect(func(on: bool) -> void:
		SimState.set_view_param("power_on", on)
		_power_led.color = Color(1.0, 0.58, 0.12, 1.0) if on else Color(0.28, 0.20, 0.15, 1.0)
	)
	pwr_box.add_child(pwr_btn)

	_power_led = ColorRect.new()
	_power_led.custom_minimum_size = Vector2(14, 14)
	_power_led.color = Color(1.0, 0.58, 0.12, 1.0)
	_power_led.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pwr_box.add_child(_power_led)

	_add_knob(strip_hbox, "INTENSITY", 0.1, 1.0, 0.05, 0.85, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		SimState.set_analog_param("intensity", v)
	)
	_add_knob(strip_hbox, "FOCUS", 0.1, 1.0, 0.05, 0.88, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		SimState.set_analog_param("focus", v)
	)
	_add_knob(strip_hbox, "SCALE ILLUM", 0.0, 1.0, 0.05, 0.65, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		SimState.set_analog_param("scale_illum", v)
	)

	# ==================== RIGHT COLUMN: ANALOG CONTROL PANEL ====================
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.0
	right_col.add_theme_constant_override("separation", 8)
	face_hbox.add_child(right_col)

	# Top Row: TRIGGER + HORIZONTAL TIME/DIV
	var top_controls := HBoxContainer.new()
	top_controls.add_theme_constant_override("separation", 8)
	right_col.add_child(top_controls)

	var trig_box := _make_section_box(top_controls, "TRIGGER")
	var trig_row := HBoxContainer.new()
	trig_row.alignment = BoxContainer.ALIGNMENT_CENTER
	trig_box.add_child(trig_row)

	_add_knob(trig_row, "LEVEL", -4.0, 4.0, 0.1, 0.0, Color(0.76, 0.72, 0.64, 1.0), [], func(v: float) -> void:
		SimState.set_analog_param("trigger_level", v)
	)

	var slope_col := VBoxContainer.new()
	slope_col.alignment = BoxContainer.ALIGNMENT_CENTER
	trig_row.add_child(slope_col)
	slope_col.add_child(_silk_label("SLOPE", 10))
	var slope_opt := OptionButton.new()
	slope_opt.add_item("+ RISING")
	slope_opt.add_item("- FALLING")
	slope_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_analog_param("trigger_slope", idx)
	)
	slope_col.add_child(slope_opt)

	var time_box := _make_section_box(top_controls, "HORIZONTAL  /  TIME/DIV")
	var time_row := HBoxContainer.new()
	time_row.alignment = BoxContainer.ALIGNMENT_CENTER
	time_box.add_child(time_row)

	_add_knob(time_row, "TIME/DIV", 0.0, float(TIME_STEPS.size() - 1), 1.0, 2.0, Color(0.22, 0.21, 0.20, 1.0), TIME_LABELS, func(v: float) -> void:
		var idx := clampi(int(round(v)), 0, TIME_STEPS.size() - 1)
		SimState.set_view_param("time_per_div", TIME_STEPS[idx])
	)
	_add_knob(time_row, "POSITION", -5.0, 5.0, 0.2, 0.0, Color(0.76, 0.72, 0.64, 1.0), [], func(v: float) -> void:
		SimState.set_analog_param("horiz_pos_div", v)
	)

	# Middle Row: VERTICAL CH 1 + PROBE / PHOSPHOR
	var vert_controls := HBoxContainer.new()
	vert_controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vert_controls.add_theme_constant_override("separation", 8)
	right_col.add_child(vert_controls)

	var ch1_box := _make_section_box(vert_controls, "VERTICAL  CH 1  (1MΩ // 25pF)")
	var ch1_knobs := HBoxContainer.new()
	ch1_knobs.alignment = BoxContainer.ALIGNMENT_CENTER
	ch1_box.add_child(ch1_knobs)

	_add_knob(ch1_knobs, "POSITION", -4.0, 4.0, 0.2, 0.0, Color(0.22, 0.21, 0.20, 1.0), [], func(v: float) -> void:
		SimState.set_analog_param("vert_pos_div", v)
	)
	_add_knob(ch1_knobs, "VOLTS/DIV", 0.0, float(VOLTS_STEPS.size() - 1), 1.0, 2.0, Color(0.68, 0.22, 0.20, 1.0), VOLTS_LABELS, func(v: float) -> void:
		var idx := clampi(int(round(v)), 0, VOLTS_STEPS.size() - 1)
		SimState.set_view_param("volts_per_div", VOLTS_STEPS[idx])
	)

	# AC - GND - DC Slide Selector Bar
	var coup_row := HBoxContainer.new()
	coup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coup_row.add_theme_constant_override("separation", 6)
	ch1_box.add_child(coup_row)
	coup_row.add_child(_silk_label("INPUT COUPLING:", 10))
	var coup_opt := OptionButton.new()
	coup_opt.add_item("DC")
	coup_opt.add_item("AC")
	coup_opt.add_item("GND")
	coup_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_analog_param("coupling", idx)
	)
	coup_row.add_child(coup_opt)

	var aux_box := _make_section_box(vert_controls, "PROBE & PHOSPHOR")
	var aux_knobs := HBoxContainer.new()
	aux_knobs.alignment = BoxContainer.ALIGNMENT_CENTER
	aux_box.add_child(aux_knobs)

	_add_knob(aux_knobs, "PERSISTENCE", 0.0, 0.95, 0.05, 0.30, Color(0.76, 0.72, 0.64, 1.0), [], func(v: float) -> void:
		SimState.set_analog_param("persistence", v)
	)

	var probe_col := VBoxContainer.new()
	probe_col.alignment = BoxContainer.ALIGNMENT_CENTER
	aux_knobs.add_child(probe_col)
	probe_col.add_child(_silk_label("PROBE", 10))
	var probe_opt := OptionButton.new()
	probe_opt.add_item("1x")
	probe_opt.add_item("10x")
	probe_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_analog_param("probe_attenuation", 10.0 if idx == 1 else 1.0)
	)
	probe_col.add_child(probe_opt)

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
	gen_title.text = "BENCH FUNCTION GENERATOR:"
	gen_title.add_theme_font_size_override("font_size", 12)
	gen_title.add_theme_color_override("font_color", Color(0.45, 0.90, 0.75, 1.0))
	gen_hbox.add_child(gen_title)

	var wf_opt := OptionButton.new()
	for wf_name in SignalGenerator.WAVEFORM_NAMES:
		wf_opt.add_item(wf_name)
	wf_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_signal_param("waveform", idx)
	)
	gen_hbox.add_child(wf_opt)

	_add_compact_slider(gen_hbox, "Amp (V)", 0.2, 8.0, 0.2, 2.0, func(v: float) -> void:
		SimState.set_signal_param("amplitude", v)
	)
	_add_compact_slider(gen_hbox, "Freq (Hz)", 100.0, 5000.0, 100.0, 1000.0, func(v: float) -> void:
		SimState.set_signal_param("frequency", v)
	)
	_add_compact_slider(gen_hbox, "DC Off (V)", -3.0, 3.0, 0.2, 0.0, func(v: float) -> void:
		SimState.set_signal_param("dc_offset", v)
	)
	_add_compact_slider(gen_hbox, "Noise (V)", 0.0, 0.6, 0.05, 0.0, func(v: float) -> void:
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

func _add_knob(parent: Control, label_txt: String, min_v: float, max_v: float, step_v: float, init_v: float, cap_col: Color, labels: Array[String], cb: Callable) -> void:
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

func _add_compact_slider(parent: Control, name_txt: String, min_v: float, max_v: float, step_v: float, init_v: float, cb: Callable) -> void:
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
