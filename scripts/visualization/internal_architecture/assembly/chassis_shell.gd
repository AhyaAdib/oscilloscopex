class_name ChassisShellBuilder
extends RefCounted

static func build_ghost_shell(parent: Node3D, cabinet_center: Vector3, cabinet_size: Vector3) -> Node3D:
	var shell_root := Node3D.new()
	shell_root.name = "GhostChassisShell"
	parent.add_child(shell_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.72, 0.96, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(0.14, 0.58, 0.88)
	mat.emission_energy_multiplier = 0.35
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.roughness = 0.25

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "GhostedCabinetHull"
	var box := BoxMesh.new()
	box.size = cabinet_size + Vector3(0.004, 0.004, 0.004)
	mesh_inst.mesh = box
	mesh_inst.position = cabinet_center
	mesh_inst.material_override = mat
	shell_root.add_child(mesh_inst)

	return shell_root

static func build_engineering_grid(parent: Node3D, y_level := 0.0) -> Node3D:
	var grid_root := Node3D.new()
	grid_root.name = "EngineeringGrid"
	parent.add_child(grid_root)

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.16, 0.32, 0.44, 0.45)
	line_mat.roughness = 0.8

	for i in range(-8, 9):
		var offset := float(i) * 0.06
		var x_bar := MeshInstance3D.new()
		var xb := BoxMesh.new()
		xb.size = Vector3(0.96, 0.001, 0.002)
		x_bar.mesh = xb
		x_bar.position = Vector3(0.0, y_level - 0.001, offset)
		x_bar.material_override = line_mat
		grid_root.add_child(x_bar)

		var z_bar := MeshInstance3D.new()
		var zb := BoxMesh.new()
		zb.size = Vector3(0.002, 0.001, 0.96)
		z_bar.mesh = zb
		z_bar.position = Vector3(offset, y_level - 0.001, 0.0)
		z_bar.material_override = line_mat
		grid_root.add_child(z_bar)

	return grid_root
