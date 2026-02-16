extends TextureRect
var player_actor
var enemy_actor
var original_position: Vector2
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

func _ready() -> void:
	original_position = global_position
	Global.send_sprite_shake.connect(_play_sprite_shake)
	Global.send_monster_fainted.connect(_play_monster_faint)
	
	
func _play_sprite_shake(target: Monster) -> void:
	if animation_player.is_playing():
		return
	if target == player_actor:
		animation_player.play("player_hit")
	else:
		animation_player.play("enemy_hit")


func _play_monster_faint(target: Monster) -> void:
	if animation_player.is_playing():
		return
	if target == player_actor:
		animation_player.play("player_faint")
		player_actor = null
	else:
		animation_player.play("enemy_faint")
		enemy_actor = null
	
	
func clear_image() -> void:
	reset_texture()
	reset_position()
	Global.monster_fainted_animation_complete.emit()


func reset_texture() -> void:
	texture = null
	
	
func reset_position() -> void:
	animation_player.play("RESET")
