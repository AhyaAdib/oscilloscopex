class_name ArchitectureController
extends Control

signal part_selected(part_cfg: Dictionary)

const PRESETS := {
	"iso":   {"pos": Vector3(0.65, 0.44, 0.70), "target": Vector3(0.0, 0.0, 0.02)},
	"front": {"pos": Vector3(0.0, 0.02, 0.88),  "target": Vector3(0.0, 0.0, 0.13)},
	"crt":   {"pos": Vector3(-0.50, 0.24, 0.48),"target": Vector3(-0.09, 0.03, 0.10)},
	"pcb":   {"pos": Vector3(0.68, 0.19, 0.10), "target": Vector3(0.09, 0.01, 0.01)},
	"rear":  {"pos": Vector3(-0.55, 0.31, -0.72),"target": Vector3(0.0, -0.02, -0.13)},
	"top":   {"pos": Vector3(0.01, 0.96, 0.04), "target": Vector3(0.0, 0.0, 0.0)}
}

var _view_3d_container: Control
var _sub_viewport: SubViewport
var _viewport_rect: TextureRect
var _callout_layer: Control
var _inspector_popup: PanelContainer
var _insp_title: Label
var _insp_meta: Label
var _insp_desc: Label
var _camera: Camera3D
var _env: Environment
var _assembly_root: InternalAssemblyRoot
var _badges := {}

var _yaw := 0.75
var _pitch := -0.42
var _dist := 1.05
var _target := Vector3(0.0, 0.0, 0.02)
var _orbiting := false
var _panning := false
var _last_mouse := Vector2.ZERO
var _press_pos := Vector2.ZERO
var _show_pins := true
var _selected_id := -1
var _hovered_id := -1
var _isolate := false

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
	_sub_viewport.size = Vector2i(800, 520)
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

	_build_inspector_popup(_view_3d_container)

	var we := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.957, 0.965, 0.976) # #f4f6f9 Service Manual Blueprint
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color.WHITE
	_env.ambient_light_energy = 0.92
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
	set_camera_preset("iso")
	_view_3d_container.resized.connect(_on_container_resized)
	return _view_3d_container

func _build_inspector_popup(parent: Control) -> void:
	_inspector_popup = PanelContainer.new()
	_inspector_popup.visible = false
	_inspector_popup.position = Vector2(14, 14)
	_inspector_popup.custom_minimum_size = Vector2(340, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.10, 0.15, 0.94)
	sb.border_color = Color(0.02, 0.52, 0.78, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	_inspector_popup.add_theme_stylebox_override("panel", sb)
	parent.add_child(_inspector_popup)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_inspector_popup.add_child(vb)

	var hb := HBoxContainer.new()
	vb.add_child(hb)
	_insp_title = Label.new()
	_insp_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_insp_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_title.add_theme_color_override("font_color", Color(0.22, 0.78, 0.98))
	hb.add_child(_insp_title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(func(): _select_part(-1))
	hb.add_child(close_btn)

	_insp_meta = Label.new()
	_insp_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_meta.add_theme_color_override("font_color", Color(0.98, 0.78, 0.24))
	vb.add_child(_insp_meta)

	_insp_desc = Label.new()
	_insp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_desc.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
	vb.add_child(_insp_desc)

func _build_callout_badges() -> void:
	for rec in _assembly_root.part_records:
		var pid: int = rec["id"]
		var btn := Button.new()
		btn.text = "%02d" % pid
		btn.custom_minimum_size = Vector2(24, 18)
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
		_update_camera()

func set_render_style(is_blueprint: bool) -> void:
	if _env != null:
		_env.background_color = Color(0.957, 0.965, 0.976) if is_blueprint else Color(0.078, 0.098, 0.137)
		_env.ambient_light_energy = 0.92 if is_blueprint else 0.65
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

func set_isolate_selected(iso: bool) -> void:
	_isolate = iso
	if _assembly_root != null:
		_assembly_root.set_selection(_selected_id, _hovered_id, _isolate)

func set_camera_preset(key: String) -> void:
	var p: Dictionary = PRESETS.get(key, PRESETS["iso"])
	var pos: Vector3 = p["pos"]
	_target = p["target"]
	var off := pos - _target
	_dist = off.length()
	_yaw = atan2(off.x, off.z)
	_pitch = -asin(clampf(off.y / maxf(0.01, _dist), -0.98, 0.98))
	_update_camera()

func _process(_delta: float) -> void:
	if not _view_3d_container.visible or not _show_pins or _camera == null:
		return
	var placed: Array[Vector2] = []
	var sz := _view_3d_container.size
	for rec in _assembly_root.part_records:
		var pid: int = rec["id"]
		var btn: Button = _badges[pid]
		if (_selected_id > 0 and pid != _selected_id) or (_isolate and _selected_id > 0 and pid != _selected_id):
			btn.visible = false
			continue
		var n: Node3D = rec["node"]
		var world_p := n.global_position + (rec["pin_offset"] as Vector3)
		if _camera.is_position_behind(world_p):
			btn.visible = false
			continue
		var sp := _camera.unproject_position(world_p)
		if sp.x < 12.0 or sp.x > sz.x - 28.0 or sp.y < 12.0 or sp.y > sz.y - 24.0:
			btn.visible = false
			continue
		if pid != _selected_id and pid != _hovered_id:
			var overlap := false
			for prev in placed:
				if absf(prev.x - sp.x) < 26.0 and absf(prev.y - sp.y) < 19.0:
					overlap = true
					break
			if overlap:
				btn.visible = false
				continue
		placed.append(sp)
		btn.visible = true
		btn.position = sp - Vector2(12, 9)

func _select_part(pid: int) -> void:
	_selected_id = pid
	_assembly_root.set_selection(_selected_id, _hovered_id, _isolate)
	if pid <= 0:
		_inspector_popup.visible = false
		return
	var cfg := ArchitectureRegistry.get_part(pid)
	_insp_title.text = "#%02d [%s] — %s" % [pid, cfg["code"], cfg["name"]]
	_insp_meta.text = "%s | %s | %s" % [cfg["subsystem"], cfg["axis"], cfg["spec"]]
	_insp_desc.text = "%s\n\nService Note: %s" % [cfg["desc"], cfg["service"]]
	_inspector_popup.visible = true
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
				_last_mouse = mb.position
				_press_pos = mb.position
			else:
				_orbiting = false
				if mb.position.distance_to(_press_pos) < 5.0:
					_select_part(_pick_part_at(mb.position))
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = clampf(_dist * 0.88, 0.22, 2.2)
			_update_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = clampf(_dist * 1.12, 0.22, 2.2)
			_update_camera()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _last_mouse
		_last_mouse = mm.position
		if _orbiting:
			_yaw -= delta.x * 0.008
			_pitch = clampf(_pitch - delta.y * 0.008, -1.45, 1.45)
			_update_camera()
		elif _panning and _camera != null:
			var right := _camera.global_transform.basis.x
			var up := _camera.global_transform.basis.y
			_target -= (right * delta.x - up * delta.y) * (_dist * 0.0014)
			_update_camera()
		else:
			var hov := _pick_part_at(mm.position)
			if hov != _hovered_id:
				_hovered_id = hov
				_assembly_root.set_selection(_selected_id, _hovered_id, _isolate)

func _on_container_resized() -> void:
	if _view_3d_container == null or _sub_viewport == null:
		return
	var w := maxi(480, int(_view_3d_container.size.x))
	var h := maxi(360, int(_view_3d_container.size.y))
	_sub_viewport.size = Vector2i(w, h)
	if _viewport_rect != null:
		_viewport_rect.texture = _sub_viewport.get_texture()

func _update_camera() -> void:
	if _camera == null:
		return
	var cp := cos(_pitch)
	var offset := Vector3(sin(_yaw) * cp, -sin(_pitch), cos(_yaw) * cp) * maxf(0.22, _dist)
	var cam_pos := _target + offset
	if cam_pos.distance_squared_to(_target) > 0.00001:
		_camera.look_at_from_position(cam_pos, _target, Vector3.UP)
