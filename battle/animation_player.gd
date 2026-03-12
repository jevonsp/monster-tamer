extends AnimationPlayer
var player_actor
var enemy_actor
@onready var player_texture_rect: TextureRect = $"../Content/PlayerTextureRect"
@onready var enemy_texture_rect: TextureRect = $"../Content/EnemyTextureRect"

func _ready() -> void:
	Global.send_sprite_shake.connect(_play_sprite_shake)
	Global.send_monster_fainted.connect(_play_monster_faint)
	Global.send_monster_switch_out.connect(_play_monster_switch_out)
	Global.send_monster_switch_in.connect(_play_monster_switch_in)
	
	
func _play_sprite_shake(target: Monster) -> void:
	if is_playing():
		stop()
	if target == player_actor:
		play("player_hit")
	else:
		play("enemy_hit")


func _play_monster_faint(target: Monster) -> void:
	if is_playing():
		stop()
	if target == player_actor:
		play("player_faint")
	else:
		play("enemy_faint")
	
	
func _play_monster_switch_out(target: Monster) -> void:
	if is_playing():
		stop()
	if target == player_actor:
		play("player_switch_out")
		player_actor = null
	else:
		play("enemy_switch_out")
		enemy_actor = null
	
	await animation_finished
	Global.monster_switch_out_animation_complete.emit()
	
	
func _play_monster_switch_in(target: Monster) -> void:
	if is_playing():
		stop()
	if target == player_actor:
		play("player_switch_in")
	else:
		play("enemy_switch_in")
	
	await animation_finished
	Global.monster_switch_in_animation_complete.emit()
	
	
func clear_image() -> void:
	reset_textures()
	reset_position()
	Global.monster_fainted_animation_complete.emit()


func reset_textures() -> void:
	player_texture_rect.texture = null
	enemy_texture_rect.texture = null
	
	
func reset_position() -> void:
	play("RESET")
