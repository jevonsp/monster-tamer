extends TextureRect
var player_actor
var enemy_actor

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

func _ready() -> void:
	Global.send_sprite_shake.connect(_play_sprite_shake)
	Global.send_monster_fainted.connect(_play_monster_faint)
	
func _play_monster_faint(target: Monster) -> void:
	if target == player_actor:
		animation_player.play("player_faint")
	else:
		animation_player.play("enemy_faint")
	
func _play_sprite_shake(target: Monster) -> void:
	if target == player_actor:
		animation_player.play("player_hit")
	else:
		animation_player.play("enemy_hit")
