extends Node
const DEFAULT_DELAY: float = 1.0
@warning_ignore_start("unused_signal")
# Player
signal toggle_player
signal step_completed(position: Vector2)
signal send_respawn_player
# WildZone
signal wild_battle_requested(mon_data: MonsterData, level: int)
signal player_party_requested
signal send_player_party(party: Array[Monster])
# Overworld
# DialogueLabel
signal send_overworld_text_box(object: Node, text: Array[String], auto_complete: bool, is_question: bool)
signal overworld_text_box_complete
# Menu
signal request_open_menu
signal on_menu_closed
# Party
signal request_open_party
signal on_party_closed
# Summary
signal send_summary_index(index: int)
signal request_open_summary()
# Battle
# Label
signal send_battle_text_box(text: Array[String], auto_complete: bool)
signal battle_text_box_complete
# Move Animation
signal send_move_animation(scene: PackedScene)
signal move_animation_complete
# Sprite Shake
signal send_sprite_shake(target: Monster)
# Hitpoints
signal send_hitpoints_change(target: Monster, new_hp: int)
signal hitpoints_animation_complete
# Fainting
signal send_monster_fainted(monster: Monster)
signal monster_fainted_animation_complete
# Experience
signal send_monster_death_experience(amount: int)
signal monster_gained_exp(target: Monster, amount: int)
signal experience_animation_complete
# Level
signal monster_gained_level(target: Monster, amount: int)
@warning_ignore_restore("unused_signal")
