
class_name RotaryKnob
extends Control

signal value_changed(new_value: float)

@export var label_text := "KNOB"
@export var min_value := 0.0
@export var max_value := 1.0
@export var step := 0.05
@export var value := 0.5
@export var accent_cap_color := Color(0.22, 0.21, 0.20, 1.0) # Charcoal or beige/red variable cap
@export var discrete_labels: Array[String] = []

var _dragging := false
var _drag_start_y := 0.0
var _drag_start_val := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(76, 84)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_knob_value(v: float, emit := false) -> void:
	var snapped_v := snappedf(clampf(v, min_value, max_value), step)
	if is_equal_approx(snapped_v, value):
		return
	value = snapped_v
	queue_redraw()
	if emit:
		value_changed.emit(value)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_start_y = mb.position.y
				_drag_start_val = value
			else:
				_dragging = false
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_knob_value(value + step, true)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_knob_value(value - step, true)
	elif event is InputEventMouseMotion and _dragging:
		var dy := _drag_start_y - (event as InputEventMouseMotion).position.y
		var span := maxf(max_value - min_value, 1e-6)
		var delta_val := (dy / 110.0) * span
		set_knob_value(_drag_start_val + delta_val, true)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var center := Vector2(w * 0.5, 42.0)
	var outer_r := 21.0

	# Top silk-screen label
	draw_string(font, Vector2(0, 11), label_text, HORIZONTAL_ALIGNMENT_CENTER, w, 10, Color(0.14, 0.14, 0.13, 1.0))

	# Outer dial ticks (-135 deg to +135 deg)
	var start_ang := deg_to_rad(-225.0)
	var end_ang := deg_to_rad(45.0)
	var tick_count := discrete_labels.size() if discrete_labels.size() > 1 else 11
	for i in range(tick_count):
		var frac := float(i) / float(maxi(tick_count - 1, 1))
		var ang := lerpf(start_ang, end_ang, frac)
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(center + dir * (outer_r + 2.0), center + dir * (outer_r + 6.0), Color(0.18, 0.18, 0.17, 0.9), 1.3)

	# Skirt ring + shadow
	draw_circle(center + Vector2(1.5, 2.5), outer_r + 1.0, Color(0.08, 0.08, 0.08, 0.35))
	draw_circle(center, outer_r, Color(0.78, 0.76, 0.72, 1.0))
	draw_arc(center, outer_r, 0.0, TAU, 32, Color(0.22, 0.22, 0.21, 1.0), 1.2)

	# Fluted charcoal body
	var body_r := outer_r - 3.5
	draw_circle(center, body_r, Color(0.17, 0.16, 0.16, 1.0))
	for f in range(12):
		var fa := float(f) * (TAU / 12.0)
		var fdir := Vector2(cos(fa), sin(fa))
		draw_line(center + fdir * (body_r - 2.5), center + fdir * body_r, Color(0.32, 0.31, 0.30, 0.9), 1.5)

	# Inner cap
	draw_circle(center, body_r * 0.56, accent_cap_color)
	draw_arc(center, body_r * 0.56, 0.0, TAU, 24, Color(0.10, 0.10, 0.10, 0.8), 1.0)

	# Pointer indicator line
	var norm := clampf((value - min_value) / maxf(max_value - min_value, 1e-6), 0.0, 1.0)
	var cur_ang := lerpf(start_ang, end_ang, norm)
	var p_dir := Vector2(cos(cur_ang), sin(cur_ang))
	draw_line(center + p_dir * 3.0, center + p_dir * (outer_r - 1.0), Color(0.96, 0.95, 0.92, 1.0), 2.2)

	# Bottom readout value
	var readout := ""
	if discrete_labels.size() > 0:
		var idx := clampi(int(round(norm * float(discrete_labels.size() - 1))), 0, discrete_labels.size() - 1)
		readout = discrete_labels[idx]
	else:
		readout = "%.2f" % value
	draw_string(font, Vector2(0, size.y - 4.0), readout, HORIZONTAL_ALIGNMENT_CENTER, w, 10, Color(0.12, 0.15, 0.18, 1.0))
