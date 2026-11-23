class_name CampusStudentBuilder
extends RefCounted

static var _chest_badge_tex: Texture2D = null

static func build_student(parent: Node3D, variant: String = "man", is_seated: bool = true) -> Dictionary:
	var av := Node3D.new()
	parent.add_child(av)

	var shirt_blue := Color(0.16, 0.30, 0.47)
	var shirt_dark := Color(0.11, 0.21, 0.34)
	var band_yellow := Color(0.92, 0.80, 0.22)
	var pants_black := Color(0.07, 0.08, 0.10)
	var shoe_black := Color(0.05, 0.05, 0.06)
	var skin_col := Color(0.84, 0.65, 0.53)
	var hair_black := Color(0.08, 0.08, 0.10)
	var hijab_black := Color(0.07, 0.07, 0.09)

	var is_female := (variant == "hijab" or variant == "woman")
	var hip_y := 0.47 if is_seated else 0.90

	# 1. Pelvis & Articulated Legs
	_add_loft(av, [
		[-0.065, 0.135, 0.092],
		[0.0,    0.155, 0.108],
		[0.065,  0.145, 0.098]
	], Vector3(0, hip_y, 0), pants_black, 0.72, 10)

	var hip_x := 0.085 if is_female else 0.094
	var leg_l := _build_leg(av, Vector3(-hip_x, hip_y - 0.04, 0.0), pants_black, shoe_black, is_seated)
	var leg_r := _build_leg(av, Vector3(hip_x, hip_y - 0.04, 0.0), pants_black, shoe_black, is_seated)

	if is_seated:
		_add_cyl(av, 0.18, 0.032, Vector3(0, 0.44, 0.03), Color(0.16, 0.18, 0.21), 0.50, 14)
		_add_cyl(av, 0.022, 0.44, Vector3(0, 0.22, 0.03), Color(0.10, 0.11, 0.13), 0.40, 10)

	# 2. Tailored DTE Work Shirt Torso + Collar + Pockets + DTE/PENS Crest
	var torso := Node3D.new()
	torso.position = Vector3(0, hip_y + 0.05, 0)
	av.add_child(torso)

	var w_bot := 0.142 if is_female else 0.162
	var w_mid := 0.132 if is_female else 0.158
	var w_top := 0.182 if is_female else 0.208
	_add_loft(torso, [
		[0.0,  w_bot, 0.102],
		[0.14, w_mid, 0.096],
		[0.32, w_top, 0.118],
		[0.43, w_top * 0.92, 0.105],
		[0.46, 0.085, 0.078]
	], Vector3.ZERO, shirt_blue, 0.62, 12)

	_add_loft(torso, [
		[0.445, 0.084, 0.080],
		[0.478, 0.074, 0.072]
	], Vector3.ZERO, shirt_dark, 0.58, 12)

	_add_box(torso, Vector3(0.022, 0.38, 0.008), Vector3(0.0, 0.22, 0.114), shirt_dark, 0.60)
	for by in [0.12, 0.21, 0.30, 0.39]:
		_add_cyl(torso, 0.0042, 0.005, Vector3(0.0, by, 0.119), Color(0.06, 0.07, 0.09), 0.35, 8).rotation.x = PI * 0.5

	for px in [-0.078, 0.078]:
		_add_box(torso, Vector3(0.068, 0.078, 0.012), Vector3(px, 0.275, 0.114), shirt_dark, 0.62)
		_add_box(torso, Vector3(0.072, 0.022, 0.015), Vector3(px, 0.306, 0.116), shirt_blue, 0.58)
	_add_box(torso, Vector3(0.008, 0.090, 0.008), Vector3(0.025, 0.275, 0.117), Color(0.05, 0.05, 0.07), 0.40)

	var badge_plate := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.255, 0.070)
	badge_plate.mesh = qm
	badge_plate.position = Vector3(0.0, 0.362, 0.116)
	badge_plate.rotation.x = -0.08
	var bmat := StandardMaterial3D.new()
	bmat.albedo_texture = _get_chest_badge_texture()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.roughness = 0.55
	badge_plate.material_override = bmat
	torso.add_child(badge_plate)

	# 3. Neck & Properly Proportioned Low-Poly Human Head (Open Face, No Helmet Overlap)
	var head_pivot := Node3D.new()
	head_pivot.position = Vector3(0.0, 0.465, 0.0)
	torso.add_child(head_pivot)

	# Slender human neck
	_add_cyl(head_pivot, 0.038, 0.082, Vector3(0, 0.038, 0), skin_col, 0.58, 12)

	# Anatomically proportioned human head (height 0.205m, width 0.152m, depth 0.176m)
	var jaw_rx := 0.044 if is_female else 0.050
	var cheek_rx := 0.072 if is_female else 0.077
	var head_node := _add_loft(head_pivot, [
		[0.052, 0.020, 0.026],   # Chin
		[0.080, jaw_rx, 0.062],  # Jawline
		[0.122, cheek_rx, 0.084],# Cheekbones
		[0.162, cheek_rx * 1.02, 0.088], # Brow / temple
		[0.202, 0.064, 0.076],   # Upper forehead / cranium
		[0.224, 0.022, 0.028]    # Crown
	], Vector3(0, 0, 0.012), skin_col, 0.56, 14)

	# Crisp Facial Features positioned cleanly on the front face (+Z = +0.088)
	for ex in [-0.027, 0.027]:
		_add_box(head_node, Vector3(0.022, 0.005, 0.006), Vector3(ex, 0.160, 0.085), hair_black, 0.7)
		_add_box(head_node, Vector3(0.018, 0.009, 0.005), Vector3(ex, 0.148, 0.085), Color(0.95, 0.95, 0.94), 0.25)
		_add_box(head_node, Vector3(0.009, 0.008, 0.007), Vector3(ex, 0.148, 0.086), Color(0.12, 0.09, 0.07), 0.20)
	# Sculpted nose bridge & tip
	var nose := _add_loft(head_node, [
		[0.116, 0.008, 0.013],
		[0.150, 0.005, 0.007]
	], Vector3(0.0, 0.0, 0.088), skin_col.darkened(0.05), 0.55, 6)
	nose.rotation.x = -0.18
	# Subtle lips
	_add_box(head_node, Vector3(0.022, 0.004, 0.006), Vector3(0.0, 0.094, 0.078), Color(0.62, 0.39, 0.36), 0.55)

	if variant == "hijab":
		# Hijab Hood shifted BACKWARD (z = -0.022) so the entire face (z > +0.045) remains completely visible!
		_add_loft(head_pivot, [
			[0.048, 0.078, 0.074],   # Under-chin scarf wrap
			[0.095, 0.084, 0.082],   # Side cheek framing
			[0.155, 0.088, 0.088],   # Upper hood framing forehead
			[0.205, 0.080, 0.084],   # Crown hood
			[0.232, 0.026, 0.030]    # Top crown
		], Vector3(0.0, 0.0, -0.022), hijab_black, 0.76, 14)
		# Draped neck & chest hijab fold
		_add_loft(head_pivot, [
			[-0.015, 0.088, 0.082],
			[0.035,  0.076, 0.074],
			[0.062,  0.068, 0.068]
		], Vector3(0.0, 0.0, -0.006), hijab_black, 0.78, 12)
		# Back draped triangular veil over upper back
		var back_veil := _add_loft(torso, [
			[0.30, 0.022, 0.014],
			[0.38, 0.088, 0.034],
			[0.45, 0.105, 0.048]
		], Vector3(0.0, 0.0, -0.095), hijab_black, 0.76, 10)
		back_veil.rotation.x = 0.12
	elif variant == "woman":
		# Shoulder-Length Parted Hair shifted BACKWARD (z = -0.026) framing sides & back of head
		_add_loft(head_pivot, [
			[-0.010, 0.094, 0.076],  # Shoulder-length hair hem
			[0.068,  0.090, 0.080],  # Neck curtain
			[0.145,  0.088, 0.086],  # Cheek framing hair
			[0.198,  0.080, 0.084],  # Upper crown hair
			[0.232,  0.032, 0.036]
		], Vector3(0.0, 0.0, -0.026), hair_black, 0.65, 14)
	else:
		# Cropped Men's Hair Cap shifted BACKWARD (z = -0.016) + Visible Ears
		_add_loft(head_pivot, [
			[0.115, 0.078, 0.078],
			[0.172, 0.082, 0.086],
			[0.208, 0.070, 0.078],
			[0.230, 0.028, 0.034]
		], Vector3(0.0, 0.0, -0.016), hair_black, 0.65, 14)
		for ear_x in [-0.076, 0.076]:
			_add_cyl(head_node, 0.012, 0.028, Vector3(ear_x, 0.140, -0.004), skin_col, 0.58, 8)

	# 4. Articulated Tapered Arms + Yellow Sleeve Bands + Hands
	var sh_x := 0.198 if is_female else 0.224
	var arm_l := _build_arm(torso, Vector3(-sh_x, 0.40, 0.0), shirt_blue, shirt_dark, band_yellow, skin_col, true)
	var arm_r := _build_arm(torso, Vector3(sh_x, 0.40, 0.0), shirt_blue, shirt_dark, band_yellow, skin_col, false)

	if is_seated:
		torso.rotation.x = 0.16
		arm_l["shoulder"].rotation = Vector3(-0.78, 0.18, 0.10)
		arm_l["elbow"].rotation.x = -0.65
		arm_r["shoulder"].rotation = Vector3(-0.84, -0.22, -0.10)
		arm_r["elbow"].rotation.x = -0.72
	else:
		arm_l["shoulder"].rotation.z = 0.12
		arm_r["shoulder"].rotation.z = -0.12

	return {
		"root": av,
		"torso": torso,
		"head": head_pivot,
		"arm_l": arm_l,
		"arm_r": arm_r,
		"leg_l": leg_l,
		"leg_r": leg_r
	}

static func _build_arm(parent: Node3D, pos: Vector3, shirt_col: Color, pocket_col: Color, yellow_col: Color, skin_col: Color, is_left: bool) -> Dictionary:
	var shoulder := Node3D.new()
	shoulder.position = pos
	parent.add_child(shoulder)

	_add_loft(shoulder, [
		[-0.23, 0.042, 0.042],
		[-0.12, 0.048, 0.048],
		[0.01,  0.054, 0.054]
	], Vector3.ZERO, shirt_col, 0.62, 10)
	_add_loft(shoulder, [
		[-0.145, 0.0485, 0.0485],
		[-0.102, 0.0505, 0.0505]
	], Vector3.ZERO, yellow_col, 0.48, 10)
	var side_x := -0.046 if is_left else 0.046
	_add_box(shoulder, Vector3(0.010, 0.064, 0.044), Vector3(side_x, -0.172, 0.0), pocket_col, 0.62)

	var elbow := Node3D.new()
	elbow.position = Vector3(0, -0.23, 0)
	shoulder.add_child(elbow)
	_add_loft(elbow, [
		[-0.22, 0.032, 0.032],
		[-0.11, 0.038, 0.038],
		[0.0,   0.042, 0.042]
	], Vector3.ZERO, shirt_col, 0.62, 10)
	_add_loft(elbow, [
		[-0.30, 0.016, 0.022],
		[-0.25, 0.020, 0.030],
		[-0.22, 0.024, 0.026]
	], Vector3.ZERO, skin_col, 0.55, 8)

	return {"shoulder": shoulder, "elbow": elbow}

static func _build_leg(parent: Node3D, pos: Vector3, pants_col: Color, shoe_col: Color, is_seated: bool) -> Dictionary:
	var hip := Node3D.new()
	hip.position = pos
	parent.add_child(hip)

	_add_loft(hip, [
		[-0.42, 0.058, 0.062],
		[-0.21, 0.068, 0.074],
		[0.0,   0.076, 0.082]
	], Vector3.ZERO, pants_col, 0.72, 10)

	var knee := Node3D.new()
	knee.position = Vector3(0, -0.42, 0)
	hip.add_child(knee)
	_add_loft(knee, [
		[-0.41, 0.048, 0.052],
		[-0.20, 0.054, 0.058],
		[0.0,   0.058, 0.062]
	], Vector3.ZERO, pants_col, 0.72, 10)
	var shoe := _add_loft(knee, [
		[-0.095, 0.032, 0.022],
		[-0.025, 0.042, 0.028],
		[0.065,  0.044, 0.030]
	], Vector3(0, -0.425, 0.035), shoe_col, 0.45, 8)
	shoe.rotation.x = PI * 0.5

	if is_seated:
		hip.rotation.x = -1.48
		knee.rotation.x = 1.48

	return {"hip": hip, "knee": knee}

static func _get_chest_badge_texture() -> Texture2D:
	if _chest_badge_tex != null:
		return _chest_badge_tex

	var w := 512
	var h := 144
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var white := Color(0.97, 0.98, 1.0, 0.96)
	var cyan_wing := Color(0.78, 0.90, 1.0, 0.96)

	_draw_dte_text(img, 44, 38, 6, white)

	var cx := 392
	var cy := 50
	for wy in range(-10, 12):
		var span: int = 46 - absi(wy) * 2
		for wx in range(-span, span + 1):
			if absi(wx) > 16:
				img.set_pixel(cx + wx, cy + wy, cyan_wing)
	for dy in range(-22, 23):
		for dx in range(-22, 23):
			var r2 := dx * dx + dy * dy
			if r2 <= 440 and r2 >= 190:
				img.set_pixel(cx + dx, cy + dy, white)
			elif r2 < 120 and dy < 4:
				img.set_pixel(cx + dx, cy + dy - 4, white)

	_draw_pens_text(img, 344, 84, 4, white)

	_chest_badge_tex = ImageTexture.create_from_image(img)
	return _chest_badge_tex

static func _draw_rect_px(img: Image, x0: int, y0: int, rw: int, rh: int, col: Color) -> void:
	for y in range(maxi(0, y0), mini(img.get_height(), y0 + rh)):
		for x in range(maxi(0, x0), mini(img.get_width(), x0 + rw)):
			img.set_pixel(x, y, col)

static func _draw_dte_text(img: Image, x: int, y: int, s: int, col: Color) -> void:
	_draw_rect_px(img, x, y, s, s * 8, col)
	_draw_rect_px(img, x + s, y, s * 3, s, col)
	_draw_rect_px(img, x + s, y + s * 7, s * 3, s, col)
	_draw_rect_px(img, x + s * 4, y + s, s, s * 6, col)
	var tx := x + s * 7
	_draw_rect_px(img, tx, y, s * 5, s, col)
	_draw_rect_px(img, tx + s * 2, y + s, s, s * 7, col)
	var ex := x + s * 14
	_draw_rect_px(img, ex, y, s, s * 8, col)
	_draw_rect_px(img, ex + s, y, s * 4, s, col)
	_draw_rect_px(img, ex + s, y + s * 3, s * 3, s, col)
	_draw_rect_px(img, ex + s, y + s * 7, s * 4, s, col)

static func _draw_pens_text(img: Image, x: int, y: int, s: int, col: Color) -> void:
	_draw_rect_px(img, x, y, s, s * 7, col)
	_draw_rect_px(img, x + s, y, s * 3, s, col)
	_draw_rect_px(img, x + s, y + s * 3, s * 3, s, col)
	_draw_rect_px(img, x + s * 4, y + s, s, s * 2, col)
	var ex := x + s * 6
	_draw_rect_px(img, ex, y, s, s * 7, col)
	_draw_rect_px(img, ex + s, y, s * 3, s, col)
	_draw_rect_px(img, ex + s, y + s * 3, s * 2, s, col)
	_draw_rect_px(img, ex + s, y + s * 6, s * 3, s, col)
	var nx := x + s * 11
	_draw_rect_px(img, nx, y, s, s * 7, col)
	_draw_rect_px(img, nx + s, y + s, s, s * 2, col)
	_draw_rect_px(img, nx + s * 2, y + s * 3, s, s * 2, col)
	_draw_rect_px(img, nx + s * 3, y + s * 5, s, s, col)
	_draw_rect_px(img, nx + s * 4, y, s, s * 7, col)
	var sx := x + s * 16
	_draw_rect_px(img, sx + s, y, s * 3, s, col)
	_draw_rect_px(img, sx, y + s, s, s * 2, col)
	_draw_rect_px(img, sx + s, y + s * 3, s * 2, s, col)
	_draw_rect_px(img, sx + s * 3, y + s * 4, s, s * 2, col)
	_draw_rect_px(img, sx, y + s * 6, s * 3, s, col)

static func _add_loft(parent: Node3D, rings: Array, pos: Vector3, col: Color, rough := 0.6, segs := 12) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_verts: Array = []
	for r in rings:
		var y := float(r[0])
		var rx := float(r[1])
		var rz := float(r[2])
		var pts: Array[Vector3] = []
		for i in range(segs):
			var ang := TAU * float(i) / float(segs)
			pts.append(Vector3(cos(ang) * rx, y, sin(ang) * rz))
		ring_verts.append(pts)

	for ri in range(ring_verts.size() - 1):
		var r0: Array = ring_verts[ri]
		var r1: Array = ring_verts[ri + 1]
		for i in range(segs):
			var ni := (i + 1) % segs
			var p00: Vector3 = r0[i]
			var p10: Vector3 = r0[ni]
			var p11: Vector3 = r1[ni]
			var p01: Vector3 = r1[i]
			var n1 := (p10 - p00).cross(p11 - p00).normalized()
			st.set_normal(n1); st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p11)
			var n2 := (p11 - p00).cross(p01 - p00).normalized()
			st.set_normal(n2); st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p01)

	var bot: Array = ring_verts[0]
	var cy_b := float(rings[0][0])
	for i in range(segs):
		var ni := (i + 1) % segs
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3(0, cy_b, 0)); st.add_vertex(bot[ni]); st.add_vertex(bot[i])

	var top: Array = ring_verts[ring_verts.size() - 1]
	var cy_t := float(rings[rings.size() - 1][0])
	for i in range(segs):
		var ni := (i + 1) % segs
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(0, cy_t, 0)); st.add_vertex(top[i]); st.add_vertex(top[ni])

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, col: Color, rough := 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, rad: float, h: float, pos: Vector3, col: Color, rough := 0.5, segs := 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rad
	cm.bottom_radius = rad
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	mi.material_override = mat
	parent.add_child(mi)
	return mi
