class_name InternalAssemblyRoot
extends Node3D

var assembly_root: Node3D
var guide_lines_mi: MeshInstance3D
var floor_grid: Node3D
var part_records := []
var show_guides := true
var blueprint_mode := true
var explode_factor := 0.72
var selected_part_id := -1
var hovered_part_id := -1
var isolate_selected := false

func _ready() -> void:
	name = "InternalAssemblyRoot"
	floor_grid = ChassisShellBuilder.build_engineering_grid(self, -0.22)

	assembly_root = Node3D.new()
	assembly_root.name = "VP5231A_55Part_Assembly"
	add_child(assembly_root)

	part_records = SubsystemBuilder.build_all_55_parts(assembly_root)

	guide_lines_mi = MeshInstance3D.new()
	guide_lines_mi.name = "AssemblyAxisGuideLines"
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(0.01, 0.52, 0.78, 0.65)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	guide_lines_mi.material_override = gm
	add_child(guide_lines_mi)

	apply_explosion_factor(explode_factor)
	apply_render_style()

func apply_explosion_factor(factor: float) -> void:
	explode_factor = clampf(factor, 0.0, 1.0)
	for rec in part_records:
		var n: Node3D = rec["node"]
		n.position = rec["base_pos"] + rec["exp_offset"] * explode_factor
	_rebuild_guide_lines()

func set_guides_visible(vis: bool) -> void:
	show_guides = vis
	_rebuild_guide_lines()

func set_blueprint_mode(is_bp: bool) -> void:
	blueprint_mode = is_bp
	apply_render_style()

func set_selection(sel_id: int, hov_id: int, isolate: bool) -> void:
	selected_part_id = sel_id
	hovered_part_id = hov_id
	isolate_selected = isolate
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
			var steps := 10
			for s in range(0, steps, 2):
				var t0 := float(s) / float(steps)
				var t1 := float(s + 1) / float(steps)
				verts.append(p0.lerp(p1, t0))
				verts.append(p0.lerp(p1, t1))
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
	var active_id := selected_part_id if selected_part_id > 0 else hovered_part_id

	for rec in part_records:
		var pid: int = rec["id"]
		var n: Node3D = rec["node"]
		var is_sel := (pid == selected_part_id)
		var is_hov := (pid == hovered_part_id)
		var is_dim := (active_id > 0 and pid != active_id) or (isolate_selected and selected_part_id > 0 and pid != selected_part_id)

		_style_node_recursive(n, is_sel, is_hov, is_dim)

func _style_node_recursive(node: Node, is_sel: bool, is_hov: bool, is_dim: bool) -> void:
	for ch in node.get_children():
		if ch is MeshInstance3D:
			var mi := ch as MeshInstance3D
			if mi.name == "CadEdgeLines":
				mi.visible = blueprint_mode or is_sel or is_hov
				var em := mi.material_override as StandardMaterial3D
				if em != null:
					if is_sel:
						em.albedo_color = Color(0.01, 0.52, 0.78, 0.95)
					elif blueprint_mode:
						em.albedo_color = Color(0.06, 0.09, 0.16, 0.10 if is_dim else 0.75)
					else:
						em.albedo_color = Color(0.22, 0.74, 0.97, 0.10 if is_dim else 0.65)
			elif mi.material_override is StandardMaterial3D:
				var m := mi.material_override as StandardMaterial3D
				if m.has_meta("bp_color"):
					var base_c: Color = m.get_meta("bp_color") if blueprint_mode else m.get_meta("real_color")
					var alpha: float = 0.14 if is_dim else float(m.get_meta("base_alpha"))
					m.albedo_color = Color(base_c.r, base_c.g, base_c.b, alpha)
					m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
					m.metallic = 0.04 if blueprint_mode else float(m.get_meta("real_metal"))
					m.roughness = 0.88 if blueprint_mode else float(m.get_meta("real_rough"))
					if is_sel:
						m.emission_enabled = true
						m.emission = Color(0.01, 0.52, 0.78)
						m.emission_energy_multiplier = 0.45
					elif is_hov:
						m.emission_enabled = true
						m.emission = Color(0.22, 0.74, 0.97)
						m.emission_energy_multiplier = 0.32
					else:
						m.emission_enabled = false
		_style_node_recursive(ch, is_sel, is_hov, is_dim)
