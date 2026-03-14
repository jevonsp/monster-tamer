extends Node

const DEFAULT_DELAY: float = 1.0

enum AccessFrom {NONE, MENU, BATTLE, PARTY, INVENTORY}

@warning_ignore_start("unused_signal")

#region Player
signal toggle_player
signal toggle_in_battle
signal step_completed(position: Vector2)
signal send_respawn_player
signal battle_started
#endregion

#region Wild/Trainer
signal wild_battle_requested(mon_data: MonsterData, level: int)
signal trainer_battle_requested(trainer: Trainer)
#endregion

#region Party
signal capture_monster(monster: Monster)
signal send_player_party(party: Array[Monster])
signal send_player_storage(storage: Array[Monster])
signal send_player_party_and_storage(party: Array[Monster], storage: Dictionary)
signal request_move_party_to_storage(from_index: int, to_index: int)
signal request_move_storage_to_party(from_index: int, to_index: int)
signal player_party_requested
signal add_switch_to_turn_queue(switch: Switch)
signal switch_monster_to_first(monster: Monster)
signal battle_switch_complete
signal out_of_battle_switch(index_one: int, index_two: int)
#endregion

#region Summary
signal request_switch_moves(monster: Monster, index_one: int, index_two: int)
#endregion

#region Inventory
signal send_player_inventory(inventory: Dictionary[Item, int])
signal player_inventory_requested
signal use_item_on(item: Item, monster: Monster)
signal give_item_to(item: Item, monster: Monster)
signal item_used(item: Item)
#endregion

#region General UI
signal switch_ui_context(new_context: AccessFrom)
signal send_text_box(
	object: Node, text: Array[String], auto_complete: bool, is_question: bool, toggles_player: bool
)
signal text_box_complete
#endregion

#region Overworld
signal request_open_menu
signal on_menu_closed
#endregion

#region Party UI
signal request_open_party
signal on_party_closed
signal monster_selected(monster: Monster)
signal item_finished_using
signal request_switch_creation(index: int)
#endregion

#region Inventory UI
signal request_open_inventory
signal on_inventory_closed
signal item_selected(item: Item)
signal add_item_to_turn_queue(item: Item)
signal set_inventory_use(value: bool)
signal set_inventory_give(value: bool)
#endregion

#region Summary UI
signal send_summary_index(index: int)
signal request_open_summary
signal on_summary_closed
signal move_learning_finished
#endregion

#region Storage UI
signal request_open_storage
signal storage_deposit_monster(monster: Monster)
signal storage_withdraw_monster(monster: Monster)
#endregion

#region Battle
signal battle_ended
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
signal grab_default_battle_focus
signal switch_battle_actors(old: Monster, new: Monster)
signal send_monster_switch_out(target: Monster)
signal send_monster_switch_in(target: Monster)
signal monster_switch_out_animation_complete
signal monster_switch_in_animation_complete
signal request_forced_switch
signal send_selected_force_switch(target: Monster)
#endregion

@warning_ignore_restore("unused_signal")
