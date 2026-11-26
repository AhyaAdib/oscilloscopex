class_name ArchitectureToolbar
extends HBoxContainer

signal view_mode_changed(mode_3d: bool)
signal render_style_changed(is_blueprint: bool)
signal explosion_changed(factor: float)
signal camera_preset_selected(preset_key: String)
signal callouts_toggled(show_pins: bool)
signal guides_toggled(show_axes: bool)
signal isolate_toggled(isolate: bool)

var btn_2d: Button
var btn_3d: Button
var btn_style: Button
var preset_opt: OptionButton
var btn_0: Button
var btn_72: Button
var btn_100: Button
var btn_anim: Button
var exp_slider: HSlider
var btn_pins: Button
var btn_axes: Button
var btn_isolate: Button
var _is_bp := true

func _ready() -> void:
	add_theme_constant_override("separation", 5)

	btn_2d = Button.new()
	btn_2d.text = "2D Flow"
	btn_2d.toggle_mode = true
	btn_2d.button_pressed = true
	btn_2d.pressed.connect(func(): _set_mode(false))
	add_child(btn_2d)

	btn_3d = Button.new()
	btn_3d.text = "3D CAD Exploded (55 Parts)"
	btn_3d.toggle_mode = true
	btn_3d.pressed.connect(func(): _set_mode(true))
	add_child(btn_3d)

	btn_style = Button.new()
	btn_style.text = "Style: Service Manual"
	btn_style.visible = false
	btn_style.pressed.connect(func():
		_is_bp = not _is_bp
		btn_style.text = "Style: Service Manual" if _is_bp else "Style: Hardware 3D"
		render_style_changed.emit(_is_bp)
	)
	add_child(btn_style)

	preset_opt = OptionButton.new()
	preset_opt.visible = false
	for label in ["Isometric", "Front Panel", "CRT & Atten", "Internal PCBs", "Rear & Power", "Top-Down"]:
		preset_opt.add_item(label)
	preset_opt.item_selected.connect(func(idx: int):
		var keys := ["iso", "front", "crt", "pcb", "rear", "top"]
		camera_preset_selected.emit(keys[idx])
	)
	add_child(preset_opt)

	btn_0 = Button.new()
	btn_0.text = "0%"
	btn_0.visible = false
	btn_0.pressed.connect(func(): _set_exp(0.0))
	add_child(btn_0)

	btn_72 = Button.new()
	btn_72.text = "72%"
	btn_72.visible = false
	btn_72.pressed.connect(func(): _set_exp(0.72))
	add_child(btn_72)

	btn_100 = Button.new()
	btn_100.text = "100%"
	btn_100.visible = false
	btn_100.pressed.connect(func(): _set_exp(1.0))
	add_child(btn_100)

	exp_slider = HSlider.new()
	exp_slider.min_value = 0.0
	exp_slider.max_value = 1.0
	exp_slider.step = 0.01
	exp_slider.value = 0.72
	exp_slider.custom_minimum_size = Vector2(95, 22)
	exp_slider.visible = false
	exp_slider.value_changed.connect(func(v: float): explosion_changed.emit(v))
	add_child(exp_slider)

	btn_pins = Button.new()
	btn_pins.text = "#01 Pins"
	btn_pins.toggle_mode = true
	btn_pins.button_pressed = true
	btn_pins.visible = false
	btn_pins.toggled.connect(func(p: bool): callouts_toggled.emit(p))
	add_child(btn_pins)

	btn_axes = Button.new()
	btn_axes.text = "Axes"
	btn_axes.toggle_mode = true
	btn_axes.button_pressed = true
	btn_axes.visible = false
	btn_axes.toggled.connect(func(p: bool): guides_toggled.emit(p))
	add_child(btn_axes)

	btn_isolate = Button.new()
	btn_isolate.text = "Isolate"
	btn_isolate.toggle_mode = true
	btn_isolate.button_pressed = false
	btn_isolate.visible = false
	btn_isolate.toggled.connect(func(p: bool): isolate_toggled.emit(p))
	add_child(btn_isolate)

func _set_exp(v: float) -> void:
	exp_slider.value = v
	explosion_changed.emit(v)

func _set_mode(is_3d: bool) -> void:
	btn_2d.button_pressed = not is_3d
	btn_3d.button_pressed = is_3d
	for w in [btn_style, preset_opt, btn_0, btn_72, btn_100, exp_slider, btn_pins, btn_axes, btn_isolate]:
		w.visible = is_3d
	view_mode_changed.emit(is_3d)
