extends Node
const DEFAULT_DELAY: float = 1.0
@warning_ignore_start("unused_signal")
# Player
signal toggle_player
signal step_completed(position: Vector2)
# WildZone
signal wild_battle_requested(mon_data: MonsterData, level: int)
signal player_party_requested
signal send_player_party(party: Array[Monster])
# Battle
# Label
signal send_text_box(text: Array[String], auto_complete: bool)
signal text_box_complete
# Move Animation
signal send_move_animation(scene: PackedScene)
signal move_animation_complete
# Sprite Shake
signal send_sprite_shake(target: Monster)
# Hitpoints
signal send_hitpoints_change(target: Monster, new_hp: int)
signal hitpoints_animation_complete
@warning_ignore_restore("unused_signal")
