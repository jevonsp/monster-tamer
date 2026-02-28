extends TextureRect
var player_actor
var enemy_actor
var original_position: Vector2
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

func _ready() -> void:
	original_position = global_position
	Global.send_sprite_shake.connect(_play_sprite_shake)
	Global.send_monster_fainted.connect(_play_monster_faint)
	Global.send_monster_switch_out.connect(_play_monster_switch_out)
	Global.send_monster_switch_in.connect(_play_monster_switch_in)
	
	
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
	
	
func _play_monster_switch_out(target: Monster) -> void:
	if animation_player.is_playing():
		return
	if target == player_actor:
		animation_player.play("player_switch_out")
		player_actor = null
	else:
		animation_player.play("enemy_switch_out")
		enemy_actor = null
	
	await animation_player.animation_finished
	Global.monster_switch_out_animation_complete.emit()

	
	
func _play_monster_switch_in(target: Monster) -> void:
	if animation_player.is_playing():
		return
	if target == player_actor:
		animation_player.play("player_switch_in")
	else:
		animation_player.play("enemy_switch_in")
	
	await animation_player.animation_finished
	Global.monster_switch_in_animation_complete.emit()
	
func clear_image() -> void:
	reset_texture()
	reset_position()
	Global.monster_fainted_animation_complete.emit()


func reset_texture() -> void:
	texture = null
	
	
func reset_position() -> void:
	animation_player.play("RESET")
