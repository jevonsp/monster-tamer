extends AnimationPlayer
var player_actor
var enemy_actor
@onready var player_texture_rect: TextureRect = $"../Content/PlayerTextureRect"
@onready var enemy_texture_rect: TextureRect = $"../Content/EnemyTextureRect"
@onready var item_sprite: Sprite2D = $"../AnimationContainer/Path2D/PathFollow2D/ItemSprite"

func _ready() -> void:
	Global.send_sprite_shake.connect(_play_sprite_shake)
	Global.send_monster_fainted.connect(_play_monster_faint)
	Global.send_monster_switch_out.connect(_play_monster_switch_out)
	Global.send_monster_switch_in.connect(_play_monster_switch_in)
	Global.send_capture_animation.connect(_animate_capture)
	Global.send_escape_animation.connect(_animate_escape)
	Global.send_item_wiggle.connect(_animate_ball_shake)
	

func reset_textures() -> void:
	player_texture_rect.texture = null
	enemy_texture_rect.texture = null
	
	
func reset_position() -> void:
	play("RESET")
	
	
func clear_image() -> void:
	reset_textures()
	reset_position()
	Global.monster_fainted_animation_complete.emit()
	
	
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


func _animate_ball_shake(times: int) -> void:
	if is_playing():
		stop()
		
	match times:
		0:
			play("shake_zero")
		1:
			play("shake_one")
		2:
			play("shake_two")
		3:
			play("shake_three")
		4:
			play("shake_four")
	
	if is_playing():
		await animation_finished
	
	Global.wiggle_animation_complete.emit()


func _animate_capture() -> void:
	await get_tree().process_frame
	enemy_texture_rect.visible = false
	Global.capture_or_escape_animation_complete.emit()
	
	
func _animate_escape() -> void:
	await get_tree().process_frame
	item_sprite.reset_ball()
	Global.capture_or_escape_animation_complete.emit()
