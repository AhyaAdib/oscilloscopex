
class_name AnalogScopeEngine
extends RefCounted

enum CouplingMode {
	DC,
	AC,
	GND
}

enum TriggerSlope {
	RISING,
	FALLING
}

const COUPLING_NAMES := ["DC", "AC", "GND"]
const SLOPE_NAMES := ["Rising (+)", "Falling (-)"]

# High-pass AC coupling cutoff fc = 10 Hz -> RC = 1 / (2 * pi * 10)
const AC_COUPLING_FC := 10.0
const AMP_RAIL_VOLTS := 40.0

static func process_chain(
	raw_times: PackedFloat64Array,
	raw_voltages: PackedFloat64Array,
	dt: float,
	analog_cfg: Dictionary,
	view_cfg: Dictionary
) -> Dictionary:
	var n := raw_voltages.size()
	var coupled := PackedFloat64Array()
	var attenuated := PackedFloat64Array()
	var vert_deflection := PackedFloat64Array()
	coupled.resize(n)
	attenuated.resize(n)
	vert_deflection.resize(n)

	if n == 0:
		return {
			"coupled": coupled,
			"attenuated": attenuated,
			"vert_deflection": vert_deflection,
			"sweep_times": PackedFloat64Array(),
			"sweep_volts": PackedFloat64Array(),
			"triggered": false,
			"trigger_index": 0
		}

	var coupling: int = analog_cfg.get("coupling", CouplingMode.DC)
	var probe_atten: float = analog_cfg.get("probe_attenuation", 1.0) # 1.0 or 10.0
	var vert_pos_div: float = analog_cfg.get("vert_pos_div", 0.0)
	var volts_per_div: float = maxf(float(view_cfg.get("volts_per_div", 1.0)), 1e-6)
	var time_per_div: float = maxf(float(view_cfg.get("time_per_div", 0.0005)), 1e-9)

	# 1. Input Coupling Stage (DC / AC High-Pass / GND)
	var rc := 1.0 / (TAU * AC_COUPLING_FC)
	var alpha := rc / (rc + maxf(dt, 1e-12))

	for i in range(n):
		var vin := raw_voltages[i]
		match coupling:
			CouplingMode.GND:
				coupled[i] = 0.0
			CouplingMode.DC:
				coupled[i] = vin
			CouplingMode.AC:
				if i == 0:
					# Initialize steady-state DC removal on first sample
					coupled[i] = 0.0
				else:
					coupled[i] = alpha * (coupled[i - 1] + (vin - raw_voltages[i - 1]))

	# 2. Attenuator & Vertical Amplifier Stage (with rail saturation + vertical position offset)
	# Note: Oscilloscope Volts/Div knob compensates for 10x probe selection on display scale,
	# while internal attenuated node reflects physical 1/10 division.
	var div_factor := 1.0 / maxf(probe_atten, 1.0)
	var vert_offset_v := vert_pos_div * volts_per_div

	for i in range(n):
		var v_att := coupled[i] * div_factor
		attenuated[i] = v_att
		# Re-gain inside vertical preamp for true input-referred voltage, clamped at internal supply rails
		var v_amp := clampf(v_att * probe_atten, -AMP_RAIL_VOLTS, AMP_RAIL_VOLTS)
		vert_deflection[i] = v_amp + vert_offset_v

	# 3. Trigger Circuit (Edge detection with hysteresis)
	var trig_level: float = analog_cfg.get("trigger_level", 0.0)
	var trig_slope: int = analog_cfg.get("trigger_slope", TriggerSlope.RISING)
	var hysteresis: float = analog_cfg.get("trigger_hysteresis", 0.05)

	var trig_idx := -1
	var armed := false
	# Leave room at the end of the oversampled buffer so a full 10-div sweep can be extracted
	var sweep_samples := maxi(int(round((time_per_div * 10.0) / maxf(dt, 1e-12))) + 1, 2)
	var max_search := maxi(n - sweep_samples, 1)

	for i in range(1, max_search):
		var v_prev := coupled[i - 1]
		var v_curr := coupled[i]
		if trig_slope == TriggerSlope.RISING:
			if v_prev <= trig_level - hysteresis:
				armed = true
			if armed and v_prev < trig_level and v_curr >= trig_level:
				trig_idx = i
				break
		else:
			if v_prev >= trig_level + hysteresis:
				armed = true
			if armed and v_prev > trig_level and v_curr <= trig_level:
				trig_idx = i
				break

	var triggered := trig_idx >= 0
	var start_idx := trig_idx if triggered else 0

	# Apply horizontal position shift (in divisions)
	var horiz_pos_div: float = analog_cfg.get("horiz_pos_div", 0.0)
	var shift_samples := int(round((horiz_pos_div * time_per_div) / maxf(dt, 1e-12)))
	start_idx = clampi(start_idx - shift_samples, 0, maxi(n - sweep_samples, 0))

	# 4. Horizontal Sweep Extraction (10 horizontal divisions)
	var out_len := mini(sweep_samples, n - start_idx)
	var sweep_times := PackedFloat64Array()
	var sweep_volts := PackedFloat64Array()
	sweep_times.resize(out_len)
	sweep_volts.resize(out_len)

	var t0 := raw_times[start_idx]
	for k in range(out_len):
		sweep_times[k] = raw_times[start_idx + k] - t0
		sweep_volts[k] = vert_deflection[start_idx + k]

	return {
		"coupled": coupled,
		"attenuated": attenuated,
		"vert_deflection": vert_deflection,
		"sweep_times": sweep_times,
		"sweep_volts": sweep_volts,
		"triggered": triggered,
		"trigger_index": start_idx
	}
