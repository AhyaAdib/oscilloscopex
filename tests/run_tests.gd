extends SceneTree

var _failures := 0
var _passed := 0

func _init() -> void:
	print("=== OSCILLOSCOPE LAB — AUTOMATED VALIDATION SUITE ===")
	_test_sine_wave()
	_test_square_duty_cycle()
	_test_triangle_and_sawtooth()
	_test_dc_and_noise()
	print("=== SUMMARY: %d PASSED, 0 FAILED ===" % _passed if _failures == 0 else "=== SUMMARY: %d PASSED, %d FAILED ===" % [_passed, _failures])
	quit(1 if _failures > 0 else 0)

func _assert_near(actual: float, expected: float, tol: float, label: String) -> void:
	if absf(actual - expected) <= tol:
		_passed += 1
		print("[PASS] %s (actual=%.5f, expected=%.5f)" % [label, actual, expected])
	else:
		_failures += 1
		printerr("[FAIL] %s (actual=%.5f, expected=%.5f, tol=%.5f)" % [label, actual, expected, tol])

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
