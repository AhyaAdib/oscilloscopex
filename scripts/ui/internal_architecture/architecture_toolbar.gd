class_name ArchitectureToolbar
extends HBoxContainer

signal view_mode_changed(mode_3d: bool)
signal shell_toggled(show_shell: bool)
signal explosion_changed(factor: float)
signal reset_camera_requested()

var btn_2d: Button
var btn_3d: Button
var btn_shell: Button
var btn_assembled: Button
var btn_cutaway: Button
var btn_exploded: Button
var btn_reset: Button
var exp_slider: HSlider

func _ready() -> void:
	add_theme_constant_override("separation", 6)

	btn_2d = Button.new()
	btn_2d.text = "2D Signal Flow"
	btn_2d.toggle_mode = true
	btn_2d.button_pressed = true
	btn_2d.pressed.connect(func(): _set_mode(false))
	add_child(btn_2d)

	btn_3d = Button.new()
	btn_3d.text = "3D Physical Architecture"
	btn_3d.toggle_mode = true
	btn_3d.button_pressed = false
	btn_3d.pressed.connect(func(): _set_mode(true))
	add_child(btn_3d)

	btn_assembled = Button.new()
	btn_assembled.text = "Assembled"
	btn_assembled.visible = false
	btn_assembled.pressed.connect(func(): _set_explosion(0.0))
	add_child(btn_assembled)

	btn_cutaway = Button.new()
	btn_cutaway.text = "50% Cutaway"
	btn_cutaway.visible = false
	btn_cutaway.pressed.connect(func(): _set_explosion(0.5))
	add_child(btn_cutaway)

	btn_exploded = Button.new()
	btn_exploded.text = "100% Exploded"
	btn_exploded.visible = false
	btn_exploded.pressed.connect(func(): _set_explosion(1.0))
	add_child(btn_exploded)

	exp_slider = HSlider.new()
	exp_slider.min_value = 0.0
	exp_slider.max_value = 1.0
	exp_slider.step = 0.01
	exp_slider.value = 0.5
	exp_slider.custom_minimum_size = Vector2(110, 22)
	exp_slider.visible = false
	exp_slider.value_changed.connect(func(v: float): explosion_changed.emit(v))
	add_child(exp_slider)

	btn_shell = Button.new()
	btn_shell.text = "Ghost Chassis"
	btn_shell.toggle_mode = true
	btn_shell.button_pressed = true
	btn_shell.visible = false
	btn_shell.toggled.connect(func(pressed: bool): shell_toggled.emit(pressed))
	add_child(btn_shell)

	btn_reset = Button.new()
	btn_reset.text = "Reset View"
	btn_reset.visible = false
	btn_reset.pressed.connect(func(): reset_camera_requested.emit())
	add_child(btn_reset)

func _set_explosion(v: float) -> void:
	exp_slider.value = v
	explosion_changed.emit(v)

func _set_mode(is_3d: bool) -> void:
	btn_2d.button_pressed = not is_3d
	btn_3d.button_pressed = is_3d
	for w in [btn_assembled, btn_cutaway, btn_exploded, exp_slider, btn_shell, btn_reset]:
		w.visible = is_3d
	view_mode_changed.emit(is_3d)
