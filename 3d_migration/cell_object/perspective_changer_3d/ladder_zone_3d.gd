@tool
class_name LadderZone3D
extends CellObject

const BASE_SIZE := 0.938

@export var ladder_length: int = 1:
	set(val):
		if val <= 0:
			return
		ladder_length = val
		update_ladder()
@export var collision_shape_3d: CollisionShape3D


func _ready() -> void:
	update_ladder()


func update_ladder() -> void:
	if collision_shape_3d == null:
		return
	var box := collision_shape_3d.shape as BoxShape3D
	var new_size_z := BASE_SIZE + (ladder_length - 1)
	box.size.z = new_size_z

	var start_face_z := 0.5 - (BASE_SIZE * 0.5)
	collision_shape_3d.position.z = start_face_z + (new_size_z * 0.5)

	if Engine.is_editor_hint():
		_update_debug_mesh(box.size, collision_shape_3d.position)


func _update_debug_mesh(size: Vector3, pos: Vector3) -> void:
	var mesh_node := get_node_or_null("EditorDebugMesh") as MeshInstance3D
	if mesh_node == null:
		mesh_node = MeshInstance3D.new()
		mesh_node.name = "EditorDebugMesh"
		add_child(mesh_node)
		mesh_node.owner = owner

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = pos

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.8, 1.0, 0.35)
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_node.material_override = mat


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return
	(area as Player3D).travel_handler.is_on_ladder = true


func _on_area_exited(area: Area3D) -> void:
	if area is not Player3D:
		return
	(area as Player3D).travel_handler.is_on_ladder = false
