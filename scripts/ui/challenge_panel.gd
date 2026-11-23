class_name ChallengePanel
extends PanelContainer

signal jump_to_3d_requested
signal mission_started(mission: Dictionary)

var _mission_opt: OptionButton
var _start_btn: Button
var _timer_lbl: Label
var _desc_lbl: Label

var _status_routing: Label
var _status_coupling: Label
var _status_trig: Label
var _status_comp: Label

var _in_vpp: SpinBox
var _in_freq: SpinBox
var _in_offset: SpinBox
var _submit_btn: Button
var _result_lbl: RichTextLabel

var active_mission := {}
var is_running := false
var time_remaining := 120.0

func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.13, 1.0)
	sb.border_color = Color(0.25, 0.32, 0.40, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", sb)

	_build_ui()
	_select_mission(0, false)
	if has_node("/root/SimState"):
		SimState.state_updated.connect(_refresh_hardware_status)
	_refresh_hardware_status()
	mission_started.emit(active_mission)

func _process(delta: float) -> void:
	if not is_running:
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	SimState.active_time_remaining = time_remaining
	_update_timer_display()
	if time_remaining <= 0.0:
		is_running = false
		_on_submit_pressed()

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 18)
	margin.add_child(main_hbox)

	# ==================== LEFT COLUMN: LIVE CRT + CALIBRATION AUDIT ====================
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_stretch_ratio = 1.1
	left_vbox.add_theme_constant_override("separation", 10)
	main_hbox.add_child(left_vbox)

	var left_hdr := HBoxContainer.new()
	left_vbox.add_child(left_hdr)

	var crt_title := Label.new()
	crt_title.text = "LIVE CRT GRATICULE MONITOR (COUNT DIVISIONS TO MEASURE)"
	crt_title.add_theme_font_size_override("font_size", 13)
	crt_title.add_theme_color_override("font_color", Color(0.42, 0.95, 0.78, 1.0))
	crt_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_hdr.add_child(crt_title)

	var jump_btn := Button.new()
	jump_btn.text = "Go to 3D Bench (Plug Probes / Turn Knobs) →"
	jump_btn.pressed.connect(func() -> void: jump_to_3d_requested.emit())
	left_hdr.add_child(jump_btn)

	var crt_frame := PanelContainer.new()
	crt_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var crt_sb := StyleBoxFlat.new()
	crt_sb.bg_color = Color(0.03, 0.05, 0.06, 1.0)
	crt_sb.border_color = Color(0.20, 0.45, 0.42, 1.0)
	crt_sb.set_border_width_all(2)
	crt_frame.add_theme_stylebox_override("panel", crt_sb)
	left_vbox.add_child(crt_frame)

	var crt_canvas := WaveformCanvas.new()
	crt_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crt_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crt_frame.add_child(crt_canvas)

	# Hardware Calibration Telemetry Strip
	var cal_box := PanelContainer.new()
	var cal_sb := StyleBoxFlat.new()
	cal_sb.bg_color = Color(0.11, 0.14, 0.18, 1.0)
	cal_sb.border_color = Color(0.28, 0.36, 0.46, 1.0)
	cal_sb.set_border_width_all(1)
	cal_sb.set_corner_radius_all(4)
	cal_box.add_theme_stylebox_override("panel", cal_sb)
	left_vbox.add_child(cal_box)

	var cal_pad := MarginContainer.new()
	cal_pad.add_theme_constant_override("margin_left", 10)
	cal_pad.add_theme_constant_override("margin_right", 10)
	cal_pad.add_theme_constant_override("margin_top", 8)
	cal_pad.add_theme_constant_override("margin_bottom", 8)
	cal_box.add_child(cal_pad)

	var cal_grid := GridContainer.new()
	cal_grid.columns = 2
	cal_grid.add_theme_constant_override("h_separation", 18)
	cal_grid.add_theme_constant_override("v_separation", 6)
	cal_pad.add_child(cal_grid)

	_status_routing = Label.new()
	_status_coupling = Label.new()
	_status_trig = Label.new()
	_status_comp = Label.new()
	for lbl in [_status_routing, _status_coupling, _status_trig, _status_comp]:
		lbl.add_theme_font_size_override("font_size", 12)
		cal_grid.add_child(lbl)

	# ==================== RIGHT COLUMN: TIMER, BRIEFING & PLAYER SUBMISSION ====================
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_stretch_ratio = 1.0
	right_vbox.add_theme_constant_override("separation", 10)
	main_hbox.add_child(right_vbox)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	right_vbox.add_child(top_bar)

	_mission_opt = OptionButton.new()
	_mission_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for m in ChallengeManager.MISSIONS:
		_mission_opt.add_item(m["title"])
	_mission_opt.item_selected.connect(func(idx: int) -> void: _select_mission(idx, false))
	top_bar.add_child(_mission_opt)

	_start_btn = Button.new()
	_start_btn.text = "▶ START MISSION"
	_start_btn.pressed.connect(_on_start_mission)
	top_bar.add_child(_start_btn)

	# Countdown Timer Banner
	var timer_panel := PanelContainer.new()
	var t_sb := StyleBoxFlat.new()
	t_sb.bg_color = Color(0.12, 0.10, 0.08, 1.0)
	t_sb.border_color = Color(1.0, 0.72, 0.22, 0.9)
	t_sb.set_border_width_all(2)
	t_sb.set_corner_radius_all(5)
	timer_panel.add_theme_stylebox_override("panel", t_sb)
	right_vbox.add_child(timer_panel)

	var t_hbox := HBoxContainer.new()
	t_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_panel.add_child(t_hbox)

	_timer_lbl = Label.new()
	_timer_lbl.text = "MISSION TIMER:  02:00  [READY]"
	_timer_lbl.add_theme_font_size_override("font_size", 18)
	_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 1.0))
	t_hbox.add_child(_timer_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.add_theme_font_size_override("font_size", 12)
	_desc_lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.92, 1.0))
	right_vbox.add_child(_desc_lbl)

	# Player Measurement Submission Form
	var form_panel := PanelContainer.new()
	var f_sb := StyleBoxFlat.new()
	f_sb.bg_color = Color(0.11, 0.14, 0.18, 1.0)
	f_sb.border_color = Color(0.30, 0.42, 0.52, 1.0)
	f_sb.set_border_width_all(1)
	f_sb.set_corner_radius_all(5)
	form_panel.add_theme_stylebox_override("panel", f_sb)
	right_vbox.add_child(form_panel)

	var form_pad := MarginContainer.new()
	form_pad.add_theme_constant_override("margin_left", 12)
	form_pad.add_theme_constant_override("margin_right", 12)
	form_pad.add_theme_constant_override("margin_top", 10)
	form_pad.add_theme_constant_override("margin_bottom", 10)
	form_panel.add_child(form_pad)

	var form_vbox := VBoxContainer.new()
	form_vbox.add_theme_constant_override("separation", 8)
	form_pad.add_child(form_vbox)

	var form_hdr := Label.new()
	form_hdr.text = "PLAYER OSCILLOSCOPE READING SUBMISSION"
	form_hdr.add_theme_font_size_override("font_size", 13)
	form_hdr.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0, 1.0))
	form_vbox.add_child(form_hdr)

	var inputs_grid := GridContainer.new()
	inputs_grid.columns = 2
	inputs_grid.add_theme_constant_override("h_separation", 12)
	inputs_grid.add_theme_constant_override("v_separation", 8)
	form_vbox.add_child(inputs_grid)

	_in_vpp = _add_spin_row(inputs_grid, "1. Peak-to-Peak Voltage Vpp (V):", 0.0, 20.0, 0.05, 1.0)
	_in_freq = _add_spin_row(inputs_grid, "2. Signal Frequency f (Hz):", 10.0, 20000.0, 10.0, 1000.0)
	_in_offset = _add_spin_row(inputs_grid, "3. DC Offset Voltage (V):", -10.0, 10.0, 0.05, 0.0)

	_submit_btn = Button.new()
	_submit_btn.text = "✓ SUBMIT CALIBRATION & READINGS FOR GRADING"
	_submit_btn.pressed.connect(_on_submit_pressed)
	form_vbox.add_child(_submit_btn)

	# Graded Report Output
	var rep_panel := PanelContainer.new()
	rep_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var r_sb := StyleBoxFlat.new()
	r_sb.bg_color = Color(0.06, 0.08, 0.10, 1.0)
	r_sb.border_color = Color(0.24, 0.30, 0.38, 1.0)
	r_sb.set_border_width_all(1)
	r_sb.set_corner_radius_all(4)
	rep_panel.add_theme_stylebox_override("panel", r_sb)
	right_vbox.add_child(rep_panel)

	var rep_pad := MarginContainer.new()
	rep_pad.add_theme_constant_override("margin_left", 10)
	rep_pad.add_theme_constant_override("margin_right", 10)
	rep_pad.add_theme_constant_override("margin_top", 8)
	rep_pad.add_theme_constant_override("margin_bottom", 8)
	rep_panel.add_child(rep_pad)

	_result_lbl = RichTextLabel.new()
	_result_lbl.bbcode_enabled = true
	_result_lbl.text = "[color=#9ab0c4]Select a mission and click [b]▶ START MISSION[/b]. The oscilloscope will scramble so you can calibrate it in 3D, measure the waveform on the CRT graticule, and submit your readings here.[/color]"
	rep_pad.add_child(_result_lbl)

func _add_spin_row(grid: GridContainer, label_txt: String, min_v: float, max_v: float, step_v: float, init_v: float) -> SpinBox:
	var lbl := Label.new()
	lbl.text = label_txt
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(lbl)

	var sb := SpinBox.new()
	sb.min_value = min_v
	sb.max_value = max_v
	sb.step = step_v
	sb.value = init_v
	sb.custom_minimum_size = Vector2(130, 0)
	grid.add_child(sb)
	return sb

func _select_mission(idx: int, auto_start: bool) -> void:
	active_mission = ChallengeManager.build_mission_instance(idx)
	time_remaining = float(active_mission["time_limit"])
	is_running = auto_start
	_desc_lbl.text = str(active_mission["description"])
	_update_timer_display()

func _on_start_mission() -> void:
	var idx := _mission_opt.selected
	_select_mission(idx, true)
	SimState.active_challenge_running = true
	SimState.active_mission_data = active_mission
	SimState.active_time_remaining = time_remaining
	SimState.last_mission_report = ""
	SimState.submission_attempts = 0
	SimState.failed_attempts = 0
	SimState.set_lab_mode("CALIBRATION")
	if active_mission.get("randomize_fg", false):
		SimState.select_fg_channel(1)
		SimState.set_signal_param("waveform", int(active_mission["fg_wf"]))
		SimState.set_signal_param("amplitude", float(active_mission["fg_amp"]))
		SimState.set_signal_param("frequency", float(active_mission["true_freq"]))
		SimState.set_signal_param("dc_offset", float(active_mission["true_offset"]))
	_result_lbl.text = "[color=#ffd166]MISSION ACTIVE![/color] Jump to [b][1] 3D Lab Workbench[/b] to plug probes, calibrate the VP-5231A, count CRT divisions, and return here to submit before time runs out."
	_refresh_hardware_status()

func _on_submit_pressed() -> void:
	var res := ChallengeManager.evaluate_submission(
		active_mission, _in_vpp.value, _in_freq.value, _in_offset.value, time_remaining
	)
	SimState.submission_attempts += 1
	if not res["passed"]:
		SimState.failed_attempts += 1
	if res["passed"] or time_remaining <= 0.0:
		is_running = false
		SimState.active_challenge_running = false
	_update_timer_display()
	var verdict := "[color=#4ade80][b]PASS — LAB PRACTICUM VERIFIED![/b][/color]" if res["passed"] else "[color=#f87171][b]NEEDS RE-CALIBRATION / RE-MEASUREMENT[/b][/color]"
	var lines: Array[String] = [
		"%s   |   [b]Score: %d / 100[/b] (Cal: %d/50, Reading: %d/50)" % [verdict, res["total_score"], res["cal_score"], res["read_score"]],
		"• Probe Routing: %s   |   DC Coupling: %s   |   Trigger Lock: %s   |   Probe Comp: %s" % [
			"OK" if res["routing_ok"] else "WRONG",
			"OK" if res["coupling_ok"] else "WRONG",
			"LOCKED" if res["trig_ok"] else "UNLOCKED",
			"OK" if res["comp_ok"] else "OFF"
		],
		"• Vpp: submitted [b]%.2f V[/b] vs true [b]%.2f V[/b] (err %.1f%%) — %s" % [_in_vpp.value, res["true_vpp"], res["vpp_err_pct"], "PASS" if res["vpp_ok"] else "FAIL"],
		"• Freq: submitted [b]%.0f Hz[/b] vs true [b]%.0f Hz[/b] (err %.1f%%) — %s" % [_in_freq.value, res["true_freq"], res["freq_err_pct"], "PASS" if res["freq_ok"] else "FAIL"],
		"• Offset: submitted [b]%.2f V[/b] vs true [b]%.2f V[/b] (err %.2f V) — %s" % [_in_offset.value, res["true_offset"], res["off_err_v"], "PASS" if res["off_ok"] else "FAIL"]
	]
	_last_summary = "Score: %d/100 (%s)" % [res["total_score"], "PASS" if res["passed"] else "RETRY"]
	if res["passed"] or time_remaining <= 0.0:
		SimState.last_mission_report = "FINAL: %d/100 (%s) | Attempts: %d (Fails: %d) | True: %.2fVpp, %.0fHz, %.2fV" % [res["total_score"], "PASS" if res["passed"] else "TIME UP", SimState.submission_attempts, SimState.failed_attempts, res["true_vpp"], res["true_freq"], res["true_offset"]]
	else:
		SimState.last_mission_report = "Score: %d/100 — KEEP GOING! | Attempts: %d (Fails: %d) | Route:%s | Comp:%s | Trig:%s | Vpp:%s | Freq:%s" % [res["total_score"], SimState.submission_attempts, SimState.failed_attempts, "OK" if res["routing_ok"] else "NO", "OK" if res["comp_ok"] else "OFF", "OK" if res["trig_ok"] else "NO", "OK" if res["vpp_ok"] else "ERR", "OK" if res["freq_ok"] else "ERR"]
	_result_lbl.text = "\n".join(lines)

func _update_timer_display() -> void:
	var mins := int(time_remaining) / 60
	var secs := int(time_remaining) % 60
	var state_tag := "RUNNING" if is_running else "STOPPED"
	_timer_lbl.text = "MISSION TIMER:  %02d:%02d  [%s]" % [mins, secs, state_tag]
	if time_remaining <= 20.0 and is_running:
		_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.32, 0.30, 1.0))
	else:
		_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 1.0))

func _refresh_hardware_status() -> void:
	if _status_routing == null or not has_node("/root/SimState"):
		return
	var p1_b := str(SimState.analog_config.get("probe1_bnc", "UNPLUGGED"))
	var p1_t := str(SimState.analog_config.get("probe1_tip", "FLOATING"))
	_status_routing.text = "Probe 1 Route: %s → %s" % [p1_b, p1_t]
	_status_routing.add_theme_color_override("font_color", Color(0.45, 0.95, 0.72) if p1_b == "CH1" and p1_t != "FLOATING" else Color(0.95, 0.55, 0.45))

	var coup_names := ["DC", "AC", "GND"]
	var c_idx := int(SimState.analog_config.get("coupling", 0))
	_status_coupling.text = "CH 1 Coupling: %s" % coup_names[clampi(c_idx, 0, 2)]
	_status_coupling.add_theme_color_override("font_color", Color(0.45, 0.95, 0.72) if c_idx == 0 else Color(0.95, 0.78, 0.35))

	_status_trig.text = "Trigger: %s (%.2f V)" % ["LOCKED" if SimState.is_triggered else "UNLOCKED", float(SimState.analog_config["trigger_level"])]
	_status_trig.add_theme_color_override("font_color", Color(0.45, 0.95, 0.72) if SimState.is_triggered else Color(0.95, 0.45, 0.42))

	var comp := float(SimState.analog_config["probe_compensation"])
	var atten := int(round(float(SimState.analog_config["probe_attenuation"])))
	_status_comp.text = "Probe: %dx | Comp: %.2f" % [atten, comp]
	_status_comp.add_theme_color_override("font_color", Color(0.45, 0.95, 0.72) if absf(comp - 1.0) <= 0.07 else Color(0.95, 0.78, 0.35))

var _last_summary := ""

func submit_external(vpp_v: float, freq_hz: float, off_v: float) -> void:
	_in_vpp.value = vpp_v
	_in_freq.value = freq_hz
	_in_offset.value = off_v
	_on_submit_pressed()

func get_last_summary_line() -> String:
	return _last_summary
