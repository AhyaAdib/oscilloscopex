
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
	"running": true
}

var time_buffer := PackedFloat64Array()
var voltage_buffer := PackedFloat64Array()
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

func advance_time(delta: float) -> void:
	if not view_config["running"]:
		return
	sim_time_offset = fmod(sim_time_offset + delta * 0.05, 10.0)
	recompute()

func recompute() -> void:
	var total_time: float = float(view_config["time_per_div"]) * 10.0
	var count: int = int(view_config["sample_count"])
	var result := SignalGenerator.generate_buffer(signal_params, count, total_time, sim_time_offset)
	time_buffer = result["times"]
	voltage_buffer = result["voltages"]
	state_updated.emit()
