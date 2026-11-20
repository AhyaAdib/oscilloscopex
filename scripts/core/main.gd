extends Control

var _canvas: WaveformCanvas
var _animate_check: CheckButton

func _ready() -> void:
	print("[Oscilloscope Lab] Milestone 1 Boot | Renderer: ", RenderingServer.get_video_adapter_name())
	_build_ui()

func _process(delta: float) -> void:
	if _animate_check != null and _animate_check.button_pressed:
		SimState.advance_time(delta)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(root_vbox)

	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "OSCILLOSCOPE LAB  //  MILESTONE 1: FUNCTION GENERATOR & DISPLAY"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.25, 0.95, 0.60, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_animate_check = CheckButton.new()
	_animate_check.text = "Free-Run Sweep"
	_animate_check.button_pressed = false
	header.add_child(_animate_check)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	root_vbox.add_child(split)

	_canvas = WaveformCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(_canvas)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	split.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 14)
	panel_margin.add_theme_constant_override("margin_right", 14)
	panel_margin.add_theme_constant_override("margin_top", 12)
	panel_margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(panel_margin)

	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	panel_margin.add_child(controls)

	var sec_sig := Label.new()
	sec_sig.text = "SIGNAL GENERATOR"
	sec_sig.add_theme_font_size_override("font_size", 15)
	sec_sig.add_theme_color_override("font_color", Color(0.45, 0.80, 1.0, 1.0))
	controls.add_child(sec_sig)

	var wf_row := HBoxContainer.new()
	controls.add_child(wf_row)
	var wf_lbl := Label.new()
	wf_lbl.text = "Waveform"
	wf_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wf_row.add_child(wf_lbl)

	var wf_opt := OptionButton.new()
	for wf_name in SignalGenerator.WAVEFORM_NAMES:
		wf_opt.add_item(wf_name)
	wf_opt.item_selected.connect(func(idx: int) -> void:
		SimState.set_signal_param("waveform", idx)
	)
	wf_row.add_child(wf_opt)

	_add_slider_control(controls, "Amplitude (Vpk)", 0.1, 10.0, 0.1, 2.0, "amplitude")
	_add_slider_control(controls, "Frequency (Hz)", 100.0, 5000.0, 50.0, 1000.0, "frequency")
	_add_slider_control(controls, "Phase (deg)", -180.0, 180.0, 5.0, 0.0, "phase_deg")
	_add_slider_control(controls, "DC Offset (V)", -4.0, 4.0, 0.1, 0.0, "dc_offset")
	_add_slider_control(controls, "Duty Cycle", 0.05, 0.95, 0.05, 0.50, "duty_cycle")
	_add_slider_control(controls, "Noise RMS (V)", 0.0, 1.0, 0.02, 0.0, "noise_rms")

	var sep := HSeparator.new()
	controls.add_child(sep)

	var sec_disp := Label.new()
	sec_disp.text = "DISPLAY SCALE"
	sec_disp.add_theme_font_size_override("font_size", 15)
	sec_disp.add_theme_color_override("font_color", Color(0.45, 0.80, 1.0, 1.0))
	controls.add_child(sec_disp)

	_add_view_slider(controls, "Volts / Div (V)", 0.2, 5.0, 0.2, 1.0, "volts_per_div")
	_add_view_slider(controls, "Time / Div (ms)", 0.1, 5.0, 0.1, 0.5, "time_per_div", 0.001)

func _add_slider_control(parent: Control, label_text: String, min_v: float, max_v: float, step_v: float, init_v: float, key: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	top.add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.text = "%.2f" % init_v
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", Color(0.25, 0.95, 0.60, 1.0))
	top.add_child(val_lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = init_v
	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = "%.2f" % v
		SimState.set_signal_param(key, v)
	)
	box.add_child(slider)

func _add_view_slider(parent: Control, label_text: String, min_v: float, max_v: float, step_v: float, init_v: float, key: String, scale_factor: float = 1.0) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	top.add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.text = "%.2f" % init_v
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.35, 1.0))
	top.add_child(val_lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = init_v
	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = "%.2f" % v
		SimState.set_view_param(key, v * scale_factor)
	)
	box.add_child(slider)
