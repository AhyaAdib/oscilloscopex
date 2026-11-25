class_name ChallengeManager
extends RefCounted

const MISSIONS := [
	{
		"id": "M1_CAL",
		"title": "Mission 1: Scope Probe Compensation & 1Vp-p Calibration",
		"time_limit": 120.0,
		"description": "Calibrate the VP-5231A: plug Probe 1 into CH 1 and CAL 1Vp-p, switch to 10x, tune PROBE COMP for flat square corners, lock trigger, and submit Vpp, Frequency, and DC Offset.",
		"req_tip": "CAL_1VPP",
		"req_10x": true,
		"true_vpp": 1.0,
		"true_freq": 1000.0,
		"true_offset": 0.5,
		"randomize_fg": false
	},
	{
		"id": "M2_UNKNOWN",
		"title": "Mission 2: Unknown Function Generator Signal Reading",
		"time_limit": 150.0,
		"description": "Connect Probe 1 (CH 1 → FG CH1 OUT), calibrate the scope, and measure the unknown waveform by counting CRT divisions. Submit Vpp, Frequency, and DC Offset.",
		"req_tip": "FG_CH1",
		"req_10x": false,
		"true_vpp": 3.2,
		"true_freq": 1250.0,
		"true_offset": 0.4,
		"randomize_fg": true
	},
	{
		"id": "M3_BB_RC",
		"title": "Mission 3: Breadboard RC Low-Pass Filter Output (TP2)",
		"time_limit": 150.0,
		"description": "Select Breadboard Model 1 (RC Low-Pass Filter), clip Probe 1 hook onto Breadboard TP2 (Capacitor Out), and measure the attenuated filtered Vpp, Frequency, and DC Offset.",
		"req_tip": "BB_TP2",
		"bb_model": 0,
		"req_10x": false,
		"true_vpp": 3.52,
		"true_freq": 1600.0,
		"true_offset": 0.0,
		"randomize_fg": false
	},
	{
		"id": "M4_BB_RECT",
		"title": "Mission 4: Breadboard Diode Rectifier & Ripple (TP2 / TP3)",
		"time_limit": 150.0,
		"description": "Select Breadboard Model 2 (Diode Rectifier), probe TP2 (Half-Wave Rectified output after 0.65V diode drop), and measure its peak-to-peak amplitude Vpp, Frequency, and average DC Offset.",
		"req_tip": "BB_TP2",
		"bb_model": 1,
		"req_10x": false,
		"true_vpp": 2.35,
		"true_freq": 500.0,
		"true_offset": 0.75,
		"randomize_fg": false
	},
	{
		"id": "M5_BB_PROC",
		"title": "Mission 5: Procedural Breadboard Circuit Audit (TP2)",
		"time_limit": 180.0,
		"description": "A procedural RC circuit with randomized R, C, and drive frequency has been placed on the breadboard! Clip Probe 1 onto Breadboard TP2, calibrate the scope, and measure Vpp, Frequency, and DC Offset.",
		"req_tip": "BB_TP2",
		"bb_model": 3,
		"procedural_bb": true,
		"req_10x": false,
		"true_vpp": 2.0,
		"true_freq": 1000.0,
		"true_offset": 0.0,
		"randomize_fg": false
	}
]

static func build_mission_instance(mission_idx: int) -> Dictionary:
	var base: Dictionary = MISSIONS[clampi(mission_idx, 0, MISSIONS.size() - 1)].duplicate(true)
	if base.get("randomize_fg", false):
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var amp_choices := [1.2, 1.5, 1.8, 2.0, 2.4, 2.5]
		var freq_choices := [500.0, 800.0, 1000.0, 1250.0, 2000.0, 2500.0]
		var off_choices := [-0.8, -0.4, 0.0, 0.4, 0.8]
		var amp: float = amp_choices[rng.randi_range(0, amp_choices.size() - 1)]
		var freq: float = freq_choices[rng.randi_range(0, freq_choices.size() - 1)]
		var off: float = off_choices[rng.randi_range(0, off_choices.size() - 1)]
		base["true_vpp"] = amp * 2.0
		base["true_freq"] = freq
		base["true_offset"] = off
		base["fg_amp"] = amp
		base["fg_wf"] = SignalGenerator.WaveformType.SINE
	elif base.get("procedural_bb", false) or base.has("bb_model"):
		if base.get("procedural_bb", false):
			SimState.select_breadboard_model(3, true)
		else:
			SimState.select_breadboard_model(int(base["bb_model"]), false)
		var cfg := SimState.breadboard_config
		var model_id := str(cfg.get("id", "RC_LPF"))
		var psu_vcc := float(cfg.get("psu_vcc", 12.0))
		var freq := float(cfg.get("freq_hz", float(base.get("true_freq", 1000.0))))
		var tp_key := str(base.get("req_tip", "BB_TP2"))
		var sig := Breadboard3DBuilder.generate_breadboard_signal(cfg, tp_key, 4096, maxf(5.0 / maxf(freq, 1.0), 0.005), 0.0)
		var volts: PackedFloat64Array = sig["volts"]
		var vmin := volts[0]
		var vmax := volts[0]
		var vsum := 0.0
		for v in volts:
			if v < vmin:
				vmin = v
			if v > vmax:
				vmax = v
			vsum += v
		base["true_vpp"] = vmax - vmin
		base["true_freq"] = freq
		base["true_offset"] = vsum / float(maxi(volts.size(), 1)) if psu_vcc > 0.01 else 0.0
		if model_id == "ASTABLE_555" and psu_vcc < 4.5:
			base["true_vpp"] = 0.0
			base["true_offset"] = 0.0
	return base

static func evaluate_submission(mission: Dictionary, sub_vpp: float, sub_freq: float, sub_offset: float, time_left: float) -> Dictionary:
	var p1_bnc := str(SimState.analog_config.get("probe1_bnc", "UNPLUGGED"))
	var p1_tip := str(SimState.analog_config.get("probe1_tip", "FLOATING"))
	var p2_bnc := str(SimState.analog_config.get("probe2_bnc", "UNPLUGGED"))
	var p2_tip := str(SimState.analog_config.get("probe2_tip", "FLOATING"))

	var req_tip := str(mission.get("req_tip", "CAL_1VPP"))
	var routing_ok := (p1_bnc == "CH1" and p1_tip == req_tip) or (p2_bnc == "CH1" and p2_tip == req_tip)

	var coupling_ok := int(SimState.analog_config["coupling"]) == AnalogScopeEngine.CouplingMode.DC
	var trig_ok := SimState.is_triggered
	var comp_val := float(SimState.analog_config["probe_compensation"])
	var comp_ok := absf(comp_val - 1.0) <= 0.07
	if mission.get("req_10x", false):
		comp_ok = comp_ok and (float(SimState.analog_config["probe_attenuation"]) > 1.5)

	var cal_score := 0
	if routing_ok:
		cal_score += 15
	if coupling_ok:
		cal_score += 10
	if trig_ok:
		cal_score += 10
	if comp_ok:
		cal_score += 15

	var true_vpp := float(mission["true_vpp"])
	var true_freq := float(mission["true_freq"])
	var true_off := float(mission["true_offset"])

	var vpp_err_pct := absf(sub_vpp - true_vpp) / maxf(true_vpp, 1e-6) * 100.0
	var freq_err_pct := absf(sub_freq - true_freq) / maxf(true_freq, 1e-6) * 100.0
	var off_err_v := absf(sub_offset - true_off)

	var vpp_ok := vpp_err_pct <= 8.0
	var freq_ok := freq_err_pct <= 8.0
	var off_ok := off_err_v <= 0.25

	var read_score := 0
	if vpp_ok:
		read_score += 20
	elif vpp_err_pct <= 16.0:
		read_score += 10
	if freq_ok:
		read_score += 20
	elif freq_err_pct <= 16.0:
		read_score += 10
	if off_ok:
		read_score += 10

	var total_score := cal_score + read_score
	var passed := (total_score >= 80) and (time_left > 0.0)

	return {
		"passed": passed,
		"total_score": total_score,
		"cal_score": cal_score,
		"read_score": read_score,
		"routing_ok": routing_ok,
		"coupling_ok": coupling_ok,
		"trig_ok": trig_ok,
		"comp_ok": comp_ok,
		"vpp_ok": vpp_ok,
		"freq_ok": freq_ok,
		"off_ok": off_ok,
		"true_vpp": true_vpp,
		"true_freq": true_freq,
		"true_offset": true_off,
		"vpp_err_pct": vpp_err_pct,
		"freq_err_pct": freq_err_pct,
		"off_err_v": off_err_v
	}
