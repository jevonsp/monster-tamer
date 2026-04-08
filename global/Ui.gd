extends Node

@warning_ignore_start("unused_signal")
signal switch_ui_context(new_context: Global.AccessFrom)
signal send_text_box(
		object: Node,
		text: Array[String],
		auto_complete: bool,
		is_question: bool,
		toggles_player: bool,
)
signal answer_given(answer: bool)
signal text_box_complete
signal request_open_menu
signal on_menu_closed
signal request_open_party
signal on_party_closed
signal monster_selected(monster: Monster)
signal item_finished_using
signal request_switch_creation(index: int)
signal request_open_inventory
signal on_inventory_closed
signal item_selected(item: Item)
signal set_inventory_use(value: bool)
signal set_inventory_give(value: bool)
signal request_open_summary(monster: Monster)
signal on_summary_closed
signal move_learning_finished
signal request_open_storage
signal request_open_store(store_component: NPCStoreComponent)
signal grab_default_battle_focus
signal send_move_helper_panel_info(move: Move, player_actor: Monster, enemy_actor: Monster)
signal update_save_info
signal request_text_entry
signal text_enter_pressed(chosen_string: String)
signal text_cancel_pressed
signal text_cancel_response(answer: bool)
@warning_ignore_restore("unused_signal")
