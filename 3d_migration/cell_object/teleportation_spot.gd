@tool
extends CellObject

@export var draw_debug_shape: bool:
	set(val):
		draw_debug_shape = val
		if Engine.is_editor_hint():
			_get_box_and_shape()
@export var collision_shape_3d: CollisionShape3D


func _ready() -> void:
	if Engine.is_editor_hint():
		_get_box_and_shape()


func _get_box_and_shape():
	if collision_shape_3d == null:
		collision_shape_3d = $CollisionShape3D
	var box := collision_shape_3d.shape as BoxShape3D
	_update_debug_mesh(box.size, collision_shape_3d.position)


func _update_debug_mesh(size: Vector3, pos: Vector3) -> void:
	var mesh_node := get_node_or_null("EditorDebugMesh") as MeshInstance3D
	for child in get_children():
		# gdlint-ignore-next-line
		if child is MeshInstance3D and child != mesh_node and String(child.name).begins_with("EditorDebugMesh"):
			child.queue_free()
	if mesh_node == null:
		mesh_node = MeshInstance3D.new()
		mesh_node.name = "EditorDebugMesh"
		add_child(mesh_node)
	mesh_node.owner = null

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = pos

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(255, 0.0, 0.0, 0.5)
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_node.material_override = mat
	mesh_node.visible = draw_debug_shape
