
class_name WaveformCanvas
extends Control

const H_DIVS := 10
const V_DIVS := 8
const MAX_PERSISTENCE_FRAMES := 12

# National VP-5231A Cyan-Teal CRT Glass & Dark Etched Graticule Palette
const CRT_UNLIT_COLOR := Color(0.08, 0.22, 0.27, 1.0)
const CRT_LIT_COLOR := Color(0.14, 0.48, 0.58, 1.0)
const GRATICULE_ETCH_COLOR := Color(0.05, 0.14, 0.18, 0.72)
const GRATICULE_AXIS_COLOR := Color(0.03, 0.10, 0.13, 0.90)
const TRIG_MARKER_COLOR := Color(1.0, 0.85, 0.30, 0.90)

var _trace_history: Array[PackedVector2Array] = []

func _ready() -> void:
	custom_minimum_size = Vector2(460, 360)
	if has_node("/root/SimState"):
		SimState.state_updated.connect(_on_state_updated)

func _on_state_updated() -> void:
	var pts := _compute_screen_points()
	if pts.size() >= 2:
		_trace_history.push_front(pts)
		if _trace_history.size() > MAX_PERSISTENCE_FRAMES:
			_trace_history.resize(MAX_PERSISTENCE_FRAMES)
	queue_redraw()

func _compute_screen_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	if not has_node("/root/SimState") or size.x < 20.0 or size.y < 20.0:
		return points

	var voltages: PackedFloat64Array = SimState.voltage_buffer
	var n := voltages.size()
	if n < 2:
		return points

	var volts_per_div: float = maxf(float(SimState.view_config["volts_per_div"]), 1e-6)
	var full_scale_v := volts_per_div * float(V_DIVS)
	var mid_y := size.y * 0.5
	var px_per_volt := size.y / full_scale_v
	var step_x := size.x / float(n - 1)

	points.resize(n)
	for i in range(n):
		var x := float(i) * step_x
		var y := mid_y - float(voltages[i]) * px_per_volt
		points[i] = Vector2(x, y)
	return points

func _draw() -> void:
	var power_on := true
	var illum := 0.65
	if has_node("/root/SimState"):
		power_on = bool(SimState.view_config.get("power_on", true))
		illum = float(SimState.analog_config.get("scale_illum", 0.65)) if power_on else 0.0

	var glass_col := CRT_UNLIT_COLOR.lerp(CRT_LIT_COLOR, clampf(illum, 0.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, size), glass_col, true)
	if size.x < 20.0 or size.y < 20.0:
		return

	_draw_graticule()
	if power_on:
		_draw_reference_markers()
		_draw_crt_beam()
	_draw_crt_bezel_shadow()

func _draw_graticule() -> void:
	var dx := size.x / float(H_DIVS)
	var dy := size.y / float(V_DIVS)

	for i in range(1, H_DIVS):
		var x := float(i) * dx
		var is_center := (i == H_DIVS / 2)
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), GRATICULE_AXIS_COLOR if is_center else GRATICULE_ETCH_COLOR, 1.6 if is_center else 1.1)

	for j in range(1, V_DIVS):
		var y := float(j) * dy
		var is_center := (j == V_DIVS / 2)
		draw_line(Vector2(0.0, y), Vector2(size.x, y), GRATICULE_AXIS_COLOR if is_center else GRATICULE_ETCH_COLOR, 1.6 if is_center else 1.1)

	# 0.2-division sub-ticks along center vertical & horizontal axes
	var mid_x := size.x * 0.5
	var mid_y := size.y * 0.5
	for i in range(H_DIVS * 5):
		var tx := float(i) * (dx / 5.0)
		draw_line(Vector2(tx, mid_y - 3.5), Vector2(tx, mid_y + 3.5), GRATICULE_AXIS_COLOR, 1.1)
	for j in range(V_DIVS * 5):
		var ty := float(j) * (dy / 5.0)
		draw_line(Vector2(mid_x - 3.5, ty), Vector2(mid_x + 3.5, ty), GRATICULE_AXIS_COLOR, 1.1)

	# Dotted 0% / 10% / 90% / 100% rise-time lines (2 divs from top and bottom)
	for row_div in [2, 6]:
		var ry := float(row_div) * dy
		for d in range(0, int(size.x), 8):
			draw_line(Vector2(float(d), ry), Vector2(float(d) + 3.0, ry), GRATICULE_ETCH_COLOR, 1.0)

func _draw_reference_markers() -> void:
	if not has_node("/root/SimState"):
		return
	var volts_per_div: float = maxf(float(SimState.view_config["volts_per_div"]), 1e-6)
	var full_scale_v := volts_per_div * float(V_DIVS)
	var mid_y := size.y * 0.5
	var px_per_volt := size.y / full_scale_v

	var vert_pos_div: float = SimState.analog_config["vert_pos_div"]
	var trig_level: float = SimState.analog_config["trigger_level"]

	var gnd_y := clampf(mid_y - (vert_pos_div * volts_per_div) * px_per_volt, 6.0, size.y - 6.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(2.0, gnd_y - 4.0),
		Vector2(9.0, gnd_y),
		Vector2(2.0, gnd_y + 4.0)
	]), Color(0.55, 1.0, 0.85, 0.85))

	var trig_y := clampf(mid_y - (trig_level + vert_pos_div * volts_per_div) * px_per_volt, 6.0, size.y - 6.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x - 2.0, trig_y - 4.0),
		Vector2(size.x - 9.0, trig_y),
		Vector2(size.x - 2.0, trig_y + 4.0)
	]), TRIG_MARKER_COLOR)

func _draw_crt_beam() -> void:
	if not has_node("/root/SimState"):
		return
	var current_pts := _compute_screen_points()
	if current_pts.size() < 2:
		return

	var intensity: float = clampf(float(SimState.analog_config["intensity"]), 0.1, 1.0)
	var focus: float = clampf(float(SimState.analog_config["focus"]), 0.1, 1.0)
	var persistence: float = clampf(float(SimState.analog_config["persistence"]), 0.0, 0.95)

	var core_width := lerpf(4.6, 1.6, focus)
	var halo_width := lerpf(13.0, 5.5, focus)

	# P31 Cyan-Green Phosphor Persistence
	if persistence > 0.02 and _trace_history.size() > 1:
		var tau_p := maxf(persistence * 4.5, 0.2)
		for k in range(1, _trace_history.size()):
			var hist_pts := _trace_history[k]
			if hist_pts.size() < 2:
				continue
			var decay := exp(-float(k) / tau_p) * intensity * 0.42
			if decay < 0.02:
				break
			draw_polyline(hist_pts, Color(0.30, 1.0, 0.78, decay), core_width * 1.15, true)

	var halo_col := Color(0.25, 1.0, 0.76, 0.30 * intensity)
	var core_col := Color(0.62, 1.0, 0.88, clampf(0.40 + 0.60 * intensity, 0.15, 1.0))
	draw_polyline(current_pts, halo_col, halo_width, true)
	draw_polyline(current_pts, core_col, core_width, true)

func _draw_crt_bezel_shadow() -> void:
	# Recessed dark CRT tube edge border
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.08, 0.95), false, 5.0)
	draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color(0.02, 0.05, 0.06, 0.55), false, 3.0)
