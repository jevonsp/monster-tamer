extends Sprite2D

const BALL = preload("res://3d_migration/cell_object/ground_items/ball_single.png")

var starting_pos: Vector2

@onready var path_follow_2d: PathFollow2D = $".."
@onready var enemy_texture_rect: TextureRect = $"../../../../Content/EnemyTextureRect"


func _ready() -> void:
	if visible:
		visible = false

	Battle.send_item_throw_animation.connect(_on_item_throw_animation_recieved)


func reset_ball() -> void:
	path_follow_2d.progress_ratio = 0.0
	texture = BALL
	hframes = 3
	frame = 1
	visible = false


func _on_item_throw_animation_recieved(item: Item) -> void:
	if item.battle_texture:
		texture = item.battle_texture
	visible = true
	await _animate_throw_item()


func _animate_throw_item() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(path_follow_2d, "progress_ratio", 1.0, 0.5)
	await tween.finished
	Battle.item_animation_complete.emit()
