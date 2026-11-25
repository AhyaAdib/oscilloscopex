class_name ComponentFactory
extends RefCounted

static func mat(col: Color, rough := 0.45, metal := 0.2, emit_col := Color(0, 0, 0, 0), emit_energy := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.roughness = rough
	m.metallic = metal
	if alpha < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_energy
	return m

static func add_box(parent: Node3D, node_name: String, sz: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi

static func add_cyl(parent: Node3D, node_name: String, rad: float, h: float, pos: Vector3, rot: Vector3, material: Material, segs := 14) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = rad
	cm.bottom_radius = rad
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.material_override = material
	parent.add_child(mi)
	return mi

static func add_wire(parent: Node3D, node_name: String, p0: Vector3, p1: Vector3, rad: float, material: Material) -> MeshInstance3D:
	var dir := p1 - p0
	var length := dir.length()
	if length < 0.0005:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = rad
	cm.bottom_radius = rad
	cm.height = length
	cm.radial_segments = 8
	mi.mesh = cm
	mi.position = (p0 + p1) * 0.5
	var up := dir.normalized()
	if absf(up.dot(Vector3.UP)) > 0.999:
		mi.rotation = Vector3.ZERO
	else:
		var axis := Vector3.UP.cross(up).normalized()
		var angle := acos(clampf(Vector3.UP.dot(up), -1.0, 1.0))
		mi.basis = Basis(axis, angle)
	mi.material_override = material
	parent.add_child(mi)
	return mi

static func add_knob(parent: Node3D, node_name: String, rad: float, h: float, pos: Vector3, body_mat: Material, cap_mat: Material) -> Node3D:
	var k := Node3D.new()
	k.name = node_name
	k.position = pos
	parent.add_child(k)
	add_cyl(k, "Skirt", rad * 1.25, 0.002, Vector3(0, 0, 0.001), Vector3(PI * 0.5, 0, 0), cap_mat, 16)
	add_cyl(k, "Body", rad, h, Vector3(0, 0, h * 0.5 + 0.002), Vector3(PI * 0.5, 0, 0), body_mat, 16)
	add_box(k, "Pointer", Vector3(0.0016, rad * 0.85, 0.002), Vector3(0, rad * 0.45, h + 0.0025), cap_mat)
	return k

static func add_dense_pcb(parent: Node3D, node_name: String, sz: Vector3, pos: Vector3, accent: Color) -> Node3D:
	var card := Node3D.new()
	card.name = node_name
	card.position = pos
	parent.add_child(card)

	var pcb_mat := mat(Color(0.06, 0.24, 0.19), 0.40, 0.15)
	var trace_mat := mat(accent, 0.25, 0.3, accent, 1.25)
	var ic_mat := mat(Color(0.11, 0.12, 0.14), 0.35, 0.3)
	var gold_mat := mat(Color(0.90, 0.74, 0.28), 0.28, 0.85)
	var res_mat := mat(Color(0.84, 0.72, 0.52), 0.45, 0.1)
	var cap_blue := mat(Color(0.16, 0.44, 0.82), 0.3, 0.3)
	var cap_orange := mat(Color(0.92, 0.46, 0.16), 0.35, 0.1)

	add_box(card, "Substrate", sz, Vector3.ZERO, pcb_mat)
	add_box(card, "AccentEdge", Vector3(sz.x + 0.001, 0.002, sz.z + 0.001), Vector3(0, sz.y * 0.5, 0), trace_mat)
	add_box(card, "GoldFingers", Vector3(sz.x * 0.76, 0.005, sz.z + 0.002), Vector3(0, -sz.y * 0.48, 0), gold_mat)

	# Dense rows of DIP ICs, axial resistors, radial electrolytic caps, and trimpots
	var cols := 3
	var rows := 3
	for r in range(rows):
		var ry := -sz.y * 0.28 + float(r) * (sz.y * 0.28)
		for c in range(cols):
			var cx := -sz.x * 0.28 + float(c) * (sz.x * 0.28)
			var z_side := (sz.z * 0.5 + 0.003)
			if (r + c) % 3 == 0:
				add_box(card, "DIP_IC", Vector3(0.011, 0.014, 0.005), Vector3(cx, ry, z_side), ic_mat)
			elif (r + c) % 3 == 1:
				add_cyl(card, "ElecCap", 0.0032, 0.009, Vector3(cx, ry, z_side + 0.002), Vector3(PI * 0.5, 0, 0), cap_blue, 10)
			else:
				add_cyl(card, "AxialRes", 0.0016, 0.009, Vector3(cx, ry, z_side), Vector3(0, 0, PI * 0.5), res_mat, 8)
				add_cyl(card, "Trimpot", 0.0028, 0.004, Vector3(cx, ry - 0.006, z_side), Vector3(PI * 0.5, 0, 0), cap_orange, 10)
	return card
