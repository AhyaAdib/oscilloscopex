
extends Node

signal state_updated

var signal_params := {
	"waveform": SignalGenerator.WaveformType.SINE,
	"amplitude": 2.0,       # Volts peak (V)
	"frequency": 1000.0,    # Hertz (Hz)
	"phase_deg": 0.0,       # Degrees
	"dc_offset": 0.0,       # Volts (V)
	"duty_cycle": 0.50,     # 0.01 to 0.99
	"noise_rms": 0.0,       # Volts RMS (V)
	"noise_seed": 1337
}

var view_config := {
	"volts_per_div": 1.0,
	"time_per_div": 0.0005, # 0.5 ms/div -> 5.0 ms across 10 horizontal divs
	"sample_count": 1024,
	"running": true,
	"power_on": true
}

var analog_config := {
	"coupling": AnalogScopeEngine.CouplingMode.DC,
	"probe_attenuation": 1.0, # 1.0 (1x) or 10.0 (10x)
	"vert_pos_div": 0.0,      # -4.0 to +4.0 divs
	"horiz_pos_div": 0.0,     # -5.0 to +5.0 divs
	"trigger_level": 0.0,     # Volts
	"trigger_slope": AnalogScopeEngine.TriggerSlope.RISING,
	"trigger_hysteresis": 0.05,
	"intensity": 0.85,        # 0.1 to 1.0
	"focus": 0.88,            # 0.1 to 1.0
	"scale_illum": 0.65,      # 0.0 to 1.0 (VP-5231A cyan-blue graticule backlight)
	"persistence": 0.30       # 0.0 to 0.95 phosphor decay retention
}

var raw_time_buffer := PackedFloat64Array()
var raw_voltage_buffer := PackedFloat64Array()
var node_coupled_buffer := PackedFloat64Array()
var node_attenuated_buffer := PackedFloat64Array()
var node_vert_deflection_buffer := PackedFloat64Array()

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

	var raw := SignalGenerator.generate_buffer(signal_params, total_samples, total_span, sim_time_offset)
	raw_time_buffer = raw["times"]
	raw_voltage_buffer = raw["voltages"]
	var dt: float = raw["dt"]

	var analog_out := AnalogScopeEngine.process_chain(
		raw_time_buffer, raw_voltage_buffer, dt, analog_config, view_config
	)

	node_coupled_buffer = analog_out["coupled"]
	node_attenuated_buffer = analog_out["attenuated"]
	node_vert_deflection_buffer = analog_out["vert_deflection"]
	time_buffer = analog_out["sweep_times"]
	voltage_buffer = analog_out["sweep_volts"]
	is_triggered = analog_out["triggered"]

	state_updated.emit()
