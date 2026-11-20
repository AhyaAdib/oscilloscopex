extends Node

signal state_updated
signal selected_node_changed(node_id: String)

var signal_params := {
	"waveform": SignalGenerator.WaveformType.SINE,
	"amplitude": 2.0,
	"frequency": 1000.0,
	"phase_deg": 0.0,
	"dc_offset": 0.0,
	"duty_cycle": 0.50,
	"noise_rms": 0.0,
	"noise_seed": 1337
}

var view_config := {
	"volts_per_div": 1.0,
	"time_per_div": 0.0005,
	"sample_count": 1024,
	"running": true,
	"power_on": true
}

var analog_config := {
	"coupling": AnalogScopeEngine.CouplingMode.DC,
	"probe_attenuation": 1.0,
	"probe_compensation": 0.72, # Slightly under-compensated initially so user can calibrate on CAL 1Vp-p!
	"probe_target": AnalogScopeEngine.ProbeTarget.FUNC_GEN,
	"vert_pos_div": 0.0,
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
var is_triggered := false
var sim_time_offset := 0.0

func _ready() -> void:
	recompute()

func set_signal_param(key: String, value: Variant) -> void:
	if signal_params.get(key) == value:
		return
	signal_params[key] = value
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

func recompute() -> void:
	var sweep_span: float = float(view_config["time_per_div"]) * 10.0
	var sweep_samples: int = int(view_config["sample_count"])
	var total_span := sweep_span * 3.0
	var total_samples := sweep_samples * 3

	var active_sig := signal_params
	var target: int = int(analog_config.get("probe_target", AnalogScopeEngine.ProbeTarget.FUNC_GEN))
	if target == AnalogScopeEngine.ProbeTarget.CAL_1VPP:
		# Built-in VP-5231A 1 kHz, 1.0 Vp-p (0V to +1V) square calibration reference
		active_sig = {
			"waveform": SignalGenerator.WaveformType.SQUARE,
			"amplitude": 0.5,
			"frequency": 1000.0,
			"phase_deg": 0.0,
			"dc_offset": 0.5,
			"duty_cycle": 0.50,
			"noise_rms": 0.005,
			"noise_seed": 42
		}
	elif target == AnalogScopeEngine.ProbeTarget.FLOATING:
		active_sig = {
			"waveform": SignalGenerator.WaveformType.DC,
			"amplitude": 0.0,
			"frequency": 50.0,
			"phase_deg": 0.0,
			"dc_offset": 0.0,
			"duty_cycle": 0.50,
			"noise_rms": 0.015,
			"noise_seed": 77
		}

	var raw := SignalGenerator.generate_buffer(active_sig, total_samples, total_span, sim_time_offset)
	raw_time_buffer = raw["times"]
	raw_voltage_buffer = raw["voltages"]
	var dt: float = raw["dt"]

	var analog_out := AnalogScopeEngine.process_chain(
		raw_time_buffer, raw_voltage_buffer, dt, analog_config, view_config
	)

	analog_nodes = analog_out["nodes"]
	time_buffer = analog_out["sweep_times"]
	voltage_buffer = analog_out["sweep_volts"]
	is_triggered = analog_out["triggered"]

	state_updated.emit()

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
