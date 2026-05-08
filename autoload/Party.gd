extends Node

# gdlint:ignore-file:god-class-signals
@warning_ignore_start("unused_signal")
signal capture_monster(monster: Monster)
signal send_player_party(party: Array[Monster])
signal send_player_storage(storage: Array[Monster])
signal send_player_party_and_storage(party: Array[Monster], storage: Dictionary)
signal request_move_party_to_storage(from_index: int, to_index: int)
signal request_move_storage_to_party(from_index: int, to_index: int)
signal player_party_requested
signal out_of_battle_switch(index_one: int, index_two: int)
signal request_switch_moves(monster: Monster, index_one: int, index_two: int)
signal request_summary_learn_move(move: Move)
signal request_summary_move_learning(monster: Monster, move: Move)
signal storage_deposit_monster(monster: Monster)
signal storage_withdraw_monster(monster: Monster)
@warning_ignore_restore("unused_signal")
