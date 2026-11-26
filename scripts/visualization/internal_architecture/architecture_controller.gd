class_name ArchitectureController
extends Control

signal part_selected(part_cfg: Dictionary)
signal drawer_visibility_changed(is_visible: bool)

const PRESETS := {
	"iso":   {"pos": Vector3(0.62, 0.40, 0.68), "target": Vector3(0.0, 0.0, 0.02)},
	"front": {"pos": Vector3(0.0, 0.02, 0.88),  "target": Vector3(0.0, 0.0, 0.13)},
	"crt":   {"pos": Vector3(-0.46, 0.22, 0.44),"target": Vector3(-0.10, 0.02, 0.08)},
	"pcb":   {"pos": Vector3(0.68, 0.19, 0.10), "target": Vector3(0.09, 0.01, 0.01)},
	"rear":  {"pos": Vector3(-0.55, 0.31, -0.72),"target": Vector3(0.0, -0.02, -0.13)},
	"top":   {"pos": Vector3(0.01, 0.96, 0.04), "target": Vector3(0.0, 0.0, 0.0)}
}

var _view_3d_container: Control
var _sub_viewport: SubViewport
var _viewport_rect: TextureRect
var _callout_layer: Control
var _floating_card: PanelContainer
var _float_title: Label
var _float_sub: Label
var _float_flow: Label

var _drawer_panel: PanelContainer
var _stage_graph_canvas: Control
var _drawer_plate_lbl: Label
var _drawer_wb_lbl: Label
var _ch_opt: OptionButton
var _selected_channel := 1
var _step_cards := {}

var _right_inspector: PanelContainer
var _insp_badge: Label
var _insp_title: Label
var _insp_sub: Label
var _insp_desc: Label
var _insp_upstream_box: VBoxContainer
var _insp_downstream_box: VBoxContainer
var _insp_service: Label

var _camera: Camera3D
var _env: Environment
var _assembly_root: InternalAssemblyRoot
var _badges := {}

# Smooth inertial camera state
var _yaw := 0.72
var _pitch := -0.40
var _dist := 1.02
var _target := Vector3(0.0, 0.0, 0.02)
var _goal_yaw := 0.72
var _goal_pitch := -0.40
var _goal_dist := 1.02
var _goal_target := Vector3(0.0, 0.0, 0.02)
var _yaw_vel := 0.0
var _pitch_vel := 0.0
var _dist_vel := 0.0

var _orbiting := false
var _panning := false
var _last_mouse := Vector2.ZERO
var _press_pos := Vector2.ZERO
var _show_pins := true
var _selected_id := -1
var _hovered_id := -1
var _isolate := false
var _beam_phase := 0.0

func build_3d_layer(parent_host: Control) -> Control:
	_view_3d_container = Control.new()
	_view_3d_container.name = "Arch3DViewContainer"
	_view_3d_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view_3d_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view_3d_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view_3d_container.visible = false
	_view_3d_container.gui_input.connect(_on_viewport_gui_input)
	parent_host.add_child(_view_3d_container)

	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "Arch3DSubViewport"
	_sub_viewport.own_world_3d = true
	_sub_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_sub_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_sub_viewport.size = Vector2i(720, 440)
	_view_3d_container.add_child(_sub_viewport)

	_viewport_rect = TextureRect.new()
	_viewport_rect.name = "Arch3DViewportRect"
	_viewport_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewport_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_viewport_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport_rect.texture = _sub_viewport.get_texture()
	_view_3d_container.add_child(_viewport_rect)

	_callout_layer = Control.new()
	_callout_layer.name = "CalloutBadgeLayer"
	_callout_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_callout_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view_3d_container.add_child(_callout_layer)

	_build_left_flow_tree_drawer(_view_3d_container)
	_build_right_service_inspector(_view_3d_container)

	var we := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.075, 0.105, 0.155)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color.WHITE
	_env.ambient_light_energy = 0.72
	we.environment = _env
	_sub_viewport.add_child(we)

	var key_light := DirectionalLight3D.new()
	key_light.position = Vector3(0.7, 1.1, 0.9)
	key_light.look_at_from_position(key_light.position, Vector3.ZERO, Vector3.UP)
	key_light.light_energy = 0.85
	_sub_viewport.add_child(key_light)

	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.near = 0.01
	_camera.far = 20.0
	_sub_viewport.add_child(_camera)
	_camera.current = true

	_assembly_root = InternalAssemblyRoot.new()
	_sub_viewport.add_child(_assembly_root)

	_build_callout_badges()
	_build_floating_part_card(_callout_layer)

	set_camera_preset("iso")
	_yaw = _goal_yaw
	_pitch = _goal_pitch
	_dist = _goal_dist
	_target = _goal_target
	_update_camera()

	_view_3d_container.resized.connect(_on_container_resized)

	if is_inside_tree() and has_node("/root/SimState"):
		SimState.state_updated.connect(_on_sim_state_updated)
	return _view_3d_container

func _make_card_style(bg: Color, border: Color, radius := 8, pad := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	return sb

func _build_floating_part_card(parent: Control) -> void:
	_floating_card = PanelContainer.new()
	_floating_card.visible = false
	_floating_card.z_index = 10
	_floating_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floating_card.custom_minimum_size = Vector2(248, 0)
	_floating_card.add_theme_stylebox_override("panel", _make_card_style(Color(0.055, 0.082, 0.125, 0.97), Color(0.24, 0.78, 0.98, 0.95), 8, 9))
	parent.add_child(_floating_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	_floating_card.add_child(vb)

	_float_title = Label.new()
	_float_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_float_title.add_theme_font_size_override("font_size", 11)
	_float_title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	vb.add_child(_float_title)

	_float_sub = Label.new()
	_float_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_float_sub.add_theme_font_size_override("font_size", 10)
	_float_sub.add_theme_color_override("font_color", Color(0.65, 0.78, 0.88))
	vb.add_child(_float_sub)

	_float_flow = Label.new()
	_float_flow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_float_flow.add_theme_font_size_override("font_size", 10)
	_float_flow.add_theme_color_override("font_color", Color(0.42, 0.98, 0.74))
	vb.add_child(_float_flow)

func _build_left_flow_tree_drawer(parent: Control) -> void:
	_drawer_panel = PanelContainer.new()
	_drawer_panel.name = "FlowTreeScopeLabDrawer"
	_drawer_panel.z_index = 20
	_drawer_panel.anchor_top = 0.0
	_drawer_panel.anchor_bottom = 1.0
	_drawer_panel.offset_left = 10.0
	_drawer_panel.offset_top = 10.0
	_drawer_panel.offset_right = 306.0
	_drawer_panel.offset_bottom = -10.0
	_drawer_panel.clip_contents = true
	_drawer_panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.065, 0.092, 0.135, 0.96), Color(0.18, 0.30, 0.42, 0.95), 10, 10))
	parent.add_child(_drawer_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_drawer_panel.add_child(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	scroll.add_child(vb)

	var top_hb := HBoxContainer.new()
	vb.add_child(top_hb)
	var title_vb := VBoxContainer.new()
	title_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(title_vb)

	var hdr := Label.new()
	hdr.text = "ARCHITECTURE FLOW TREE"
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	title_vb.add_child(hdr)

	var sub_hdr := Label.new()
	sub_hdr.text = "Click any stage or 3D part (empty space = 100% view)"
	sub_hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_hdr.add_theme_font_size_override("font_size", 10)
	sub_hdr.add_theme_color_override("font_color", Color(0.60, 0.72, 0.82))
	title_vb.add_child(sub_hdr)

	var hide_btn := Button.new()
	hide_btn.text = "Hide <"
	hide_btn.pressed.connect(func():
		set_drawer_visible(false)
		drawer_visibility_changed.emit(false)
	)
	top_hb.add_child(hide_btn)

	# Live Signal & CRT Beam Lab Card (linked directly to 3D Workbench parameters)
	var lab_card := PanelContainer.new()
	lab_card.add_theme_stylebox_override("panel", _make_card_style(Color(0.045, 0.068, 0.105, 1.0), Color(0.15, 0.28, 0.40, 1.0), 8, 8))
	vb.add_child(lab_card)
	var lab_vb := VBoxContainer.new()
	lab_vb.add_theme_constant_override("separation", 5)
	lab_card.add_child(lab_vb)

	var lab_hdr_hb := HBoxContainer.new()
	lab_vb.add_child(lab_hdr_hb)
	var lab_lbl := Label.new()
	lab_lbl.text = "3D WORKBENCH LIVE LINK"
	lab_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab_lbl.add_theme_font_size_override("font_size", 10)
	lab_lbl.add_theme_color_override("font_color", Color(0.32, 0.86, 0.98))
	lab_hdr_hb.add_child(lab_lbl)

	_ch_opt = OptionButton.new()
	_ch_opt.add_item("CH1 (FG1)")
	_ch_opt.add_item("CH2 (FG2)")
	_ch_opt.selected = 0
	_ch_opt.item_selected.connect(func(idx: int):
		_selected_channel = idx + 1
		_on_sim_state_updated()
	)
	lab_hdr_hb.add_child(_ch_opt)

	_stage_graph_canvas = Control.new()
	_stage_graph_canvas.custom_minimum_size = Vector2(248, 108)
	_stage_graph_canvas.draw.connect(_draw_stage_waveform)
	lab_vb.add_child(_stage_graph_canvas)

	_drawer_plate_lbl = Label.new()
	_drawer_plate_lbl.text = "Y-Plate: ±28.0V | Synced to Workbench"
	_drawer_plate_lbl.add_theme_font_size_override("font_size", 10)
	_drawer_plate_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.72))
	lab_vb.add_child(_drawer_plate_lbl)

	_drawer_wb_lbl = Label.new()
	_drawer_wb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_drawer_wb_lbl.add_theme_font_size_override("font_size", 10)
	_drawer_wb_lbl.add_theme_color_override("font_color", Color(0.75, 0.86, 0.94))
	lab_vb.add_child(_drawer_wb_lbl)

	# Styled Guided Flow Path Cards
	for p_idx in range(ArchitectureRegistry.FLOW_PATHS.size()):
		var path_cfg: Dictionary = ArchitectureRegistry.FLOW_PATHS[p_idx]
		var path_box := PanelContainer.new()
		path_box.add_theme_stylebox_override("panel", _make_card_style(Color(0.055, 0.080, 0.120, 0.95), Color(0.16, 0.28, 0.40, 0.90), 8, 8))
		vb.add_child(path_box)

		var p_vb := VBoxContainer.new()
		p_vb.add_theme_constant_override("separation", 6)
		path_box.add_child(p_vb)

		var p_title := Label.new()
		p_title.text = "PATH %02d   %s" % [p_idx + 1, path_cfg["title"]]
		p_title.add_theme_font_size_override("font_size", 11)
		p_title.add_theme_color_override("font_color", Color(0.32, 0.86, 0.98))
		p_vb.add_child(p_title)

		var steps: Array = path_cfg["steps"]
		for s_idx in range(steps.size()):
			var step: Dictionary = steps[s_idx]
			var pid: int = int(step["pid"])
			var card := PanelContainer.new()
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			card.add_theme_stylebox_override("panel", _make_card_style(Color(0.08, 0.115, 0.17, 1.0), Color(0.20, 0.30, 0.42, 1.0), 6, 7))
			card.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
					_select_part(pid)
					_focus_part_camera(pid)
			)
			p_vb.add_child(card)
			_step_cards[pid] = card

			var c_vb := VBoxContainer.new()
			c_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c_vb.add_theme_constant_override("separation", 2)
			card.add_child(c_vb)

			var top_row := HBoxContainer.new()
			top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c_vb.add_child(top_row)

			var st_lbl := Label.new()
			st_lbl.text = "STEP %02d  ·  #%02d" % [s_idx + 1, pid]
			st_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			st_lbl.add_theme_font_size_override("font_size", 10)
			st_lbl.add_theme_color_override("font_color", Color(0.35, 0.84, 0.98))
			top_row.add_child(st_lbl)

			var tag_lbl := Label.new()
			tag_lbl.text = step["tag"]
			tag_lbl.add_theme_font_size_override("font_size", 9)
			tag_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.94))
			top_row.add_child(tag_lbl)

			var name_lbl := Label.new()
			name_lbl.text = step["label"]
			name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_lbl.add_theme_font_size_override("font_size", 11)
			name_lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
			c_vb.add_child(name_lbl)

			var hint_lbl := Label.new()
			hint_lbl.text = step["hint"]
			hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint_lbl.add_theme_font_size_override("font_size", 10)
			hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.74, 0.82))
			c_vb.add_child(hint_lbl)

func _build_right_service_inspector(parent: Control) -> void:
	_right_inspector = PanelContainer.new()
	_right_inspector.name = "RightServiceManualInspector"
	_right_inspector.z_index = 20
	_right_inspector.visible = false
	_right_inspector.clip_contents = true
	_right_inspector.anchor_left = 1.0
	_right_inspector.anchor_right = 1.0
	_right_inspector.anchor_top = 0.0
	_right_inspector.anchor_bottom = 1.0
	_right_inspector.offset_left = -336.0
	_right_inspector.offset_right = -10.0
	_right_inspector.offset_top = 10.0
	_right_inspector.offset_bottom = -10.0
	_right_inspector.add_theme_stylebox_override("panel", _make_card_style(Color(0.965, 0.972, 0.984, 0.98), Color(0.78, 0.84, 0.90, 1.0), 10, 12))
	parent.add_child(_right_inspector)

	var main_vb := VBoxContainer.new()
	main_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_theme_constant_override("separation", 7)
	_right_inspector.add_child(main_vb)

	# Header Row (always visible inside 326px width)
	var hdr_hb := HBoxContainer.new()
	hdr_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vb.add_child(hdr_hb)
	_insp_badge = Label.new()
	_insp_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_insp_badge.add_theme_font_size_override("font_size", 11)
	_insp_badge.add_theme_color_override("font_color", Color(0.02, 0.45, 0.72))
	hdr_hb.add_child(_insp_badge)

	var close_btn := Button.new()
	close_btn.text = "Close ✕"
	close_btn.pressed.connect(func(): _select_part(-1))
	hdr_hb.add_child(close_btn)

	_insp_title = Label.new()
	_insp_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_title.custom_minimum_size = Vector2(290, 0)
	_insp_title.add_theme_font_size_override("font_size", 14)
	_insp_title.add_theme_color_override("font_color", Color(0.08, 0.12, 0.18))
	main_vb.add_child(_insp_title)

	_insp_sub = Label.new()
	_insp_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_sub.custom_minimum_size = Vector2(290, 0)
	_insp_sub.add_theme_font_size_override("font_size", 11)
	_insp_sub.add_theme_color_override("font_color", Color(0.32, 0.42, 0.52))
	main_vb.add_child(_insp_sub)

	main_vb.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vb.add_child(scroll)

	var body_vb := VBoxContainer.new()
	body_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vb.add_theme_constant_override("separation", 9)
	scroll.add_child(body_vb)

	var fn_hdr := Label.new()
	fn_hdr.text = "TECHNICAL FUNCTION & CONSTRUCTION"
	fn_hdr.add_theme_font_size_override("font_size", 10)
	fn_hdr.add_theme_color_override("font_color", Color(0.35, 0.45, 0.55))
	body_vb.add_child(fn_hdr)

	_insp_desc = Label.new()
	_insp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_desc.custom_minimum_size = Vector2(280, 0)
	_insp_desc.add_theme_font_size_override("font_size", 11)
	_insp_desc.add_theme_color_override("font_color", Color(0.16, 0.22, 0.28))
	body_vb.add_child(_insp_desc)

	# Circuit Signal & Power Flow Card
	var flow_card := PanelContainer.new()
	flow_card.add_theme_stylebox_override("panel", _make_card_style(Color(0.92, 0.945, 0.97, 1.0), Color(0.80, 0.85, 0.91, 1.0), 8, 8))
	body_vb.add_child(flow_card)
	var f_vb := VBoxContainer.new()
	f_vb.add_theme_constant_override("separation", 5)
	flow_card.add_child(f_vb)

	var f_hdr := Label.new()
	f_hdr.text = "⇅ CIRCUIT SIGNAL & POWER FLOW"
	f_hdr.add_theme_font_size_override("font_size", 10)
	f_hdr.add_theme_color_override("font_color", Color(0.15, 0.28, 0.42))
	f_vb.add_child(f_hdr)

	var up_lbl := Label.new()
	up_lbl.text = "UPSTREAM (FROM):"
	up_lbl.add_theme_font_size_override("font_size", 9)
	up_lbl.add_theme_color_override("font_color", Color(0.72, 0.42, 0.05))
	f_vb.add_child(up_lbl)

	_insp_upstream_box = VBoxContainer.new()
	_insp_upstream_box.add_theme_constant_override("separation", 4)
	f_vb.add_child(_insp_upstream_box)

	var dn_lbl := Label.new()
	dn_lbl.text = "DOWNSTREAM (TO):"
	dn_lbl.add_theme_font_size_override("font_size", 9)
	dn_lbl.add_theme_color_override("font_color", Color(0.06, 0.52, 0.34))
	f_vb.add_child(dn_lbl)

	_insp_downstream_box = VBoxContainer.new()
	_insp_downstream_box.add_theme_constant_override("separation", 4)
	f_vb.add_child(_insp_downstream_box)

	# Service & Calibration Note Amber Box
	var srv_card := PanelContainer.new()
	srv_card.add_theme_stylebox_override("panel", _make_card_style(Color(0.99, 0.95, 0.86, 1.0), Color(0.94, 0.72, 0.28, 1.0), 8, 8))
	body_vb.add_child(srv_card)
	_insp_service = Label.new()
	_insp_service.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_service.custom_minimum_size = Vector2(275, 0)
	_insp_service.add_theme_font_size_override("font_size", 11)
	_insp_service.add_theme_color_override("font_color", Color(0.45, 0.26, 0.04))
	srv_card.add_child(_insp_service)

	# Footer Navigation: < Prev | Center | Next > (fits cleanly inside 302px inner width)
	var nav_hb := HBoxContainer.new()
	nav_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_hb.add_theme_constant_override("separation", 6)
	main_vb.add_child(nav_hb)

	var prev_btn := Button.new()
	prev_btn.text = "← Prev"
	prev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev_btn.pressed.connect(func():
		var nxt := 55 if _selected_id <= 1 else _selected_id - 1
		_select_part(nxt)
		_focus_part_camera(nxt)
	)
	nav_hb.add_child(prev_btn)

	var center_btn := Button.new()
	center_btn.text = "Focus"
	center_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_btn.pressed.connect(func(): _focus_part_camera(_selected_id))
	nav_hb.add_child(center_btn)

	var next_btn := Button.new()
	next_btn.text = "Next →"
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_btn.pressed.connect(func():
		var nxt := 1 if _selected_id >= 55 else _selected_id + 1
		_select_part(nxt)
		_focus_part_camera(nxt)
	)
	nav_hb.add_child(next_btn)

func _build_callout_badges() -> void:
	for rec in _assembly_root.part_records:
		var pid: int = rec["id"]
		var btn := Button.new()
		btn.text = "#%02d" % pid
		btn.custom_minimum_size = Vector2(30, 18)
		btn.add_theme_font_size_override("font_size", 10)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pressed.connect(func(): _select_part(pid))
		_callout_layer.add_child(btn)
		_badges[pid] = btn

func set_active(active: bool) -> void:
	if _view_3d_container == null:
		return
	_view_3d_container.visible = active
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	set_process(active)
	if active:
		_camera.current = true
		call_deferred("_on_container_resized")
		_on_sim_state_updated()

func set_drawer_visible(vis: bool) -> void:
	if _drawer_panel != null:
		_drawer_panel.visible = vis

func set_render_style(is_blueprint: bool) -> void:
	if _env != null:
		_env.background_color = Color(0.957, 0.965, 0.976) if is_blueprint else Color(0.075, 0.105, 0.155)
		_env.ambient_light_energy = 0.92 if is_blueprint else 0.72
	if _assembly_root != null:
		_assembly_root.set_blueprint_mode(is_blueprint)

func set_explosion_factor(factor: float) -> void:
	if _assembly_root != null:
		_assembly_root.apply_explosion_factor(factor)

func set_callouts_visible(vis: bool) -> void:
	_show_pins = vis
	if _callout_layer != null:
		_callout_layer.visible = vis

func set_guides_visible(vis: bool) -> void:
	if _assembly_root != null:
		_assembly_root.set_guides_visible(vis)

func set_signal_flow_visible(vis: bool) -> void:
	if _assembly_root != null:
		_assembly_root.set_signal_flow_visible(vis)

func set_ghost_shell_visible(vis: bool) -> void:
	if _assembly_root != null:
		_assembly_root.set_shell_visible(vis)

func reset_camera() -> void:
	set_camera_preset("iso")

func set_isolate_selected(iso: bool) -> void:
	_isolate = iso
	if _assembly_root != null:
		_assembly_root.set_selection(_selected_id, _hovered_id, _isolate)

func set_camera_preset(key: String) -> void:
	var p: Dictionary = PRESETS.get(key, PRESETS["iso"])
	var pos: Vector3 = p["pos"]
	_goal_target = p["target"]
	var off := pos - _goal_target
	_goal_dist = off.length()
	_goal_yaw = atan2(off.x, off.z)
	_goal_pitch = -asin(clampf(off.y / maxf(0.01, _goal_dist), -0.98, 0.98))
	_yaw_vel = 0.0
	_pitch_vel = 0.0
	_dist_vel = 0.0

func _focus_part_camera(pid: int) -> void:
	if _assembly_root == null or pid <= 0:
		return
	for rec in _assembly_root.part_records:
		if int(rec["id"]) == pid:
			var n: Node3D = rec["node"]
			_goal_target = n.position
			_goal_dist = clampf(_goal_dist, 0.44, 0.72)
			break

func _get_active_sim_node() -> String:
	var active_pid := _selected_id if _selected_id > 0 else (_hovered_id if _hovered_id > 0 else 24)
	var fl := ArchitectureRegistry.get_flow(active_pid)
	return str(fl.get("node", "N3_ATTENUATOR"))

func _on_sim_state_updated() -> void:
	if _stage_graph_canvas != null:
		_stage_graph_canvas.queue_redraw()
	if not is_inside_tree() or not has_node("/root/SimState") or _drawer_plate_lbl == null:
		return
	var sim_node := _get_active_sim_node()
	var v_div := float(SimState.view_config.get("volts_per_div", 1.0))
	var t_div_ms := float(SimState.view_config.get("time_per_div", 0.0005)) * 1000.0
	var coup: String = AnalogScopeEngine.COUPLING_NAMES[int(SimState.analog_config.get("coupling", 0))]
	var fg: Dictionary = SimState.fg_channels.get(_selected_channel, SimState.fg_channels[1])
	var freq := float(fg.get("frequency", 1000.0))
	var amp := float(fg.get("amplitude", 2.0))
	var wf_name: String = ["Sine", "Square", "Triangle", "Sawtooth"][int(fg.get("waveform", 0)) % 4]

	if sim_node in ["LV_RAIL", "HV_RAIL"]:
		_drawer_plate_lbl.text = "-1.5kV / +2kV HV Rail" if sim_node == "HV_RAIL" else "±12V / +140V Regulated"
	else:
		var st := SimState.get_node_stats(sim_node)
		var vpp_ch := float(st["v_pp"]) * (amp / maxf(0.1, float(SimState.fg_channels[1].get("amplitude", 2.0))))
		_drawer_plate_lbl.text = "Y-Plate: ±%.1fV | Vpp: %.2fV" % [clampf(vpp_ch * 7.0, 0.0, 56.0), vpp_ch]

	if _drawer_wb_lbl != null:
		_drawer_wb_lbl.text = "CH%d: %s %.0fHz %.1fVpk | %.2fV/div · %.2fms/div · %s" % [
			_selected_channel, wf_name, freq, amp, v_div, t_div_ms, coup
		]

func _draw_stage_waveform() -> void:
	if _stage_graph_canvas == null:
		return
	var sz := _stage_graph_canvas.size
	_stage_graph_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.025, 0.065, 0.088, 1.0), true)
	_stage_graph_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.16, 0.40, 0.52, 1.0), false, 1.0)

	var grid_col := Color(0.11, 0.25, 0.30, 0.85)
	for c in range(1, 10):
		var gx := sz.x * float(c) / 10.0
		_stage_graph_canvas.draw_line(Vector2(gx, 0), Vector2(gx, sz.y), grid_col, 1.0)
	for r in range(1, 8):
		var gy := sz.y * float(r) / 8.0
		_stage_graph_canvas.draw_line(Vector2(0, gy), Vector2(sz.x, gy), grid_col, 1.0)

	var mid_y := sz.y * 0.5
	_stage_graph_canvas.draw_line(Vector2(0, mid_y), Vector2(sz.x, mid_y), Color(0.22, 0.48, 0.54, 1.0), 1.2)

	if not is_inside_tree() or not has_node("/root/SimState") or not bool(SimState.view_config.get("power_on", true)):
		return

	var sim_node := _get_active_sim_node()
	var font := ThemeDB.fallback_font

	if sim_node in ["LV_RAIL", "HV_RAIL"]:
		var is_hv := (sim_node == "HV_RAIL")
		var pts := PackedVector2Array()
		for i in range(65):
			var u := float(i) / 64.0
			var ripple := sin(u * TAU * 4.0 + _beam_phase * TAU) * (3.0 if is_hv else 1.2)
			pts.append(Vector2(u * sz.x, (sz.y * 0.72 if is_hv else sz.y * 0.28) + ripple))
		_stage_graph_canvas.draw_polyline(pts, Color(1.0, 0.42, 0.34) if is_hv else Color(1.0, 0.82, 0.25), 2.0, true)
		_stage_graph_canvas.draw_string(font, Vector2(6, 13), "CH%d · %s" % [_selected_channel, sim_node], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.96, 0.90, 0.72))
		return

	# Live parametric waveform directly driven by 3D Workbench CH1/CH2 settings & SimState
	var fg: Dictionary = SimState.fg_channels.get(_selected_channel, SimState.fg_channels[1])
	var wf := int(fg.get("waveform", 0))
	var freq := float(fg.get("frequency", 1000.0))
	var amp := float(fg.get("amplitude", 2.0))
	var dc_off := float(fg.get("offset", 0.0))
	var noise_v := float(fg.get("noise", 0.0))
	var v_div := maxf(float(SimState.view_config.get("volts_per_div", 1.0)), 0.05)
	var t_div := maxf(float(SimState.view_config.get("time_per_div", 0.0005)), 0.00001)
	var vert_pos := float(SimState.view_config.get("vert_pos_div", 0.0))
	var coup := int(SimState.analog_config.get("coupling", 0)) # 0=DC, 1=AC, 2=GND

	var cycles := clampf(freq * t_div * 10.0, 0.8, 6.0)
	var stage_gain := 1.0
	if sim_node == "N3_ATTENUATOR":
		stage_gain = 0.5
	elif sim_node == "N4_PREAMP":
		stage_gain = 1.35

	var pts := PackedVector2Array()
	var n_pts := 110
	pts.resize(n_pts)
	var px_per_div_y := sz.y / 8.0
	for i in range(n_pts):
		var u := float(i) / float(n_pts - 1)
		var ph := fmod(u * cycles + _beam_phase, 1.0)
		var v := 0.0
		if coup != 2:
			match wf:
				0: v = sin(ph * TAU)
				1: v = 1.0 if ph < 0.5 else -1.0
				2: v = 4.0 * absf(ph - 0.5) - 1.0
				3: v = 2.0 * ph - 1.0
			v = v * amp * stage_gain
			if coup == 0:
				v += dc_off * stage_gain
			if noise_v > 0.001:
				v += sin(u * 97.0 + _beam_phase * 31.0) * noise_v * 0.5
		if sim_node == "N8_SWEEP":
			v = (2.0 * u - 1.0) * v_div * 2.8
		elif sim_node == "N7_TRIGGER":
			v = v_div * 2.2 if sin(ph * TAU) >= 0.0 else -v_div * 2.2
		var divs_y := (v / v_div) + vert_pos
		var py := clampf(mid_y - divs_y * px_per_div_y, 2.0, sz.y - 2.0)
		pts[i] = Vector2(u * sz.x, py)

	var trace_col := Color(0.28, 0.86, 1.0, 1.0) if _selected_channel == 2 else Color(0.30, 1.0, 0.72, 1.0)
	if sim_node in ["N7_TRIGGER", "N8_SWEEP"]:
		trace_col = Color(1.0, 0.80, 0.28, 1.0)
	_stage_graph_canvas.draw_polyline(pts, trace_col, 2.0, true)
	_stage_graph_canvas.draw_string(font, Vector2(6, 13), "CH%d · %s" % [_selected_channel, sim_node], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.84, 0.96, 0.92))

func _process(delta: float) -> void:
	if not _view_3d_container.visible or _camera == null:
		return

	# Smooth inertial camera integration (decelerates smoothly when mouse is released)
	if not _orbiting:
		_goal_yaw += _yaw_vel * delta
		_goal_pitch = clampf(_goal_pitch + _pitch_vel * delta, -1.45, 1.45)
		var damp := exp(-8.5 * delta)
		_yaw_vel *= damp
		_pitch_vel *= damp
	_goal_dist = clampf(_goal_dist + _dist_vel * delta, 0.24, 2.2)
	_dist_vel *= exp(-10.0 * delta)

	var t_lerp := 1.0 - exp(-12.0 * delta)
	_yaw = lerpf(_yaw, _goal_yaw, t_lerp)
	_pitch = lerpf(_pitch, _goal_pitch, t_lerp)
	_dist = lerpf(_dist, _goal_dist, t_lerp)
	_target = _target.lerp(_goal_target, t_lerp)
	_update_camera()

	# Synchronize 3D CRT electron beam & deflection plates with Workbench CH1/CH2
	var y_norm := 0.0
	var x_norm := 0.0
	var power_on := true
	var intensity := 0.85
	if is_inside_tree() and has_node("/root/SimState"):
		power_on = bool(SimState.view_config.get("power_on", true))
		intensity = float(SimState.analog_config.get("intensity", 0.85))
		var fg: Dictionary = SimState.fg_channels.get(_selected_channel, SimState.fg_channels[1])
		var freq := float(fg.get("frequency", 1000.0))
		var amp := float(fg.get("amplitude", 2.0))
		var v_div := maxf(float(SimState.view_config.get("volts_per_div", 1.0)), 0.05)
		var vert_pos := float(SimState.view_config.get("vert_pos_div", 0.0))
		var coup := int(SimState.analog_config.get("coupling", 0))
		_beam_phase = fmod(_beam_phase + delta * clampf(freq / 700.0, 0.35, 3.0), 1.0)
		var sig := 0.0 if coup == 2 else sin(_beam_phase * TAU) * amp
		y_norm = clampf((sig / (v_div * 4.0)) + (vert_pos / 4.0), -1.0, 1.0)
		x_norm = lerpf(-1.0, 1.0, _beam_phase)

	if _assembly_root != null:
		_assembly_root.step_physics(delta, y_norm, x_norm, power_on, intensity)
	if _stage_graph_canvas != null and _drawer_panel != null and _drawer_panel.visible:
		_stage_graph_canvas.queue_redraw()

	_update_3d_callouts_and_floating_card()

func _update_3d_callouts_and_floating_card() -> void:
	if _camera == null or _assembly_root == null:
		return
	var focus_id := _selected_id if _selected_id > 0 else _hovered_id
	var fl := ArchitectureRegistry.get_flow(focus_id) if focus_id > 0 else {"in": [], "out": []}
	var in_set := {}
	var out_set := {}
	for uid in fl.get("in", []):
		in_set[int(uid)] = true
	for did in fl.get("out", []):
		out_set[int(did)] = true

	if _floating_card != null:
		_floating_card.visible = (focus_id > 0)
		if focus_id > 0:
			var fcfg := ArchitectureRegistry.get_part(focus_id)
			var in_ids: Array = fl.get("in", [])
			var out_ids: Array = fl.get("out", [])
			_float_title.text = "#%02d  %s" % [focus_id, fcfg["name"]]
			_float_sub.text = "%s  ·  %s" % [fcfg["subsystem"], fcfg["spec"]]
			var in_s := ("← IN #%02d" % int(in_ids[0])) if not in_ids.is_empty() else "← IN External"
			var out_s := ("OUT #%02d →" % int(out_ids[0])) if not out_ids.is_empty() else "OUT Display →"
			_float_flow.text = "%s   |   %s" % [in_s, out_s]

	if not _show_pins:
		return

	var placed: Array[Vector2] = []
	var sz := _view_3d_container.size
	var x_min := 316.0 if (_drawer_panel != null and _drawer_panel.visible) else 16.0
	var x_max := sz.x - (348.0 if (_right_inspector != null and _right_inspector.visible) else 24.0)

	for rec in _assembly_root.part_records:
		var pid: int = rec["id"]
		var btn: Button = _badges[pid]
		var is_focus := (pid == focus_id)
		var is_in := in_set.has(pid)
		var is_out := out_set.has(pid)

		if _isolate and _selected_id > 0 and pid != _selected_id and not is_in and not is_out:
			btn.visible = false
			continue

		var n: Node3D = rec["node"]
		var world_p := n.global_position + (rec["pin_offset"] as Vector3)
		if _camera.is_position_behind(world_p):
			btn.visible = false
			continue
		var sp := _camera.unproject_position(world_p)
		if sp.x < x_min or sp.x > x_max or sp.y < 14.0 or sp.y > sz.y - 24.0:
			btn.visible = false
			continue

		if is_focus:
			btn.text = "#%02d" % pid
			btn.modulate = Color(0.32, 0.88, 1.0)
			if _floating_card != null:
				_floating_card.position = Vector2(
					clampf(sp.x + 24.0, x_min, maxf(x_min, x_max - 255.0)),
					clampf(sp.y - 68.0, 14.0, sz.y - 96.0)
				)
		elif is_in:
			btn.text = "← IN #%02d" % pid
			btn.modulate = Color(1.0, 0.78, 0.25)
		elif is_out:
			btn.text = "OUT #%02d →" % pid
			btn.modulate = Color(0.28, 1.0, 0.68)
		else:
			btn.text = "#%02d" % pid
			btn.modulate = Color(0.85, 0.90, 0.96, 0.85)
			var overlap := false
			for prev in placed:
				if absf(prev.x - sp.x) < 34.0 and absf(prev.y - sp.y) < 20.0:
					overlap = true
					break
			if overlap:
				btn.visible = false
				continue

		placed.append(sp)
		btn.visible = true
		btn.position = sp - Vector2(16, 9)

func _select_part(pid: int) -> void:
	_selected_id = pid
	_assembly_root.set_selection(_selected_id, _hovered_id, _isolate)
	for k in _step_cards.keys():
		var card: PanelContainer = _step_cards[k]
		var active := (int(k) == pid)
		card.add_theme_stylebox_override("panel", _make_card_style(
			Color(0.11, 0.20, 0.30, 1.0) if active else Color(0.08, 0.115, 0.17, 1.0),
			Color(0.22, 0.76, 0.98, 1.0) if active else Color(0.20, 0.30, 0.42, 1.0), 6, 7
		))

	_on_sim_state_updated()
	if pid <= 0:
		_right_inspector.visible = false
		if _floating_card != null:
			_floating_card.visible = false
		return

	var cfg := ArchitectureRegistry.get_part(pid)
	var fl := ArchitectureRegistry.get_flow(pid)
	_insp_badge.text = "#%02d   %s" % [pid, cfg["code"]]
	_insp_title.text = cfg["name"]
	_insp_sub.text = "%s  •  %s" % [cfg["subsystem"], cfg["spec"]]
	_insp_desc.text = cfg["desc"]
	_insp_service.text = "⚙ SERVICE & CALIBRATION NOTE:
" + cfg["service"]

	var in_ids: Array = fl.get("in", [])
	var out_ids: Array = fl.get("out", [])

	for ch in _insp_upstream_box.get_children():
		ch.queue_free()
	if in_ids.is_empty():
		var none_in := Label.new()
		none_in.text = "• External BNC / AC Mains Input"
		none_in.add_theme_font_size_override("font_size", 10)
		none_in.add_theme_color_override("font_color", Color(0.45, 0.52, 0.60))
		_insp_upstream_box.add_child(none_in)
	else:
		for uid in in_ids:
			var u_id := int(uid)
			var ucfg := ArchitectureRegistry.get_part(u_id)
			var b := Button.new()
			b.text = "← IN: #%02d %s" % [u_id, ucfg["name"]]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.add_theme_font_size_override("font_size", 10)
			b.modulate = Color(1.0, 0.85, 0.55)
			b.pressed.connect(func():
				_select_part(u_id)
				_focus_part_camera(u_id)
			)
			_insp_upstream_box.add_child(b)

	for ch in _insp_downstream_box.get_children():
		ch.queue_free()
	if out_ids.is_empty():
		var none_out := Label.new()
		none_out.text = "• Final Visual / Mechanical Output"
		none_out.add_theme_font_size_override("font_size", 10)
		none_out.add_theme_color_override("font_color", Color(0.45, 0.52, 0.60))
		_insp_downstream_box.add_child(none_out)
	else:
		for did in out_ids:
			var d_id := int(did)
			var dcfg := ArchitectureRegistry.get_part(d_id)
			var b := Button.new()
			b.text = "OUT →: #%02d %s" % [d_id, dcfg["name"]]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.add_theme_font_size_override("font_size", 10)
			b.modulate = Color(0.55, 0.96, 0.78)
			b.pressed.connect(func():
				_select_part(d_id)
				_focus_part_camera(d_id)
			)
			_insp_downstream_box.add_child(b)

	_right_inspector.visible = true
	part_selected.emit(cfg)

func _pick_part_at(mouse_pos: Vector2) -> int:
	if _camera == null or _assembly_root == null:
		return -1
	var vp_pos := mouse_pos * (Vector2(_sub_viewport.size) / _view_3d_container.size.max(Vector2.ONE))
	var ray_o := _camera.project_ray_origin(vp_pos)
	var ray_d := _camera.project_ray_normal(vp_pos)
	var best_id := -1
	var best_t := 1e9
	for rec in _assembly_root.part_records:
		var n: Node3D = rec["node"]
		var center := n.global_position
		var to_c := center - ray_o
		var proj := to_c.dot(ray_d)
		if proj < 0.0:
			continue
		var perp_sq := to_c.length_squared() - proj * proj
		if perp_sq < 0.0022 and proj < best_t:
			best_t = proj
			best_id = rec["id"]
	return best_id

func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_orbiting = true
				_yaw_vel = 0.0
				_pitch_vel = 0.0
				_last_mouse = mb.position
				_press_pos = mb.position
			else:
				_orbiting = false
				if mb.position.distance_to(_press_pos) < 5.0:
					# Clicking a part selects it; clicking empty background deselects back to 100% overview
					_select_part(_pick_part_at(mb.position))
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist_vel -= 0.42
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist_vel += 0.42
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _last_mouse
		_last_mouse = mm.position
		if _orbiting:
			var dy := -delta.x * 0.0075
			var dp := -delta.y * 0.0075
			_goal_yaw += dy
			_goal_pitch = clampf(_goal_pitch + dp, -1.45, 1.45)
			_yaw_vel = dy * 28.0
			_pitch_vel = dp * 28.0
		elif _panning and _camera != null:
			var right := _camera.global_transform.basis.x
			var up := _camera.global_transform.basis.y
			_goal_target -= (right * delta.x - up * delta.y) * (_dist * 0.0014)
		else:
			var hov := _pick_part_at(mm.position)
			if hov != _hovered_id:
				_hovered_id = hov
				_assembly_root.set_selection(_selected_id, _hovered_id, _isolate)

func _on_container_resized() -> void:
	if _view_3d_container == null or _sub_viewport == null:
		return
	# 0.72x internal 3D resolution keeps llvmpipe software rendering fast while 2D badges/UI remain 1.0x crisp
	var w := maxi(540, int(_view_3d_container.size.x * 0.72))
	var h := maxi(340, int(_view_3d_container.size.y * 0.72))
	_sub_viewport.size = Vector2i(w, h)
	if _viewport_rect != null:
		_viewport_rect.texture = _sub_viewport.get_texture()

func _update_camera() -> void:
	if _camera == null:
		return
	var cp := cos(_pitch)
	var offset := Vector3(sin(_yaw) * cp, -sin(_pitch), cos(_yaw) * cp) * maxf(0.24, _dist)
	var cam_pos := _target + offset
	if cam_pos.distance_squared_to(_target) > 0.00001:
		_camera.look_at_from_position(cam_pos, _target, Vector3.UP)
