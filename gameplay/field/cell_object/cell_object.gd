class_name CellObject
extends Area3D

@export var command_lists: Array[CommandList] = []
@export var command_index: int = 0
@export var is_active: bool = true:
	get:
		return _is_active
	set(val):
		if _is_active == val:
			return
		_is_active = val
		_update()
@export var blocks_player: bool = false:
	get:
		return _blocks_player
	set(val):
		if _blocks_player == val:
			return
		_blocks_player = val
		_update()
@export var masks_player: bool = true:
	get:
		return _masks_player
	set(val):
		if _masks_player == val:
			return
		_masks_player = val
		_update()

var interaction_helper: InteractionHelper = InteractionHelper.new(self)
var _is_active: bool = true
var _blocks_player: bool = false
var _masks_player: bool = true


func _ready() -> void:
	_update()


func interact(player: Player3D) -> void:
	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	await interaction_helper.interact(player)

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)


func change_command_index_to(index: int) -> void:
	if index > command_lists.size():
		return

	command_index = index


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()
	new_saved_data.node_path = get_path()

	new_saved_data.is_active = _is_active
	new_saved_data.blocks_player = _blocks_player
	new_saved_data.masks_player = _masks_player
	new_saved_data.is_visible = visible

	saved_data_array.append(new_saved_data)


func on_before_load_game() -> void:
	pass


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			_is_active = data.is_active
			_blocks_player = data.blocks_player
			_masks_player = data.masks_player
			visible = data.is_visible

	_update()


func deactivate() -> void:
	is_active = false
	blocks_player = false
	visible = false
	_update()


func _after_command_list_run(_flow: Command.Flow) -> void:
	pass


func _update() -> void:
	visible = _is_active
	if _blocks_player:
		collision_layer = 3
	else:
		collision_layer = 0
	if _masks_player:
		collision_mask = 2
	else:
		collision_mask = 0


func _sync_editor_debug_mesh_to_collision_shape(
	collision_shape: CollisionShape3D,
	size: Vector3,
	debug_visible: bool,
) -> void:
	if collision_shape == null:
		return
	var mesh_node: MeshInstance3D = null
	for child in collision_shape.get_children():
		if child is MeshInstance3D and String(child.name).begins_with("EditorDebugMesh"):
			if mesh_node == null:
				mesh_node = child as MeshInstance3D
			else:
				child.queue_free()
	for child in get_children():
		if child is MeshInstance3D and String(child.name).begins_with("EditorDebugMesh"):
			if mesh_node == null:
				mesh_node = child as MeshInstance3D
			else:
				child.queue_free()
	if mesh_node == null:
		mesh_node = MeshInstance3D.new()
		mesh_node.name = "EditorDebugMesh"
		collision_shape.add_child(mesh_node)
	elif mesh_node.get_parent() != collision_shape:
		mesh_node.get_parent().remove_child(mesh_node)
		collision_shape.add_child(mesh_node)
	mesh_node.owner = null
	mesh_node.position = Vector3.ZERO
	mesh_node.rotation = Vector3.ZERO
	mesh_node.scale = Vector3.ONE
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(255, 0.0, 0.0, 0.5)
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_node.material_override = mat
	mesh_node.visible = debug_visible
