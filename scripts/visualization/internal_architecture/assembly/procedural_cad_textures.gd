class_name ProceduralCadTextures
extends RefCounted

static func create_graticule_texture() -> ImageTexture:
	var w := 256
	var h := 208
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var center := Vector2(w * 0.5, h * 0.5)
	for y in range(h):
		for x in range(w):
			var d := clampf(Vector2(x, y).distance_to(center) / 160.0, 0.0, 1.0)
			var col := Color(0.21, 0.66, 0.77).lerp(Color(0.07, 0.37, 0.46), d)
			img.set_pixel(x, y, col)

	var grid_col := Color(0.04, 0.14, 0.19, 0.78)
	for c in range(11):
		var gx := clampi(int(round(float(c) * w / 10.0)), 0, w - 1)
		for y in range(h):
			img.set_pixel(gx, y, grid_col)
	for r in range(9):
		var gy := clampi(int(round(float(r) * h / 8.0)), 0, h - 1)
		for x in range(w):
			img.set_pixel(x, gy, grid_col)

	# CH1 Sine Wave & CH2 Square Wave Phosphor Traces
	var ch1_col := Color(0.82, 0.98, 0.90, 1.0)
	var ch2_col := Color(0.43, 0.91, 0.72, 1.0)
	for x in range(w):
		var u := float(x) / float(w)
		var y1 := clampi(int(74.0 - sin(u * TAU * 3.0) * 26.0), 1, h - 2)
		var y2 := 138 if (int(floor(u * 6.0)) % 2 == 0) else 168
		for dy in range(-1, 2):
			img.set_pixel(x, y1 + dy, ch1_col)
			img.set_pixel(x, y2 + dy, ch2_col)

	return ImageTexture.create_from_image(img)

static func create_pcb_texture(base_col: Color, trace_col: Color) -> ImageTexture:
	var w := 256
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(base_col)

	for i in range(28):
		var y0 := 12 + i * 8
		var knee := 90 + (i % 7) * 10
		for x in range(10, w - 10):
			var y := y0 if x < knee else mini(h - 6, y0 + 10)
			img.set_pixel(x, y, trace_col)

	var pad_col := Color(0.85, 0.70, 0.24)
	for px in range(20, w - 16, 22):
		for py in range(20, h - 16, 22):
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					img.set_pixel(px + dx, py + dy, pad_col)

	return ImageTexture.create_from_image(img)

static func create_front_panel_texture() -> ImageTexture:
	var w := 512
	var h := 336
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var alu := Color(0.78, 0.77, 0.74)
	var olive := Color(0.70, 0.69, 0.64)
	var border := Color(0.24, 0.24, 0.22)

	for y in range(h):
		var streak := 0.025 if (y % 3 == 0) else 0.0
		var c := Color(alu.r + streak, alu.g + streak, alu.b + streak)
		for x in range(w):
			img.set_pixel(x, y, c)

	# Trigger / Timebase olive zone (top-right) & Vertical Mode center strip
	_fill_rect(img, 232, 14, 268, 144, olive)
	_fill_rect(img, 354, 164, 26, 162, olive)
	_stroke_rect(img, 4, 4, w - 8, h - 8, border, 2)
	_stroke_rect(img, 232, 14, 268, 144, border, 1)
	_stroke_rect(img, 232, 164, 122, 162, border, 1)
	_stroke_rect(img, 380, 164, 120, 162, border, 1)

	return ImageTexture.create_from_image(img)

static func create_header_badge_texture() -> ImageTexture:
	var w := 256
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.17, 0.17, 0.16))
	_stroke_rect(img, 2, 2, w - 4, h - 4, Color(0.62, 0.60, 0.56), 1)
	# White brand block + "30" MHz emblem box
	_fill_rect(img, 12, 9, 68, 14, Color(0.94, 0.93, 0.90))
	_fill_rect(img, 120, 11, 76, 10, Color(0.84, 0.82, 0.78))
	_stroke_rect(img, 224, 7, 22, 18, Color(0.94, 0.93, 0.90), 2)
	return ImageTexture.create_from_image(img)

static func _fill_rect(img: Image, x0: int, y0: int, rw: int, rh: int, col: Color) -> void:
	for y in range(maxi(0, y0), mini(img.get_height(), y0 + rh)):
		for x in range(maxi(0, x0), mini(img.get_width(), x0 + rw)):
			img.set_pixel(x, y, col)

static func _stroke_rect(img: Image, x0: int, y0: int, rw: int, rh: int, col: Color, thick: int) -> void:
	_fill_rect(img, x0, y0, rw, thick, col)
	_fill_rect(img, x0, y0 + rh - thick, rw, thick, col)
	_fill_rect(img, x0, y0, thick, rh, col)
	_fill_rect(img, x0 + rw - thick, y0, thick, rh, col)
