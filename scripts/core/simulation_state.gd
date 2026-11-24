extends Node

signal state_updated
signal selected_node_changed(node_id: String)

var lab_mode := "NORMAL" # "NORMAL" or "CALIBRATION"
var fg_selected_channel := 1 # 1 or 2 on Siglent SDG1032X
var breadboard_model_idx := 0
var board_is_pcb := false
var lab_theme_idx := 0
var active_challenge_running := false
var active_mission_data := {}
var active_time_remaining := 0.0
var last_mission_report := ""
var submission_attempts := 0
var failed_attempts := 0
var breadboard_config: Dictionary = Breadboard3DBuilder.CIRCUIT_MODELS[0].duplicate(true)

var fg_channels := {
	1: {
		"enabled": true,
		"waveform": SignalGenerator.WaveformType.SINE,
		"amplitude": 2.0,
		"frequency": 1000.0,
		"phase_deg": 0.0,
		"dc_offset": 0.0,
		"duty_cycle": 0.50,
		"noise_rms": 0.0,
		"noise_seed": 1337
	},
	2: {
		"enabled": true,
		"waveform": SignalGenerator.WaveformType.SQUARE,
		"amplitude": 1.5,
		"frequency": 2000.0,
		"phase_deg": 0.0,
		"dc_offset": 0.0,
		"duty_cycle": 0.50,
		"noise_rms": 0.0,
		"noise_seed": 2027
	}
}

# Alias pointing to currently selected generator channel for compatibility
var signal_params: Dictionary:
	get:
		return fg_channels[fg_selected_channel]

var view_config := {
	"volts_per_div": 1.0,
	"ch2_volts_per_div": 1.0,
	"time_per_div": 0.0005,
	"sample_count": 1024,
	"running": true,
	"power_on": true
}

var analog_config := {
	"vert_mode": 1,             # 0 = CH1, 1 = ALT (CH1 + CH2), 2 = CH2
	"coupling": AnalogScopeEngine.CouplingMode.DC,
	"ch2_coupling": AnalogScopeEngine.CouplingMode.DC,
	"probe_attenuation": 1.0,
	"probe2_attenuation": 1.0,
	"psu_power_on": true,
	"psu_voltage_coarse": 12.0,
	"psu_voltage_fine": 0.0,
	"psu_current_limit": 1.5,
	"probe_compensation": 1.0,
	"probe1_bnc": "CH1",
	"probe1_tip": "FG_CH1",
	"probe2_bnc": "CH2",
	"probe2_tip": "FG_CH2",
	"vert_pos_div": 0.0,
	"ch2_vert_pos_div": 0.0,
	"horiz_pos_div": 0.0,
	"trigger_level": 0.0,
	"trigger_slope": AnalogScopeEngine.TriggerSlope.RISING,
	"trigger_hysteresis": 0.05,
	"intensity": 0.85,
	"focus": 0.88,
	"scale_illum": 0.65,
	"persistence": 0.30
}

var raw_time_buffer := PackedFloat64Array()
var raw_voltage_buffer := PackedFloat64Array()
var analog_nodes := {}
var selected_circuit_node := "N3_ATTENUATOR"

var time_buffer := PackedFloat64Array()
var voltage_buffer := PackedFloat64Array()
var ch2_voltage_buffer := PackedFloat64Array()
var is_triggered := false
var sim_time_offset := 0.0

func _ready() -> void:
	set_lab_mode("NORMAL")

func select_fg_channel(ch: int) -> void:
	fg_selected_channel = 1 if ch != 2 else 2
	state_updated.emit()

func set_lab_theme(idx: int) -> void:
	lab_theme_idx = clampi(idx, 0, LabEnvironmentBuilder.LAB_THEMES.size() - 1)
	state_updated.emit()

func set_board_is_pcb(is_pcb: bool) -> void:
	board_is_pcb = is_pcb
	state_updated.emit()

func select_breadboard_model(idx: int, randomize_proc := false) -> void:
	breadboard_model_idx = clampi(idx, 0, Breadboard3DBuilder.CIRCUIT_MODELS.size() - 1)
	breadboard_config = Breadboard3DBuilder.CIRCUIT_MODELS[breadboard_model_idx].duplicate(true)
	if randomize_proc or breadboard_config.get("id") == "PROCEDURAL_MIX":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var r_list := [470.0, 1000.0, 2200.0, 4700.0]
		var c_list := [22e-9, 47e-9, 100e-9, 220e-9]
		var f_list := [500.0, 1000.0, 1500.0, 2500.0]
		var a_list := [1.5, 2.0, 2.5, 3.0]
		breadboard_config["r_ohm"] = r_list[rng.randi_range(0, r_list.size() - 1)]
		breadboard_config["c_farad"] = c_list[rng.randi_range(0, c_list.size() - 1)]
		breadboard_config["freq_hz"] = f_list[rng.randi_range(0, f_list.size() - 1)]
		breadboard_config["v_in_amp"] = a_list[rng.randi_range(0, a_list.size() - 1)]
	if str(analog_config.get("probe1_tip", "")) in ["FG_CH1", "FLOATING"]:
		analog_config["probe1_bnc"] = "CH1"
		analog_config["probe1_tip"] = "BB_TP1"
	if str(analog_config.get("probe2_tip", "")) in ["FG_CH2", "FLOATING"]:
		analog_config["probe2_bnc"] = "CH2"
		analog_config["probe2_tip"] = "BB_TP2"
	recompute()

func set_lab_mode(mode_name: String) -> void:
	lab_mode = mode_name
	if mode_name == "CALIBRATION":
		view_config["power_on"] = true
		view_config["volts_per_div"] = 5.0
		view_config["ch2_volts_per_div"] = 5.0
		view_config["time_per_div"] = 0.005
		analog_config["vert_mode"] = 0
		analog_config["coupling"] = AnalogScopeEngine.CouplingMode.GND
		analog_config["ch2_coupling"] = AnalogScopeEngine.CouplingMode.GND
		analog_config["probe_attenuation"] = 1.0
		analog_config["probe_compensation"] = 0.65
		analog_config["probe1_bnc"] = "UNPLUGGED"
		analog_config["probe1_tip"] = "FLOATING"
		analog_config["probe2_bnc"] = "UNPLUGGED"
		analog_config["probe2_tip"] = "FLOATING"
		analog_config["vert_pos_div"] = 3.2
		analog_config["ch2_vert_pos_div"] = -3.0
		analog_config["horiz_pos_div"] = -3.5
		analog_config["trigger_level"] = 3.6
		analog_config["intensity"] = 0.45
		analog_config["focus"] = 0.40
	else:
		view_config["power_on"] = true
		view_config["volts_per_div"] = 1.0
		view_config["ch2_volts_per_div"] = 1.0
		view_config["time_per_div"] = 0.0005
		analog_config["vert_mode"] = 1 # ALT (Both CH1 & CH2 active)
		analog_config["coupling"] = AnalogScopeEngine.CouplingMode.DC
		analog_config["ch2_coupling"] = AnalogScopeEngine.CouplingMode.DC
		analog_config["probe_attenuation"] = 1.0
		analog_config["probe_compensation"] = 1.0
		analog_config["probe1_bnc"] = "CH1"
		analog_config["probe1_tip"] = "FG_CH1"
		analog_config["probe2_bnc"] = "CH2"
		analog_config["probe2_tip"] = "FG_CH2"
		analog_config["vert_pos_div"] = 1.2
		analog_config["ch2_vert_pos_div"] = -1.5
		analog_config["horiz_pos_div"] = 0.0
		analog_config["trigger_level"] = 0.0
		analog_config["intensity"] = 0.85
		analog_config["focus"] = 0.88
	recompute()

func set_signal_param(key: String, value: Variant) -> void:
	var ch_dict: Dictionary = fg_channels[fg_selected_channel]
	if ch_dict.get(key) == value:
		return
	ch_dict[key] = value
	recompute()

func set_view_param(key: String, value: Variant) -> void:
	if view_config.get(key) == value:
		return
	view_config[key] = value
	recompute()

func set_analog_param(key: String, value: Variant) -> void:
	if analog_config.get(key) == value:
		return
	analog_config[key] = value
	recompute()

func select_circuit_node(node_id: String) -> void:
	if selected_circuit_node == node_id:
		return
	selected_circuit_node = node_id
	selected_node_changed.emit(node_id)
	state_updated.emit()

func advance_time(delta: float) -> void:
	if not view_config["running"] or not view_config["power_on"]:
		return
	sim_time_offset = fmod(sim_time_offset + delta * 0.05, 10.0)
	recompute()

func _resolve_tip_signal(tip_tgt: String) -> Dictionary:
	if tip_tgt == "FG_CH1" and bool(fg_channels[1].get("enabled", true)):
		return fg_channels[1]
	elif tip_tgt == "FG_CH2" and bool(fg_channels[2].get("enabled", true)):
		return fg_channels[2]
	elif tip_tgt == "CAL_1VPP":
		return {
			"waveform": SignalGenerator.WaveformType.SQUARE,
			"amplitude": 0.5,
			"frequency": 1000.0,
			"phase_deg": 0.0,
			"dc_offset": 0.5,
			"duty_cycle": 0.50,
			"noise_rms": 0.004,
			"noise_seed": 42
		}
	return {
		"waveform": SignalGenerator.WaveformType.DC,
		"amplitude": 0.0,
		"frequency": 50.0,
		"phase_deg": 0.0,
		"dc_offset": 0.0,
		"duty_cycle": 0.50,
		"noise_rms": 0.012,
		"noise_seed": 77
	}

func recompute() -> void:
	var sweep_span: float = float(view_config["time_per_div"]) * 10.0
	var sweep_samples: int = int(view_config["sample_count"])
	var total_span := sweep_span * 3.0
	var total_samples := sweep_samples * 3

	var p1_bnc: String = str(analog_config.get("probe1_bnc", "CH1"))
	var p1_tip: String = str(analog_config.get("probe1_tip", "FG_CH1"))
	var p2_bnc: String = str(analog_config.get("probe2_bnc", "CH2"))
	var p2_tip: String = str(analog_config.get("probe2_tip", "FG_CH2"))

	var ch1_tip := "FLOATING"
	if p1_bnc == "CH1":
		ch1_tip = p1_tip
	elif p2_bnc == "CH1":
		ch1_tip = p2_tip

	var ch2_tip := "FLOATING"
	if p2_bnc == "CH2":
		ch2_tip = p2_tip
	elif p1_bnc == "CH2":
		ch2_tip = p1_tip

	var psu_on := bool(analog_config.get("psu_power_on", true))
	var psu_vcc := clampf(float(analog_config.get("psu_voltage_coarse", 12.0)) + float(analog_config.get("psu_voltage_fine", 0.0)), 0.0, 30.0) if psu_on else 0.0
	breadboard_config["psu_vcc"] = psu_vcc

	# CH 1 Analog Chain
	var raw1 := Breadboard3DBuilder.generate_breadboard_signal(breadboard_config, ch1_tip, total_samples, total_span, sim_time_offset) if ch1_tip.begins_with("BB_TP") else SignalGenerator.generate_buffer(_resolve_tip_signal(ch1_tip), total_samples, total_span, sim_time_offset)
	raw_time_buffer = raw1["times"]
	raw_voltage_buffer = raw1["voltages"]
	var dt: float = raw1["dt"]

	var analog1 := AnalogScopeEngine.process_chain(raw_time_buffer, raw_voltage_buffer, dt, analog_config, view_config)
	analog_nodes = analog1["nodes"]
	time_buffer = analog1["sweep_times"]
	voltage_buffer = analog1["sweep_volts"]
	is_triggered = analog1["triggered"]

	# CH 2 Analog Chain
	var raw2 := Breadboard3DBuilder.generate_breadboard_signal(breadboard_config, ch2_tip, total_samples, total_span, sim_time_offset) if ch2_tip.begins_with("BB_TP") else SignalGenerator.generate_buffer(_resolve_tip_signal(ch2_tip), total_samples, total_span, sim_time_offset)
	var cfg2 := analog_config.duplicate()
	cfg2["coupling"] = analog_config.get("ch2_coupling", AnalogScopeEngine.CouplingMode.DC)
	cfg2["vert_pos_div"] = analog_config.get("ch2_vert_pos_div", 0.0)
	var view2 := view_config.duplicate()
	view2["volts_per_div"] = view_config.get("ch2_volts_per_div", 1.0)
	var analog2 := AnalogScopeEngine.process_chain(raw2["times"], raw2["voltages"], dt, cfg2, view2)
	ch2_voltage_buffer = analog2["sweep_volts"]

	state_updated.emit()

func get_calibration_checklist() -> Array[Dictionary]:
	var p1_bnc: String = str(analog_config.get("probe1_bnc", "UNPLUGGED"))
	var p1_tip: String = str(analog_config.get("probe1_tip", "FLOATING"))
	var p2_bnc: String = str(analog_config.get("probe2_bnc", "UNPLUGGED"))
	var p2_tip: String = str(analog_config.get("probe2_tip", "FLOATING"))

	var step1_ok := (p1_bnc == "CH1" and p1_tip == "CAL_1VPP") or (p2_bnc == "CH1" and p2_tip == "CAL_1VPP")
	var step2_ok := (int(analog_config["coupling"]) == AnalogScopeEngine.CouplingMode.DC) and (absf(float(analog_config["vert_pos_div"])) <= 0.45)
	var trig_v := float(analog_config["trigger_level"])
	var step3_ok := is_triggered and (trig_v >= 0.15 and trig_v <= 0.85)
	var v_div := float(view_config["volts_per_div"])
	var t_div := float(view_config["time_per_div"])
	var step4_ok := (v_div <= 1.0) and (t_div >= 0.0002 and t_div <= 0.001)
	var comp := float(analog_config["probe_compensation"])
	var step5_ok := (float(analog_config["probe_attenuation"]) > 1.5) and (absf(comp - 1.0) <= 0.06)

	return [
		{"done": step1_ok, "text": "1. Plug Probe BNC into CH 1 & clip Tip onto CAL 1Vp-p"},
		{"done": step2_ok, "text": "2. Set CH 1 Coupling = DC & center V-Position (~0 div)"},
		{"done": step3_ok, "text": "3. Adjust Trigger LEVEL (0.2V–0.8V) to lock square wave"},
		{"done": step4_ok, "text": "4. Set VOLTS/DIV (0.5V/1V) & TIME/DIV (0.5ms) to frame wave"},
		{"done": step5_ok, "text": "5. Flip Probe to 10x & tune PROBE COMP for flat corners"}
	]

func get_node_stats(node_id: String) -> Dictionary:
	var buf: PackedFloat64Array = analog_nodes.get(node_id, PackedFloat64Array())
	if buf.is_empty():
		return {"v_min": 0.0, "v_max": 0.0, "v_pp": 0.0, "v_rms": 0.0, "v_inst": 0.0, "buffer": buf}
	var v_min := buf[0]
	var v_max := buf[0]
	var sum_sq := 0.0
	for v in buf:
		if v < v_min:
			v_min = v
		if v > v_max:
			v_max = v
		sum_sq += v * v
	return {
		"v_min": v_min,
		"v_max": v_max,
		"v_pp": v_max - v_min,
		"v_rms": sqrt(sum_sq / float(buf.size())),
		"v_inst": buf[buf.size() / 2],
		"buffer": buf
	}
