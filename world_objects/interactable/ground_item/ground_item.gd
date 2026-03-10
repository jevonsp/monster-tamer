extends StaticObject
class_name GroundItem
@export var item: Item
@export var is_obtained: bool = false:
	set(value):
		is_obtained = value
		if is_obtained:
			visible = false
			collision_shape_2d.disabled = true
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	setup()


func setup() -> void:
	if item.ground_texture != null:
		sprite_2d.texture = item.ground_texture
		

func interact(body: CharacterBody2D) -> void:
	if not body.is_in_group("player"):
		printerr("Static Obj %s interacted with by Body %s,\nThis should never happen.\nExiting interact()")
		return
	
	if not text.is_empty():
		var tp = true # Toggles Player
		Global.send_overworld_text_box.emit(self, text, is_autocomplete, is_question, tp)
	else:
		var formatted: Array[String] = ["You found a %s!" % [item.name]]
		var tp = true # Toggles Player
		Global.send_overworld_text_box.emit(self, formatted, is_autocomplete, is_question, tp)
	if not is_question:
		await Global.text_box_complete
		trigger(body)
		return


func trigger(body) -> void:
	if body is Player:
		body.inventory_handler.add(item)
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
