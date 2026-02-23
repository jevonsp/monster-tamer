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
	if text != [""]:
		super(body)
	else:
		if not body.is_in_group("player"):
			printerr("Static Obj %s interacted with by Body %s,\nThis should never happen.\nExiting interact()")
			return
		if text == [""]:
			var formatted: Array[String] = ["You found a %s!" % [item.name]]
			Global.send_overworld_text_box.emit(self, formatted, is_autocomplete, is_question)
	if not is_question:
		await Global.overworld_text_box_complete
		trigger(body)
		return


func trigger(body) -> void:
	if body is Player:
		body.inventory_handler.add(item)
	obtain()

func obtain() -> void:
	is_obtained = true
