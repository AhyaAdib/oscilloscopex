class_name InternalAssemblyRoot
extends Node3D

const CHASSIS_ROOT_OFFSET := Vector3(-0.17, 0.0, 0.0)
const CABINET_CENTER := Vector3(0.0, 0.105, 0.0)
const CABINET_SIZE := Vector3(0.38, 0.19, 0.36)

var chassis_holder: Node3D
var assembly_root: Node3D
var ghost_shell: Node3D
var floor_grid: Node3D
var subsystem_nodes := {}

func _ready() -> void:
	name = "InternalAssemblyRoot"
	floor_grid = ChassisShellBuilder.build_engineering_grid(self, 0.0)

	chassis_holder = Node3D.new()
	chassis_holder.name = "ChassisReferenceHolder"
	chassis_holder.position = CHASSIS_ROOT_OFFSET
	add_child(chassis_holder)

	assembly_root = Node3D.new()
	assembly_root.name = "SubsystemAssemblyRoot"
	chassis_holder.add_child(assembly_root)

	subsystem_nodes = SubsystemBuilder.build_all_subsystems(assembly_root)

	ghost_shell = ChassisShellBuilder.build_ghost_shell(chassis_holder, CABINET_CENTER, CABINET_SIZE)
	ghost_shell.visible = true

func set_chassis_shell_visible(show_shell: bool) -> void:
	if ghost_shell != null:
		ghost_shell.visible = show_shell

func apply_explosion_factor(factor: float) -> void:
	var t := clampf(factor, 0.0, 1.0)
	for cfg in ArchitectureRegistry.SUBSYSTEMS:
		var sid: String = cfg["id"]
		if subsystem_nodes.has(sid):
			var node: Node3D = subsystem_nodes[sid]
			var base_p: Vector3 = cfg["assembled_pos"]
			var off_p: Vector3 = cfg["explode_offset"]
			node.position = base_p + off_p * t

func get_assembled_reference_frame() -> Transform3D:
	return assembly_root.global_transform
