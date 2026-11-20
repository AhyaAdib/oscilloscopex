class_name ChallengeManager
extends RefCounted

const MISSIONS := [
	{
		"id": "M1_CAL",
		"title": "Mission 1: Probe Compensation & 1Vp-p Calibration",
		"time_limit": 120.0,
		"description": "The VP-5231A is uncalibrated and probes are unplugged. Plug a probe into CH 1 and CAL 1Vp-p, switch to 10x, tune PROBE COMP until square corners are flat, lock trigger, and submit your graticule readings.",
		"req_tip": "CAL_1VPP",
		"req_10x": true,
		"true_vpp": 1.0,
		"true_freq": 1000.0,
		"true_offset": 0.5,
		"randomize_fg": false
	},
	{
		"id": "M2_UNKNOWN",
		"title": "Mission 2: Unknown Signal Graticule Measurement",
		"time_limit": 150.0,
		"description": "Calibrate the scope, plug Probe 1 into Siglent CH1 OUT, and measure the unknown waveform purely by counting CRT divisions (Volts/Div & Time/Div). Submit Vpp, Frequency, and DC Offset before time expires!",
		"req_tip": "FG_CH1",
		"req_10x": false,
		"true_vpp": 3.2,
		"true_freq": 1250.0,
		"true_offset": 0.4,
		"randomize_fg": true
	},
	{
		"id": "M3_DUAL",
		"title": "Mission 3: Dual-Channel (CH1 + CH2) Bench Audit",
		"time_limit": 180.0,
		"description": "Connect Probe 1 (CH1 -> FG CH1 OUT) and Probe 2 (CH2 -> FG CH2 OUT), enable ALT (Dual) mode, calibrate the scope, and read CH1 Vpp, CH1 Frequency, and CH1 DC Offset from the CRT.",
		"req_tip": "FG_CH1",
		"req_dual": true,
		"req_10x": false,
		"true_vpp": 4.0,
		"true_freq": 2000.0,
		"true_offset": -0.6,
		"randomize_fg": true
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
		base["fg_wf"] = SignalGenerator.WaveformType.SINE if mission_idx == 1 else SignalGenerator.WaveformType.TRIANGLE
	return base

static func evaluate_submission(mission: Dictionary, sub_vpp: float, sub_freq: float, sub_offset: float, time_left: float) -> Dictionary:
	var p1_bnc := str(SimState.analog_config.get("probe1_bnc", "UNPLUGGED"))
	var p1_tip := str(SimState.analog_config.get("probe1_tip", "FLOATING"))
	var p2_bnc := str(SimState.analog_config.get("probe2_bnc", "UNPLUGGED"))
	var p2_tip := str(SimState.analog_config.get("probe2_tip", "FLOATING"))

	var req_tip := str(mission.get("req_tip", "CAL_1VPP"))
	var routing_ok := (p1_bnc == "CH1" and p1_tip == req_tip) or (p2_bnc == "CH1" and p2_tip == req_tip)
	if mission.get("req_dual", false):
		routing_ok = (p1_bnc == "CH1" and p1_tip == "FG_CH1") and (p2_bnc == "CH2" and p2_tip == "FG_CH2")

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

	var vpp_ok := vpp_err_pct <= 7.0
	var freq_ok := freq_err_pct <= 7.0
	var off_ok := off_err_v <= 0.20

	var read_score := 0
	if vpp_ok:
		read_score += 20
	elif vpp_err_pct <= 15.0:
		read_score += 10
	if freq_ok:
		read_score += 20
	elif freq_err_pct <= 15.0:
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
