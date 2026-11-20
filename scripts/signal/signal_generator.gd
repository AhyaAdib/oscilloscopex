
class_name SignalGenerator
extends RefCounted

enum WaveformType {
	SINE,
	SQUARE,
	TRIANGLE,
	SAWTOOTH,
	PULSE,
	DC,
	NOISE
}

const WAVEFORM_NAMES := [
	"Sine",
	"Square",
	"Triangle",
	"Sawtooth",
	"Pulse",
	"DC",
	"Noise"
]

static func evaluate_sample(
	t: float,
	waveform: int,
	amplitude: float,
	frequency: float,
	phase_rad: float,
	dc_offset: float,
	duty_cycle: float,
	noise_rms: float,
	rng: RandomNumberGenerator = null
) -> float:
	var v_base := 0.0
	var clamped_duty := clampf(duty_cycle, 0.01, 0.99)
	var phase_cycles := fposmod(frequency * t + (phase_rad / TAU), 1.0)

	match waveform:
		WaveformType.SINE:
			v_base = dc_offset + amplitude * sin(TAU * frequency * t + phase_rad)
		WaveformType.SQUARE:
			v_base = dc_offset + (amplitude if phase_cycles < clamped_duty else -amplitude)
		WaveformType.TRIANGLE:
			if phase_cycles < 0.5:
				v_base = dc_offset + lerpf(-amplitude, amplitude, phase_cycles * 2.0)
			else:
				v_base = dc_offset + lerpf(amplitude, -amplitude, (phase_cycles - 0.5) * 2.0)
		WaveformType.SAWTOOTH:
			v_base = dc_offset + lerpf(-amplitude, amplitude, phase_cycles)
		WaveformType.PULSE:
			v_base = dc_offset + (amplitude if phase_cycles < clamped_duty else 0.0)
		WaveformType.DC:
			v_base = dc_offset
		WaveformType.NOISE:
			v_base = dc_offset

	if noise_rms > 0.0 and rng != null:
		v_base += rng.randfn(0.0, noise_rms)

	return v_base

static func generate_buffer(params: Dictionary, sample_count: int, time_span: float, start_time: float = 0.0) -> Dictionary:
	var count := maxi(sample_count, 2)
	var times := PackedFloat64Array()
	var voltages := PackedFloat64Array()
	times.resize(count)
	voltages.resize(count)

	var waveform: int = params.get("waveform", WaveformType.SINE)
	var amplitude: float = params.get("amplitude", 1.0)
	var frequency: float = params.get("frequency", 1000.0)
	var phase_deg: float = params.get("phase_deg", 0.0)
	var dc_offset: float = params.get("dc_offset", 0.0)
	var duty_cycle: float = params.get("duty_cycle", 0.5)
	var noise_rms: float = params.get("noise_rms", 0.0)
	var seed_val: int = params.get("noise_seed", 42)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var phase_rad := deg_to_rad(phase_deg)
	var dt := time_span / float(count - 1)

	for i in range(count):
		var t := start_time + float(i) * dt
		times[i] = t
		voltages[i] = evaluate_sample(
			t, waveform, amplitude, frequency, phase_rad, dc_offset, duty_cycle, noise_rms, rng
		)

	return {
		"times": times,
		"voltages": voltages,
		"dt": dt
	}
