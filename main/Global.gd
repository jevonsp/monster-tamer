extends Node
@warning_ignore_start("unused_signal")

signal toggle_player

signal step_completed(position: Vector2)
signal wild_battle_requested(mon_data: MonsterData, level: int)
signal player_party_requested
signal send_player_party(party: Array[Monster])

@warning_ignore_restore("unused_signal")
