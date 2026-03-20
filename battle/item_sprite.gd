extends Sprite2D
const BALL = preload("uid://iikfm8js0p7y")
var starting_pos: Vector2
@onready var path_follow_2d: PathFollow2D = $".."
@onready var enemy_texture_rect: TextureRect = $"../../../../Content/EnemyTextureRect"

func _ready() -> void:
	if visible:
		visible = false
		
	Global.send_item_throw_animation.connect(_on_item_throw_animation_recieved)
	print_debug("BATTLE: item_sprite ready")
	

func _on_item_throw_animation_recieved(item: Item) -> void:
	print_debug("BATTLE: item throw received item=%s" % [item])
	if item.battle_texture:
		texture = item.battle_texture
	visible = true
	await _animate_throw_item()
	print_debug("BATTLE: item throw received complete item=%s" % [item])


func _animate_throw_item() -> void:
	print_debug("BATTLE: item throw animation start")
	var tween = get_tree().create_tween()
	tween.tween_property(path_follow_2d, "progress_ratio", 1.0, 0.5)
	await tween.finished
	Global.item_animation_complete.emit()
	print_debug("BATTLE: item throw animation signal emitted")


func reset_ball() -> void:
	print_debug("BATTLE: item reset_ball")
	path_follow_2d.progress_ratio = 0.0
	texture = BALL
	hframes = 3
	frame = 1
	visible = false
