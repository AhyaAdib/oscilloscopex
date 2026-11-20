
class_name WaveformCanvas
extends Control

const H_DIVS := 10
const V_DIVS := 8

const BG_COLOR := Color(0.04, 0.06, 0.08, 1.0)
const GRID_MINOR_COLOR := Color(0.12, 0.17, 0.22, 0.85)
const AXIS_COLOR := Color(0.24, 0.34, 0.42, 1.0)
const TRACE_GLOW_COLOR := Color(0.15, 0.95, 0.55, 0.25)
const TRACE_CORE_COLOR := Color(0.25, 1.00, 0.62, 1.0)
const HUD_TEXT_COLOR := Color(0.75, 0.85, 0.92, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(640, 420)
	if has_node("/root/SimState"):
		SimState.state_updated.connect(queue_redraw)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BG_COLOR, true)

	if size.x < 20.0 or size.y < 20.0:
		return

	_draw_graticule()
	_draw_waveform()
	_draw_hud()

func _draw_graticule() -> void:
	var dx := size.x / float(H_DIVS)
	var dy := size.y / float(V_DIVS)

	for i in range(1, H_DIVS):
		var x := float(i) * dx
		var col := AXIS_COLOR if i == H_DIVS / 2 else GRID_MINOR_COLOR
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), col, 1.5 if i == H_DIVS / 2 else 1.0)

	for j in range(1, V_DIVS):
		var y := float(j) * dy
		var col := AXIS_COLOR if j == V_DIVS / 2 else GRID_MINOR_COLOR
		draw_line(Vector2(0.0, y), Vector2(size.x, y), col, 1.5 if j == V_DIVS / 2 else 1.0)

	var mid_x := size.x * 0.5
	var mid_y := size.y * 0.5
	for i in range(H_DIVS * 5):
		var tx := float(i) * (dx / 5.0)
		draw_line(Vector2(tx, mid_y - 3.0), Vector2(tx, mid_y + 3.0), AXIS_COLOR, 1.0)
	for j in range(V_DIVS * 5):
		var ty := float(j) * (dy / 5.0)
		draw_line(Vector2(mid_x - 3.0, ty), Vector2(mid_x + 3.0, ty), AXIS_COLOR, 1.0)

	draw_rect(Rect2(Vector2.ZERO, size), AXIS_COLOR, false, 2.0)

func _draw_waveform() -> void:
	if not has_node("/root/SimState"):
		return
	var voltages: PackedFloat64Array = SimState.voltage_buffer
	var n := voltages.size()
	if n < 2:
		return

	var volts_per_div: float = maxf(float(SimState.view_config["volts_per_div"]), 1e-6)
	var full_scale_v := volts_per_div * float(V_DIVS)
	var mid_y := size.y * 0.5
	var px_per_volt := size.y / full_scale_v
	var step_x := size.x / float(n - 1)

	var points := PackedVector2Array()
	points.resize(n)
	for i in range(n):
		var x := float(i) * step_x
		var y := mid_y - float(voltages[i]) * px_per_volt
		points[i] = Vector2(x, y)

	draw_polyline(points, TRACE_GLOW_COLOR, 6.0, true)
	draw_polyline(points, TRACE_CORE_COLOR, 2.0, true)

func _draw_hud() -> void:
	if not has_node("/root/SimState"):
		return
	var font := ThemeDB.fallback_font
	var v_div: float = SimState.view_config["volts_per_div"]
	var t_div_ms: float = float(SimState.view_config["time_per_div"]) * 1000.0
	var wf_idx: int = SimState.signal_params["waveform"]
	var wf_name: String = SignalGenerator.WAVEFORM_NAMES[wf_idx]
	var freq: float = SimState.signal_params["frequency"]
	var amp: float = SimState.signal_params["amplitude"]

	var top_text := "CH1: %.2f V/div   |   TIMEBASE: %.2f ms/div   |   SRC: %s (%.1f Hz, %.2f Vpk)" % [
		v_div, t_div_ms, wf_name, freq, amp
	]
	draw_string(font, Vector2(14, 24), top_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, HUD_TEXT_COLOR)
