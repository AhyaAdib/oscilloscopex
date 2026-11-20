extends Control

func _ready() -> void:
	print("[Oscilloscope Lab] Boot OK | Renderer: ", RenderingServer.get_video_adapter_name())
	_build_bootstrap_ui()

func _build_bootstrap_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.10, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "OSCILLOSCOPE LAB"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.20, 0.90, 0.55, 1.0))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "From Signal Input to CRT Beam and Digital Display — Milestone 0 Verified"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.80, 0.86, 1.0))
	vbox.add_child(subtitle)
