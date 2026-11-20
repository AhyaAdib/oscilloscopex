
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

const AC_COUPLING_FC := 10.0
const AMP_RAIL_VOLTS := 40.0
const DELAY_LINE_SEC := 0.00005 # 50 us visible educational delay offset on internal probe

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
	var preamp := PackedFloat64Array()
	var delayed := PackedFloat64Array()
	var vert_deflection := PackedFloat64Array()
	var trigger_pulse := PackedFloat64Array()
	var sweep_ramp := PackedFloat64Array()

	coupled.resize(n)
	attenuated.resize(n)
	preamp.resize(n)
	delayed.resize(n)
	vert_deflection.resize(n)
	trigger_pulse.resize(n)
	sweep_ramp.resize(n)

	if n == 0:
		return {
			"nodes": {},
			"sweep_times": PackedFloat64Array(),
			"sweep_volts": PackedFloat64Array(),
			"triggered": false,
			"trigger_index": 0
		}

	var coupling: int = analog_cfg.get("coupling", CouplingMode.DC)
	var probe_atten: float = analog_cfg.get("probe_attenuation", 1.0)
	var vert_pos_div: float = analog_cfg.get("vert_pos_div", 0.0)
	var volts_per_div: float = maxf(float(view_cfg.get("volts_per_div", 1.0)), 1e-6)
	var time_per_div: float = maxf(float(view_cfg.get("time_per_div", 0.0005)), 1e-9)
	var safe_dt := maxf(dt, 1e-12)

	# 1. Input Coupling Stage (N2_COUPLING)
	var rc := 1.0 / (TAU * AC_COUPLING_FC)
	var alpha := rc / (rc + safe_dt)
	for i in range(n):
		var vin := raw_voltages[i]
		match coupling:
			CouplingMode.GND:
				coupled[i] = 0.0
			CouplingMode.DC:
				coupled[i] = vin
			CouplingMode.AC:
				if i == 0:
					coupled[i] = 0.0
				else:
					coupled[i] = alpha * (coupled[i - 1] + (vin - raw_voltages[i - 1]))

	# 2. Attenuator (N3_ATTENUATOR) & Vertical Preamp (N4_PREAMP)
	var div_factor := 1.0 / maxf(probe_atten, 1.0)
	for i in range(n):
		var v_att := coupled[i] * div_factor
		attenuated[i] = v_att
		preamp[i] = clampf(v_att * probe_atten, -AMP_RAIL_VOLTS, AMP_RAIL_VOLTS)

	# 3. Delay Line (N5_DELAY_LINE) & Vertical Deflection Plates (N6_VERT_DEFLECT)
	var delay_samples := clampi(int(round(DELAY_LINE_SEC / safe_dt)), 1, maxi(n / 8, 1))
	var vert_offset_v := vert_pos_div * volts_per_div
	for i in range(n):
		var src_i := maxi(i - delay_samples, 0)
		delayed[i] = preamp[src_i]
		vert_deflection[i] = delayed[i] + vert_offset_v

	# 4. Trigger Comparator (N7_TRIGGER)
	var trig_level: float = analog_cfg.get("trigger_level", 0.0)
	var trig_slope: int = analog_cfg.get("trigger_slope", TriggerSlope.RISING)
	var hysteresis: float = analog_cfg.get("trigger_hysteresis", 0.05)

	var trig_idx := -1
	var armed := false
	var sweep_samples := maxi(int(round((time_per_div * 10.0) / safe_dt)) + 1, 2)
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

	var horiz_pos_div: float = analog_cfg.get("horiz_pos_div", 0.0)
	var shift_samples := int(round((horiz_pos_div * time_per_div) / safe_dt))
	start_idx = clampi(start_idx - shift_samples, 0, maxi(n - sweep_samples, 0))

	# Synthesize Trigger Gate Pulse (0V -> +5V at trigger instant) & Miller Sweep Ramp (-5V -> +5V)
	for i in range(n):
		var comp_high := (coupled[i] >= trig_level) if trig_slope == TriggerSlope.RISING else (coupled[i] <= trig_level)
		trigger_pulse[i] = 5.0 if comp_high else 0.0

		if i < start_idx:
			sweep_ramp[i] = -5.0
		else:
			var prog := clampf(float(i - start_idx) / float(maxi(sweep_samples - 1, 1)), 0.0, 1.0)
			sweep_ramp[i] = lerpf(-5.0, 5.0, prog)

	# 5. Extract 10-Div CRT Display Sweep
	var out_len := mini(sweep_samples, n - start_idx)
	var sweep_times := PackedFloat64Array()
	var sweep_volts := PackedFloat64Array()
	sweep_times.resize(out_len)
	sweep_volts.resize(out_len)

	var t0 := raw_times[start_idx]
	for k in range(out_len):
		sweep_times[k] = raw_times[start_idx + k] - t0
		sweep_volts[k] = vert_deflection[start_idx + k]

	var nodes := {
		"N1_INPUT": raw_voltages,
		"N2_COUPLING": coupled,
		"N3_ATTENUATOR": attenuated,
		"N4_PREAMP": preamp,
		"N5_DELAY_LINE": delayed,
		"N6_VERT_DEFLECT": vert_deflection,
		"N7_TRIGGER": trigger_pulse,
		"N8_SWEEP": sweep_ramp
	}

	return {
		"nodes": nodes,
		"sweep_times": sweep_times,
		"sweep_volts": sweep_volts,
		"triggered": triggered,
		"trigger_index": start_idx
	}
