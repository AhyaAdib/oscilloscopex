class_name ArchitectureController
extends Control

const DEFAULT_CAM_TARGET := Vector3(-0.14, 0.12, 0.02)

var _view_3d_container: Control
var _sub_viewport: SubViewport
var _viewport_rect: TextureRect
var _camera: Camera3D
var _assembly_root: InternalAssemblyRoot
var _yaw := 0.68
var _pitch := -0.36
var _dist := 0.86
var _target := DEFAULT_CAM_TARGET
var _orbiting := false
var _panning := false
var _last_mouse := Vector2.ZERO

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
	_viewport_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewport_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewport_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_viewport_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport_rect.texture = _sub_viewport.get_texture()
	_view_3d_container.add_child(_viewport_rect)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.08, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.50, 0.60, 0.72)
	e.ambient_light_energy = 0.78
	env.environment = e
	_sub_viewport.add_child(env)

	var key_light := DirectionalLight3D.new()
	key_light.position = Vector3(0.55, 1.05, 0.90)
	key_light.look_at_from_position(key_light.position, DEFAULT_CAM_TARGET, Vector3.UP)
	key_light.light_energy = 1.90
	key_light.shadow_enabled = false
	_sub_viewport.add_child(key_light)

	_camera = Camera3D.new()
	_camera.name = "Arch3DCamera"
	_camera.fov = 44.0
	_camera.near = 0.02
	_camera.far = 25.0
	_sub_viewport.add_child(_camera)
	_camera.current = true

	# Isolated National VP-5231A Exploded Assembly ONLY (no function generator, breadboard, or PSU)
	_assembly_root = InternalAssemblyRoot.new()
	_sub_viewport.add_child(_assembly_root)
	_assembly_root.apply_explosion_factor(0.5)

	reset_camera()
	_view_3d_container.resized.connect(_on_container_resized)
	return _view_3d_container

func set_active(active: bool) -> void:
	if _view_3d_container == null or _sub_viewport == null:
		return
	_view_3d_container.visible = active
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if active:
		if _camera != null:
			_camera.current = true
		call_deferred("_on_container_resized")
		_update_camera()

func set_explosion_factor(factor: float) -> void:
	if _assembly_root != null:
		_assembly_root.apply_explosion_factor(factor)

func set_ghost_shell_visible(show_shell: bool) -> void:
	if _assembly_root != null:
		_assembly_root.set_chassis_shell_visible(show_shell)

func reset_camera() -> void:
	_yaw = 0.68
	_pitch = -0.36
	_dist = 0.86
	_target = DEFAULT_CAM_TARGET
	_update_camera()

func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = clampf(_dist * 0.88, 0.18, 2.5)
			_update_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = clampf(_dist * 1.12, 0.18, 2.5)
			_update_camera()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _last_mouse
		_last_mouse = mm.position
		if _orbiting:
			_yaw -= delta.x * 0.008
			_pitch = clampf(_pitch - delta.y * 0.008, -1.35, 1.35)
			_update_camera()
		elif _panning and _camera != null:
			var right := _camera.global_transform.basis.x
			var up := _camera.global_transform.basis.y
			_target -= (right * delta.x - up * delta.y) * (_dist * 0.0014)
			_update_camera()

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
	var safe_dist := maxf(0.18, _dist)
	var cp := cos(_pitch)
	var offset := Vector3(sin(_yaw) * cp, -sin(_pitch), cos(_yaw) * cp) * safe_dist
	var cam_pos := _target + offset
	if cam_pos.distance_squared_to(_target) > 0.00001:
		_camera.look_at_from_position(cam_pos, _target, Vector3.UP)
