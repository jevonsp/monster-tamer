extends Node

# gdlint:ignore-file:god-class-signals
@warning_ignore_start("unused_signal")
signal toggle_in_battle
signal battle_started
signal wild_battle_requested(mon_data: MonsterData, level: int)
signal trainer_battle_requested(trainer: Trainer3D)
#signal add_switch_to_turn_queue(switch: Switch)
signal switch_monster_to_first(monster: Monster)
signal battle_switch_complete
signal add_item_to_turn_queue(item: Item)
signal battle_ended(enemy_trainer: Trainer3D)
signal send_move_animation(scene: PackedScene)
signal move_animation_complete
signal send_item_throw_animation(item: Item)
signal item_animation_complete
signal send_item_wiggle(times: int)
signal wiggle_animation_complete
signal send_capture_animation
signal send_escape_animation
signal capture_or_escape_animation_complete
signal send_sprite_shake(target: Monster)
signal send_hitpoints_change(target: Monster, new_hp: int)
signal hitpoints_animation_complete
signal send_monster_fainted(monster: Monster)
signal monster_fainted_animation_complete
signal send_monster_death_experience(amount: int)
signal monster_gained_experience(target: Monster, amount: int)
signal experience_animation_complete
signal player_done_giving_exp
signal monster_gained_level(target: Monster, amount: int)
signal request_battle_level_up_resolution(monster: Monster, amount: int)
signal battle_level_up_resolution_complete
signal switch_battle_actors(old: Monster, new: Monster)
signal send_monster_switch_out(target: Monster)
signal send_monster_switch_in(target: Monster)
signal monster_switch_out_animation_complete
signal monster_switch_in_animation_complete
signal request_forced_switch
signal send_selected_force_switch(target: Monster)
signal send_stat_change_animation(monster: Monster, stat: Monster.Stat, amount: int)
signal stat_change_animation_complete
signal request_display_monsters
@warning_ignore_restore("unused_signal")
