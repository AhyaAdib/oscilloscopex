class_name InternalAssemblyRoot
extends Node3D

var assembly_root: Node3D
var guide_lines_mi: MeshInstance3D
var flow_tubes_mi: MeshInstance3D
var crt_beam_mi: MeshInstance3D
var crt_y_plate_top: MeshInstance3D
var crt_y_plate_bot: MeshInstance3D
var crt_x_plate_l: MeshInstance3D
var crt_x_plate_r: MeshInstance3D
var floor_grid: Node3D
var part_records := []
var _part_map := {}
var _pulse_pool: Array[MeshInstance3D] = []
var _active_curves := []

var show_guides := true
var show_signal_flow := true
var blueprint_mode := false
var explode_factor := 0.72
var selected_part_id := -1
var hovered_part_id := -1
var isolate_selected := false
var _flow_phase := 0.0
var _conduits_dirty := true
var _last_y := -999.0
var _last_x := -999.0
var _last_pwr := true

func _ready() -> void:
	name = "InternalAssemblyRoot"
	floor_grid = ChassisShellBuilder.build_engineering_grid(self, -0.22)

	assembly_root = Node3D.new()
	assembly_root.name = "VP5231A_55Part_Assembly"
	add_child(assembly_root)

	part_records = SubsystemBuilder.build_all_55_parts(assembly_root)
	for rec in part_records:
		_part_map[int(rec["id"])] = rec

	_setup_crt_physics_internals()
	_setup_pulse_pool()

	guide_lines_mi = MeshInstance3D.new()
	guide_lines_mi.name = "AssemblyAxisGuideLines"
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(0.18, 0.68, 0.95, 0.36)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	guide_lines_mi.material_override = gm
	add_child(guide_lines_mi)

	flow_tubes_mi = MeshInstance3D.new()
	flow_tubes_mi.name = "SignalFlowConduits"
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.vertex_color_use_as_albedo = true
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flow_tubes_mi.material_override = fm
	add_child(flow_tubes_mi)

	apply_explosion_factor(explode_factor)
	apply_render_style()

func _setup_pulse_pool() -> void:
	var shared_sphere := SphereMesh.new()
	shared_sphere.radius = 0.0058
	shared_sphere.height = 0.0116
	shared_sphere.radial_segments = 6
	shared_sphere.rings = 3
	for i in range(8):
		var pm := MeshInstance3D.new()
		pm.mesh = shared_sphere
		pm.visible = false
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pm.material_override = mat
		add_child(pm)
		_pulse_pool.append(pm)

func _setup_crt_physics_internals() -> void:
	var crt_rec: Dictionary = _part_map.get(24, {})
	if crt_rec.is_empty():
		return
	var crt_node: Node3D = crt_rec["node"]
	var s := ComponentFactory.CAD_SCALE

	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.88, 0.64, 0.22, 0.95)
	plate_mat.metallic = 0.72
	plate_mat.roughness = 0.28
	plate_mat.emission_enabled = true
	plate_mat.emission = Color(1.0, 0.65, 0.12)
	plate_mat.emission_energy_multiplier = 0.2

	crt_y_plate_top = _make_crt_plate(crt_node, "CRT_YPlate_Top", Vector3(0.24, 0.025, 0.32) * s, Vector3(0.0, 0.13, -0.18) * s, plate_mat.duplicate())
	crt_y_plate_bot = _make_crt_plate(crt_node, "CRT_YPlate_Bot", Vector3(0.24, 0.025, 0.32) * s, Vector3(0.0, -0.13, -0.18) * s, plate_mat.duplicate())

	var x_mat := plate_mat.duplicate()
	x_mat.albedo_color = Color(0.20, 0.82, 0.62, 0.95)
	x_mat.emission = Color(0.15, 0.95, 0.62)
	crt_x_plate_l = _make_crt_plate(crt_node, "CRT_XPlate_L", Vector3(0.025, 0.24, 0.32) * s, Vector3(-0.14, 0.0, 0.22) * s, x_mat.duplicate())
	crt_x_plate_r = _make_crt_plate(crt_node, "CRT_XPlate_R", Vector3(0.025, 0.24, 0.32) * s, Vector3(0.14, 0.0, 0.22) * s, x_mat.duplicate())

	crt_beam_mi = MeshInstance3D.new()
	crt_beam_mi.name = "CRTElectronBeam"
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(0.28, 1.0, 0.62, 0.96)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crt_beam_mi.material_override = bm
	crt_node.add_child(crt_beam_mi)

func _make_crt_plate(parent: Node3D, p_name: String, sz: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = p_name
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func step_physics(delta: float, y_norm: float, x_norm: float, power_on: bool, intensity: float) -> void:
	_flow_phase = fmod(_flow_phase + delta * 1.15, 1.0)
	if absf(y_norm - _last_y) > 0.008 or absf(x_norm - _last_x) > 0.008 or power_on != _last_pwr:
		_last_y = y_norm
		_last_x = x_norm
		_last_pwr = power_on
		_update_crt_beam_and_plates(y_norm, x_norm, power_on, intensity)
	if _conduits_dirty:
		_rebuild_signal_conduit_geometry()
		_conduits_dirty = false
	_animate_pulse_pool(power_on)

func _update_crt_beam_and_plates(y_norm: float, x_norm: float, power_on: bool, intensity: float) -> void:
	if crt_beam_mi == null:
		return
	crt_beam_mi.visible = power_on
	if crt_y_plate_top != null:
		(crt_y_plate_top.material_override as StandardMaterial3D).emission_energy_multiplier = 0.15 + maxf(0.0, y_norm) * 1.5
	if crt_y_plate_bot != null:
		(crt_y_plate_bot.material_override as StandardMaterial3D).emission_energy_multiplier = 0.15 + maxf(0.0, -y_norm) * 1.5
	if crt_x_plate_l != null:
		(crt_x_plate_l.material_override as StandardMaterial3D).emission_energy_multiplier = 0.15 + maxf(0.0, -x_norm) * 1.5
	if crt_x_plate_r != null:
		(crt_x_plate_r.material_override as StandardMaterial3D).emission_energy_multiplier = 0.15 + maxf(0.0, x_norm) * 1.5

	if not power_on:
		return

	var s := ComponentFactory.CAD_SCALE
	var z_gun := -1.15 * s
	var z_yp := -0.18 * s
	var z_xp := 0.22 * s
	var z_scr := 1.32 * s
	var dy := clampf(y_norm, -1.0, 1.0) * 0.56 * s
	var dx := clampf(x_norm, -1.0, 1.0) * 0.68 * s

	var segs := 12
	var pts: Array[Vector3] = []
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var z := lerpf(z_gun, z_scr, t)
		var ty := clampf((z - z_yp) / maxf(0.001, z_scr - z_yp), 0.0, 1.0)
		var tx := clampf((z - z_xp) / maxf(0.001, z_scr - z_xp), 0.0, 1.0)
		pts.append(Vector3(dx * tx * tx, dy * ty * ty, z))

	var verts := PackedVector3Array()
	var r := clampf(0.012 + intensity * 0.015, 0.010, 0.028) * s
	for i in range(segs):
		var a := pts[i]
		var b := pts[i + 1]
		for off in [Vector3.ZERO, Vector3(r, 0, 0), Vector3(0, r, 0)]:
			verts.append(a + off)
			verts.append(b + off)

	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	am.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	crt_beam_mi.mesh = am

func _rebuild_signal_conduit_geometry() -> void:
	_active_curves.clear()
	if flow_tubes_mi == null:
		return
	var active_id := selected_part_id if selected_part_id > 0 else hovered_part_id
	if not show_signal_flow or active_id <= 0:
		flow_tubes_mi.visible = false
		return

	var flow := ArchitectureRegistry.get_flow(active_id)
	var in_ids: Array = flow.get("in", [])
	var out_ids: Array = flow.get("out", [])
	var active_rec: Dictionary = _part_map.get(active_id, {})
	if active_rec.is_empty() or (in_ids.is_empty() and out_ids.is_empty()):
		flow_tubes_mi.visible = false
		return

	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var p_center: Vector3 = (active_rec["node"] as Node3D).position

	for uid in in_ids:
		var urec: Dictionary = _part_map.get(int(uid), {})
		if not urec.is_empty():
			var p0: Vector3 = (urec["node"] as Node3D).position
			var mid := (p0 + p_center) * 0.5 + Vector3(0.0, 0.055, 0.025)
			var col := Color(0.98, 0.68, 0.14, 0.92)
			_append_curve(verts, cols, p0, mid, p_center, col)
			_active_curves.append({"p0": p0, "mid": mid, "p2": p_center, "col": col})

	for did in out_ids:
		var drec: Dictionary = _part_map.get(int(did), {})
		if not drec.is_empty():
			var p2: Vector3 = (drec["node"] as Node3D).position
			var mid := (p_center + p2) * 0.5 + Vector3(0.0, 0.055, 0.025)
			var col := Color(0.14, 0.88, 0.58, 0.92)
			_append_curve(verts, cols, p_center, mid, p2, col)
			_active_curves.append({"p0": p_center, "mid": mid, "p2": p2, "col": col})

	if verts.is_empty():
		flow_tubes_mi.visible = false
		return

	flow_tubes_mi.visible = true
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	am.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	flow_tubes_mi.mesh = am

func _append_curve(verts: PackedVector3Array, cols: PackedColorArray, p0: Vector3, mid: Vector3, p2: Vector3, col: Color) -> void:
	var steps := 12
	var t_off := 0.0018
	for i in range(steps):
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var a := p0.lerp(mid, t0).lerp(mid.lerp(p2, t0), t0)
		var b := p0.lerp(mid, t1).lerp(mid.lerp(p2, t1), t1)
		for off in [Vector3.ZERO, Vector3(0, t_off, 0)]:
			verts.append(a + off); cols.append(col)
			verts.append(b + off); cols.append(col)

func _animate_pulse_pool(power_on: bool) -> void:
	var n_curves := _active_curves.size()
	for i in range(_pulse_pool.size()):
		var pm := _pulse_pool[i]
		if not power_on or not show_signal_flow or i >= n_curves:
			pm.visible = false
			continue
		var c: Dictionary = _active_curves[i]
		var p0: Vector3 = c["p0"]
		var mid: Vector3 = c["mid"]
		var p2: Vector3 = c["p2"]
		pm.visible = true
		pm.position = p0.lerp(mid, _flow_phase).lerp(mid.lerp(p2, _flow_phase), _flow_phase)
		(pm.material_override as StandardMaterial3D).albedo_color = c["col"]

func apply_explosion_factor(factor: float) -> void:
	explode_factor = clampf(factor, 0.0, 1.0)
	for rec in part_records:
		var n: Node3D = rec["node"]
		n.position = rec["base_pos"] + rec["exp_offset"] * explode_factor
	_rebuild_guide_lines()
	_conduits_dirty = true

func set_guides_visible(vis: bool) -> void:
	show_guides = vis
	_rebuild_guide_lines()

func set_signal_flow_visible(vis: bool) -> void:
	show_signal_flow = vis
	_conduits_dirty = true

func set_shell_visible(vis: bool) -> void:
	var rec: Dictionary = _part_map.get(40, {})
	if not rec.is_empty():
		(rec["node"] as Node3D).visible = vis

func set_blueprint_mode(is_bp: bool) -> void:
	blueprint_mode = is_bp
	apply_render_style()

func set_selection(sel_id: int, hov_id: int, isolate: bool) -> void:
	selected_part_id = sel_id
	hovered_part_id = hov_id
	isolate_selected = isolate
	_conduits_dirty = true
	apply_render_style()

func _rebuild_guide_lines() -> void:
	if guide_lines_mi == null:
		return
	guide_lines_mi.visible = show_guides and explode_factor > 0.03
	if not guide_lines_mi.visible:
		return
	var verts := PackedVector3Array()
	for rec in part_records:
		var off: Vector3 = rec["exp_offset"]
		if off.length() > 0.01:
			var p0: Vector3 = rec["base_pos"]
			var p1: Vector3 = p0 + off * explode_factor
			for s in range(0, 6, 2):
				verts.append(p0.lerp(p1, float(s) / 6.0))
				verts.append(p0.lerp(p1, float(s + 1) / 6.0))
	if verts.is_empty():
		return
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	am.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	guide_lines_mi.mesh = am

func apply_render_style() -> void:
	if floor_grid != null:
		floor_grid.visible = not blueprint_mode
	# Only dim unrelated parts when a component is actively selected (not on casual mouse-over or initial overview)
	var has_selection := selected_part_id > 0
	var neighbor_ids := {}
	if has_selection:
		var fl := ArchitectureRegistry.get_flow(selected_part_id)
		for uid in fl.get("in", []):
			neighbor_ids[int(uid)] = true
		for did in fl.get("out", []):
			neighbor_ids[int(did)] = true

	var crt_xray := (selected_part_id in [24, 25, 27, 50, 53]) or (hovered_part_id == 24)

	for rec in part_records:
		var pid: int = rec["id"]
		var n: Node3D = rec["node"]
		var is_sel := (pid == selected_part_id)
		var is_hov := (pid == hovered_part_id)
		var is_neighbor := neighbor_ids.has(pid)
		var is_dim := (has_selection and not is_sel and not is_neighbor) or (isolate_selected and has_selection and not is_sel and not is_neighbor)
		_style_node_recursive(n, pid, is_sel, is_hov, is_neighbor, is_dim, crt_xray)

func _style_node_recursive(node: Node, pid: int, is_sel: bool, is_hov: bool, is_neighbor: bool, is_dim: bool, crt_xray: bool) -> void:
	for ch in node.get_children():
		if ch is MeshInstance3D:
			var mi := ch as MeshInstance3D
			if mi.material_override is StandardMaterial3D:
				var m := mi.material_override as StandardMaterial3D
				if m.has_meta("bp_color"):
					var base_c: Color = m.get_meta("bp_color") if blueprint_mode else m.get_meta("real_color")
					var base_a := float(m.get_meta("base_alpha"))
					if pid == 24 and crt_xray and base_a < 0.9:
						base_a = 0.22
					var alpha: float = 0.16 if is_dim else base_a
					m.albedo_color = Color(base_c.r, base_c.g, base_c.b, alpha)
					m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
					m.metallic = 0.04 if blueprint_mode else float(m.get_meta("real_metal"))
					m.roughness = 0.85 if blueprint_mode else float(m.get_meta("real_rough"))
					if is_sel:
						m.emission_enabled = true
						m.emission = Color(0.05, 0.62, 0.92)
						m.emission_energy_multiplier = 0.45
					elif is_hov:
						m.emission_enabled = true
						m.emission = Color(0.22, 0.74, 0.97)
						m.emission_energy_multiplier = 0.30
					elif is_neighbor:
						m.emission_enabled = true
						m.emission = Color(0.14, 0.78, 0.52)
						m.emission_energy_multiplier = 0.22
					else:
						m.emission_enabled = false
		_style_node_recursive(ch, pid, is_sel, is_hov, is_neighbor, is_dim, crt_xray)
