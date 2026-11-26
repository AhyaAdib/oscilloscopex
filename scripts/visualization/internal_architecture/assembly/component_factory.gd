class_name ComponentFactory
extends RefCounted

const CAD_SCALE := 0.085

static func make_dual_mat(real_hex: int, bp_hex: int, rough := 0.5, metal := 0.25, tex: Texture2D = null, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var bp_col := Color.hex((bp_hex << 8) | 0xFF)
	var real_col := Color.hex((real_hex << 8) | 0xFF)
	m.albedo_color = Color(bp_col.r, bp_col.g, bp_col.b, alpha)
	m.roughness = 0.85
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

static func add_part_mesh(part_node: Node3D, mesh: Mesh, material: StandardMaterial3D, pos: Vector3, rot := Vector3.ZERO, _add_edges := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos * CAD_SCALE
	mi.rotation = rot
	mi.material_override = material.duplicate()
	part_node.add_child(mi)
	return mi

static func box(sz: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = sz * CAD_SCALE
	return bm

static func cyl(rt: float, rb: float, h: float, segs := 10) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = rt * CAD_SCALE
	cm.bottom_radius = rb * CAD_SCALE
	cm.height = h * CAD_SCALE
	cm.radial_segments = mini(segs, 12)
	cm.rings = 1
	return cm

static func sphere(r: float, segs := 8) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r * CAD_SCALE
	sm.height = r * 2.0 * CAD_SCALE
	sm.radial_segments = mini(segs, 10)
	sm.rings = 4
	return sm

static func torus(inner_r: float, outer_r: float) -> TorusMesh:
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r * CAD_SCALE
	tm.outer_radius = outer_r * CAD_SCALE
	tm.rings = 12
	tm.ring_segments = 8
	return tm

static func add_fluted_knob(part_node: Node3D, radius: float, length: float, body_mat: StandardMaterial3D, cap_mat: StandardMaterial3D, ptr_mat: StandardMaterial3D, pos := Vector3.ZERO) -> void:
	add_part_mesh(part_node, cyl(radius * 1.15, radius * 1.24, length * 0.25, 10), body_mat, pos + Vector3(0, 0, -length * 0.35), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(part_node, cyl(radius * 0.92, radius, length * 0.78, 10), body_mat, pos + Vector3(0, 0, length * 0.1), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(part_node, cyl(radius * 0.82, radius * 0.82, 0.03, 10), cap_mat, pos + Vector3(0, 0, length * 0.5), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(part_node, box(Vector3(0.03, radius * 0.75, 0.04)), ptr_mat, pos + Vector3(0, radius * 0.42, length * 0.51))

static func add_bnc_connector(part_node: Node3D, metal_mat: StandardMaterial3D, insul_mat: StandardMaterial3D, pos := Vector3.ZERO, rot_y := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = pos * CAD_SCALE
	holder.rotation.y = rot_y
	part_node.add_child(holder)
	add_part_mesh(holder, cyl(0.16, 0.16, 0.08, 6), metal_mat, Vector3(0, 0, 0.04), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(holder, cyl(0.125, 0.125, 0.34, 10), metal_mat, Vector3(0, 0, 0.22), Vector3(PI * 0.5, 0, 0))
	add_part_mesh(holder, cyl(0.08, 0.08, 0.35, 8), insul_mat, Vector3(0, 0, 0.22), Vector3(PI * 0.5, 0, 0))
