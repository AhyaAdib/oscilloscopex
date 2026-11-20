
extends SceneTree

var _failures := 0
var _passed := 0

func _init() -> void:
	print("=== OSCILLOSCOPE LAB — AUTOMATED VALIDATION SUITE ===")
	_test_sine_wave()
	_test_square_duty_cycle()
	_test_triangle_and_sawtooth()
	_test_dc_and_noise()
	_test_analog_coupling_and_attenuation()
	_test_analog_trigger()
	print("=== SUMMARY: %d PASSED, %d FAILED ===" % [_passed, _failures])
	quit(1 if _failures > 0 else 0)

func _assert_near(actual: float, expected: float, tol: float, label: String) -> void:
	if absf(actual - expected) <= tol:
		_passed += 1
		print("[PASS] %s (actual=%.5f, expected=%.5f)" % [label, actual, expected])
	else:
		_failures += 1
		printerr("[FAIL] %s (actual=%.5f, expected=%.5f, tol=%.5f)" % [label, actual, expected, tol])

func _assert_true(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("[PASS] %s" % label)
	else:
		_failures += 1
		printerr("[FAIL] %s" % label)

func _test_sine_wave() -> void:
	var v_quarter := SignalGenerator.evaluate_sample(
		0.00025, SignalGenerator.WaveformType.SINE, 3.0, 1000.0, 0.0, 1.5, 0.5, 0.0
	)
	_assert_near(v_quarter, 4.5, 1e-5, "Sine quarter-period peak with DC offset")

	var v_phase := SignalGenerator.evaluate_sample(
		0.0, SignalGenerator.WaveformType.SINE, 3.0, 1000.0, PI * 0.5, 1.5, 0.5, 0.0
	)
	_assert_near(v_phase, 4.5, 1e-5, "Sine +90 deg phase shift at t=0")

func _test_square_duty_cycle() -> void:
	var v_hi := SignalGenerator.evaluate_sample(
		0.00020, SignalGenerator.WaveformType.SQUARE, 2.5, 1000.0, 0.0, 0.0, 0.25, 0.0
	)
	var v_lo := SignalGenerator.evaluate_sample(
		0.00030, SignalGenerator.WaveformType.SQUARE, 2.5, 1000.0, 0.0, 0.0, 0.25, 0.0
	)
	_assert_near(v_hi, 2.5, 1e-5, "Square wave HIGH inside 25% duty window")
	_assert_near(v_lo, -2.5, 1e-5, "Square wave LOW outside 25% duty window")

func _test_triangle_and_sawtooth() -> void:
	var v_tri := SignalGenerator.evaluate_sample(
		0.00025, SignalGenerator.WaveformType.TRIANGLE, 2.0, 1000.0, 0.0, 0.0, 0.5, 0.0
	)
	_assert_near(v_tri, 0.0, 1e-5, "Triangle midpoint zero-crossing")

	var v_saw := SignalGenerator.evaluate_sample(
		0.00075, SignalGenerator.WaveformType.SAWTOOTH, 2.0, 1000.0, 0.0, 0.0, 0.5, 0.0
	)
	_assert_near(v_saw, 1.0, 1e-5, "Sawtooth 75% ramp value")

func _test_dc_and_noise() -> void:
	var buf := SignalGenerator.generate_buffer({
		"waveform": SignalGenerator.WaveformType.DC,
		"dc_offset": -1.25,
		"noise_rms": 0.2,
		"noise_seed": 99
	}, 2000, 0.01)
	var v: PackedFloat64Array = buf["voltages"]
	var sum := 0.0
	for val in v:
		sum += val
	var mean := sum / float(v.size())
	_assert_near(mean, -1.25, 0.03, "DC + Gaussian noise sample mean convergence")

func _test_analog_coupling_and_attenuation() -> void:
	# Pure DC +5.0 V through AC coupling should decay toward 0 V
	var raw := SignalGenerator.generate_buffer({
		"waveform": SignalGenerator.WaveformType.DC,
		"dc_offset": 5.0
	}, 1000, 0.2) # 200 ms >> RC (15.9 ms)
	var res_ac := AnalogScopeEngine.process_chain(
		raw["times"], raw["voltages"], raw["dt"],
		{"coupling": AnalogScopeEngine.CouplingMode.AC, "probe_attenuation": 10.0},
		{"volts_per_div": 1.0, "time_per_div": 0.005}
	)
	var coupled: PackedFloat64Array = res_ac["coupled"]
	var attenuated: PackedFloat64Array = res_ac["attenuated"]
	_assert_near(coupled[coupled.size() - 1], 0.0, 0.01, "AC coupling rejects steady-state DC offset")

	# DC coupling with 10x probe divides physical attenuated node by 10
	var res_dc := AnalogScopeEngine.process_chain(
		raw["times"], raw["voltages"], raw["dt"],
		{"coupling": AnalogScopeEngine.CouplingMode.DC, "probe_attenuation": 10.0},
		{"volts_per_div": 1.0, "time_per_div": 0.005}
	)
	var att_dc: PackedFloat64Array = res_dc["attenuated"]
	_assert_near(att_dc[0], 0.5, 1e-5, "10x probe divider outputs 0.5V for 5.0V input")

func _test_analog_trigger() -> void:
	var raw := SignalGenerator.generate_buffer({
		"waveform": SignalGenerator.WaveformType.SINE,
		"amplitude": 2.0,
		"frequency": 1000.0
	}, 3000, 0.015)
	var res := AnalogScopeEngine.process_chain(
		raw["times"], raw["voltages"], raw["dt"],
		{
			"coupling": AnalogScopeEngine.CouplingMode.DC,
			"trigger_level": 1.0,
			"trigger_slope": AnalogScopeEngine.TriggerSlope.RISING
		},
		{"volts_per_div": 1.0, "time_per_div": 0.0005}
	)
	_assert_true(res["triggered"], "Analog trigger locks on +1.0V rising edge")
	var sweep_v: PackedFloat64Array = res["sweep_volts"]
	_assert_near(sweep_v[0], 1.0, 0.05, "Triggered sweep starts near +1.0V threshold")
