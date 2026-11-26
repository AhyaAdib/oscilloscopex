class_name ComponentFactory
extends RefCounted

const CAD_SCALE := 0.085

static func make_dual_mat(real_hex: int, bp_hex: int, rough := 0.5, metal := 0.25, tex: Texture2D = null, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var bp_col := Color.hex((bp_hex << 8) | 0xFF)
	var real_col := Color.hex((real_hex << 8) | 0xFF)
	m.albedo_color = Color(bp_col.r, bp_col.g, bp_col.b, alpha)
	m.roughness = 0.88
	m.metallic = 0.04
	m.albedo_texture = tex
	if alpha < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.set_meta("real_color", Color(real_col.r, real_col.g, real_col.b, alpha))
	m.set_meta("real_metal", metal)
	m.set_meta("real_rough", rough)
	m.set_meta("bp_color", Color(bp_col.r, bp_col.g, bp_col.b, alpha))
	m.set_meta("base_alpha", alpha)
	return m

static func add_part_mesh(part_node: Node3D, mesh: Mesh, material: StandardMaterial3D, pos: Vector3, rot := Vector3.ZERO, add_edges := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos * CAD_SCALE
	mi.rotation = rot
	mi.material_override = material.duplicate()
	part_node.add_child(mi)

	if add_edges:
		var edge_mi := _create_edge_overlay(mesh)
		if edge_mi != null:
			mi.add_child(edge_mi)
	return mi

static func box(sz: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = sz * CAD_SCALE
	return bm

static func cyl(rt: float, rb: float, h: float, segs := 20) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = rt * CAD_SCALE
	cm.bottom_radius = rb * CAD_SCALE
	cm.height = h * CAD_SCALE
	cm.radial_segments = segs
	return cm

static func sphere(r: float, segs := 14) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r * CAD_SCALE
	sm.height = r * 2.0 * CAD_SCALE
	sm.radial_segments = segs
	sm.rings = maxi(6, segs / 2)
	return sm

static func torus(inner_r: float, outer_r: float) -> TorusMesh:
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r * CAD_SCALE
	tm.outer_radius = outer_r * CAD_SCALE
	return tm

static func add_fluted_knob(part_node: Node3D, radius: float, length: float, body_mat: StandardMaterial3D, cap_mat: StandardMaterial3D, ptr_mat: StandardMaterial3D, pos := Vector3.ZERO) -> void:
	add_part_mesh(part_node, cyl(radius * 1.15, radius * 1.24, length * 0.25, 20), body_mat, pos + Vector3(0, 0, -length * 0.35), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(part_node, cyl(radius * 0.92, radius, length * 0.78, 20), body_mat, pos + Vector3(0, 0, length * 0.1), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(part_node, cyl(radius * 0.82, radius * 0.82, 0.03, 20), cap_mat, pos + Vector3(0, 0, length * 0.5), Vector3(PI * 0.5, 0, 0), false)
	add_part_mesh(part_node, box(Vector3(0.03, radius * 0.75, 0.04)), ptr_mat, pos + Vector3(0, radius * 0.42, length * 0.51), Vector3.ZERO, false)

static func add_bnc_connector(part_node: Node3D, metal_mat: StandardMaterial3D, insul_mat: StandardMaterial3D, pos := Vector3.ZERO, rot_y := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = pos * CAD_SCALE
	holder.rotation.y = rot_y
	part_node.add_child(holder)
	add_part_mesh(holder, cyl(0.16, 0.16, 0.08, 6), metal_mat, Vector3(0, 0, 0.04), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(holder, cyl(0.125, 0.125, 0.34, 18), metal_mat, Vector3(0, 0, 0.22), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(holder, cyl(0.08, 0.08, 0.35, 14), insul_mat, Vector3(0, 0, 0.22), Vector3(PI * 0.5, 0, 0), false)
	add_part_mesh(holder, cyl(0.022, 0.022, 0.32, 8), metal_mat, Vector3(0, 0, 0.25), Vector3(0, 0, PI * 0.5), false)

static func _create_edge_overlay(mesh: Mesh) -> MeshInstance3D:
	var faces := mesh.get_faces()
	if faces.is_empty():
		return null
	var line_verts := PackedVector3Array()
	var n_tris := faces.size() / 3
	for t in range(n_tris):
		var a := faces[t * 3]
		var b := faces[t * 3 + 1]
		var c := faces[t * 3 + 2]
		line_verts.append(a); line_verts.append(b)
		line_verts.append(b); line_verts.append(c)
		line_verts.append(c); line_verts.append(a)
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = line_verts
	am.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_color = Color(0.06, 0.09, 0.16, 0.55)
	em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var edge_mi := MeshInstance3D.new()
	edge_mi.name = "CadEdgeLines"
	edge_mi.mesh = am
	edge_mi.material_override = em
	return edge_mi
