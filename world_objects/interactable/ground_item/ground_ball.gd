class_name GroundBall
extends StaticObject

enum Type { ITEM, MONSTER }

@export var type: Type = Type.ITEM
@export var item: Item
@export var monster_data: MonsterData
@export_range(1, 100) var monster_level: int = 1
@export var is_obtained: bool = false:
	set(value):
		is_obtained = value
		if is_obtained:
			visible = false
			collision_shape_2d.disabled = true

var story_component: StoryComponent

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_setup()


func interact(body: CharacterBody2D) -> void:
	if not body.is_in_group("player"):
		printerr("Static Obj %s interacted with by Body %s,\nThis should never happen.\nExiting interact()")
		return

	var obj_name = item.name if type == Type.ITEM else monster_data.species

	if not text.is_empty():
		Global.send_text_box.emit(self, text, is_autocomplete, is_question, true)
		await Global.text_box_complete
	else:
		if not is_question:
			var formatted: Array[String] = ["You found a %s!" % [obj_name]]
			Global.send_text_box.emit(self, formatted, is_autocomplete, is_question, true)
			await Global.text_box_complete
		else:
			var formatted: Array[String] = ["Take the %s?" % [obj_name]]
			Global.send_text_box.emit(self, formatted, is_autocomplete, is_question, true)
			await Global.text_box_complete
	if not is_question:
		trigger()
		return


func trigger() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	match type:
		Type.ITEM:
			player.inventory_handler.add(item)
		Type.MONSTER:
			var monster = monster_data.set_up(monster_level)
			player.party_handler.add(monster)
	if story_component:
		story_component.trigger()
	obtain()


func obtain() -> void:
	is_obtained = true


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()

	new_saved_data.node_path = get_path()
	new_saved_data.is_obtained = is_obtained

	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			if data.is_obtained:
				obtain()


func _setup() -> void:
	_setup_sprite()
	_set_components()


func _setup_sprite() -> void:
	match type:
		Type.ITEM:
			if item.ground_texture != null:
				sprite_2d.texture = item.ground_texture
		Type.MONSTER:
			match monster_data.species.to_lower():
				"pyro badger":
					sprite_2d.frame = 0
				"pistol shrimp":
					sprite_2d.frame = 1
				"fox mcleaf":
					sprite_2d.frame = 2
				_:
					pass


func _set_components() -> void:
	for child in get_children():
		if child is StoryComponent:
			story_component = child
