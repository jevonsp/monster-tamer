extends Sprite2D
const BALL = preload("uid://iikfm8js0p7y")
var starting_pos: Vector2
@onready var path_follow_2d: PathFollow2D = $".."
@onready var enemy_texture_rect: TextureRect = $"../../../../Content/EnemyTextureRect"

func _ready() -> void:
	Global.send_item_throw_animation.connect(_on_item_throw_animation_recieved)
	Global.send_item_wiggle.connect(_animate_ball_shake)
	Global.send_capture_animation.connect(_animate_capture)
	Global.send_escape_animation.connect(_animate_escape)

func _on_item_throw_animation_recieved(item: Item) -> void:
	if item.battle_texture:
		texture = item.battle_texture
	visible = true
	await _animate_throw_item()


func _animate_throw_item() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(path_follow_2d, "progress_ratio", 1.0, 0.5)
	await tween.finished
	enemy_texture_rect.visible = false
	Global.item_animation_complete.emit()


func _animate_ball_shake(times: int) -> void:
	await get_tree().process_frame
	Global.wiggle_animation_complete.emit()


func _animate_capture() -> void:
	await get_tree().process_frame
	reset_ball()
	reset_enemy()
	Global.capture_or_escape_animation_complete.emit()
	
	
func _animate_escape() -> void:
	await get_tree().process_frame
	reset_ball()
	reset_enemy()
	Global.capture_or_escape_animation_complete.emit()


func reset_ball() -> void:
	path_follow_2d.progress_ratio = 0.0
	texture = BALL
	hframes = 3
	visible = false


func reset_enemy() -> void:
	enemy_texture_rect.visible = true
