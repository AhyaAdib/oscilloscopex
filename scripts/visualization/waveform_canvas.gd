class_name WaveformCanvas
extends Control

const GRID_COLS := 10
const GRID_ROWS := 8

var _persistence_buffer: Array[PackedVector2Array] = []
var _ch2_persistence: Array[PackedVector2Array] = []
const MAX_PERSISTENCE_FRAMES := 8

func _ready() -> void:
	if has_node("/root/SimState"):
		SimState.state_updated.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0 or h < 10.0:
		return

	var pad_left := 44.0
	var pad_right := 16.0
	var pad_top := 28.0
	var pad_bottom := 26.0

	var plot_rect := Rect2(
		pad_left,
		pad_top,
		maxf(w - pad_left - pad_right, 10.0),
		maxf(h - pad_top - pad_bottom, 10.0)
	)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.05, 1.0), true)

	var power_on := true
	var scale_illum := 0.65
	var intensity := 0.85
	var focus := 0.88
	var persistence := 0.30
	var vert_mode := 1

	if has_node("/root/SimState"):
		power_on = bool(SimState.view_config.get("power_on", true))
		scale_illum = float(SimState.analog_config.get("scale_illum", 0.65))
		intensity = float(SimState.analog_config.get("intensity", 0.85))
		focus = float(SimState.analog_config.get("focus", 0.88))
		persistence = float(SimState.analog_config.get("persistence", 0.30))
		vert_mode = int(SimState.analog_config.get("vert_mode", 1))

	var screen_bg := Color(0.02, 0.11, 0.12, 1.0) if power_on else Color(0.03, 0.06, 0.06, 1.0)
	draw_rect(plot_rect, screen_bg, true)

	_draw_graticule(plot_rect, scale_illum if power_on else 0.15)
	_draw_axis_labels(plot_rect)

	if not power_on:
		_persistence_buffer.clear()
		_ch2_persistence.clear()
		_draw_header_hud(plot_rect, false)
		return

	if not has_node("/root/SimState"):
		return

	var times: PackedFloat64Array = SimState.time_buffer
	if times.size() < 2:
		_draw_header_hud(plot_rect, true)
		return

	var t_start := times[0]
	var t_span := maxf(times[times.size() - 1] - t_start, 1e-9)

	# Draw CH 1 if MODE == CH1 (0) or ALT (1)
	if vert_mode == 0 or vert_mode == 1:
		var pts1 := _build_screen_points(plot_rect, times, SimState.voltage_buffer, t_start, t_span, float(SimState.view_config["volts_per_div"]))
		_draw_phosphor_trace(pts1, _persistence_buffer, Color(0.18, 1.0, 0.72), intensity, focus, persistence)
	else:
		_persistence_buffer.clear()

	# Draw CH 2 if MODE == ALT (1) or CH2 (2)
	if vert_mode == 1 or vert_mode == 2:
		var pts2 := _build_screen_points(plot_rect, times, SimState.ch2_voltage_buffer, t_start, t_span, float(SimState.view_config.get("ch2_volts_per_div", 1.0)))
		_draw_phosphor_trace(pts2, _ch2_persistence, Color(0.35, 0.85, 1.0), intensity, focus, persistence)
	else:
		_ch2_persistence.clear()

	_draw_trigger_marker(plot_rect)
	_draw_header_hud(plot_rect, true)

func _build_screen_points(plot_rect: Rect2, times: PackedFloat64Array, volts: PackedFloat64Array, t_start: float, t_span: float, v_per_div: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := mini(times.size(), volts.size())
	if n < 2:
		return pts
	pts.resize(n)
	var v_half_span := maxf(v_per_div * (float(GRID_ROWS) * 0.5), 1e-6)
	var center_y := plot_rect.position.y + plot_rect.size.y * 0.5
	var half_h := plot_rect.size.y * 0.5

	for i in range(n):
		var nx := clampf((times[i] - t_start) / t_span, 0.0, 1.0)
		var px := plot_rect.position.x + nx * plot_rect.size.x
		var norm_v := float(volts[i]) / v_half_span
		var py := clampf(center_y - norm_v * half_h, plot_rect.position.y, plot_rect.position.y + plot_rect.size.y)
		pts[i] = Vector2(px, py)
	return pts

func _draw_phosphor_trace(pts: PackedVector2Array, persist_hist: Array[PackedVector2Array], base_col: Color, intensity: float, focus: float, persistence: float) -> void:
	if pts.size() < 2:
		return
	var max_hist := int(round(persistence * float(MAX_PERSISTENCE_FRAMES)))
	if max_hist > 0:
		for h_idx in range(persist_hist.size()):
			var age_alpha := (float(h_idx + 1) / float(persist_hist.size() + 1)) * 0.24 * persistence * intensity
			var old_pts := persist_hist[h_idx]
			if old_pts.size() >= 2:
				draw_polyline(old_pts, Color(base_col.r * 0.4, base_col.g * 0.85, base_col.b * 0.75, age_alpha), 2.2, true)
		persist_hist.append(pts)
		while persist_hist.size() > max_hist:
			persist_hist.pop_front()
	else:
		persist_hist.clear()

	var defocus := 1.0 - focus
	var outer_w := 4.0 + defocus * 7.5
	var core_w := 1.4 + defocus * 2.5
	var outer_alpha := clampf(0.14 + intensity * 0.24, 0.05, 0.48)
	var core_alpha := clampf(0.35 + intensity * 0.65, 0.15, 1.0)

	draw_polyline(pts, Color(base_col.r, base_col.g, base_col.b, outer_alpha), outer_w, true)
	draw_polyline(pts, Color(minf(base_col.r + 0.45, 1.0), 1.0, minf(base_col.b + 0.20, 1.0), core_alpha), core_w, true)

func _draw_graticule(rect: Rect2, illum: float) -> void:
	var alpha := clampf(0.10 + illum * 0.36, 0.08, 0.50)
	var minor_col := Color(0.05, 0.18, 0.20, alpha * 0.65)
	var major_col := Color(0.08, 0.30, 0.33, alpha)
	var center_col := Color(0.12, 0.44, 0.48, minf(alpha * 1.35, 0.68))

	var dx := rect.size.x / float(GRID_COLS)
	var dy := rect.size.y / float(GRID_ROWS)

	for c in range(GRID_COLS + 1):
		var x := rect.position.x + float(c) * dx
		var col := center_col if c == GRID_COLS / 2 else major_col
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), col, 1.0)

	for r in range(GRID_ROWS + 1):
		var y := rect.position.y + float(r) * dy
		var col := center_col if r == GRID_ROWS / 2 else major_col
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), col, 1.0)

	var mid_y := rect.position.y + rect.size.y * 0.5
	var mid_x := rect.position.x + rect.size.x * 0.5
	for c in range(GRID_COLS * 5 + 1):
		var tx := rect.position.x + float(c) * (dx / 5.0)
		draw_line(Vector2(tx, mid_y - 3.0), Vector2(tx, mid_y + 3.0), minor_col, 1.0)
	for r in range(GRID_ROWS * 5 + 1):
		var ty := rect.position.y + float(r) * (dy / 5.0)
		draw_line(Vector2(mid_x - 3.0, ty), Vector2(mid_x + 3.0, ty), minor_col, 1.0)

	draw_rect(rect, Color(0.16, 0.36, 0.38, 0.9), false, 2.0)

func _draw_trigger_marker(rect: Rect2) -> void:
	var trig_v := float(SimState.analog_config.get("trigger_level", 0.0))
	var v_per_div := float(SimState.view_config.get("volts_per_div", 1.0))
	var v_half := maxf(v_per_div * (float(GRID_ROWS) * 0.5), 1e-6)
	var center_y := rect.position.y + rect.size.y * 0.5
	var ty := clampf(center_y - (trig_v / v_half) * (rect.size.y * 0.5), rect.position.y, rect.position.y + rect.size.y)

	var col := Color(1.0, 0.78, 0.25, 0.92) if SimState.is_triggered else Color(0.95, 0.35, 0.30, 0.85)
	var rx := rect.position.x + rect.size.x
	draw_colored_polygon(PackedVector2Array([
		Vector2(rx + 2.0, ty),
		Vector2(rx + 10.0, ty - 5.0),
		Vector2(rx + 10.0, ty + 5.0)
	]), col)

func _draw_axis_labels(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var v_per_div := 1.0
	var t_per_div := 0.0005
	if has_node("/root/SimState"):
		v_per_div = float(SimState.view_config["volts_per_div"])
		t_per_div = float(SimState.view_config["time_per_div"])

	var dy := rect.size.y / float(GRID_ROWS)
	for r in range(0, GRID_ROWS + 1, 2):
		var div_offset := (GRID_ROWS / 2) - r
		var v_val := float(div_offset) * v_per_div
		var y := rect.position.y + float(r) * dy + 4.0
		draw_string(font, Vector2(4.0, y), "%.1fV" % v_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.78, 0.78, 0.85))

	var dx := rect.size.x / float(GRID_COLS)
	for c in range(0, GRID_COLS + 1, 2):
		var t_ms := float(c) * t_per_div * 1000.0
		var x := rect.position.x + float(c) * dx - 12.0
		draw_string(font, Vector2(maxf(x, 2.0), rect.position.y + rect.size.y + 15.0), "%.2fms" % t_ms, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.78, 0.78, 0.85))

func _draw_header_hud(rect: Rect2, power_on: bool) -> void:
	var font := ThemeDB.fallback_font
	if not power_on:
		draw_string(font, Vector2(rect.position.x + 8.0, 18.0), "VP-5231A CRT  |  POWER: OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.35, 0.30, 0.95))
		return

	var mode_names := ["CH1 ONLY", "ALT (CH1 + CH2)", "CH2 ONLY"]
	var v_mode := int(SimState.analog_config.get("vert_mode", 1))
	var v_div := float(SimState.view_config["volts_per_div"])
	var v2_div := float(SimState.view_config.get("ch2_volts_per_div", 1.0))
	var t_ms := float(SimState.view_config["time_per_div"]) * 1000.0
	var trig_txt := "TRIG'D" if SimState.is_triggered else "AUTO"
	var hud := "%s  |  CH1: %.2fV/d  CH2: %.2fV/d  |  %.2fms/d  |  [%s]" % [
		mode_names[clampi(v_mode, 0, 2)], v_div, v2_div, t_ms, trig_txt
	]
	draw_string(font, Vector2(rect.position.x + 6.0, 18.0), hud, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.96, 0.78, 0.95))
