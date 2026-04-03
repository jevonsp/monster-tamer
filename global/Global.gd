extends Node

@warning_ignore_start("unused_signal")
signal toggle_player
signal step_completed(position: Vector2)
signal send_respawn_player
signal period_of_day_changed
signal time_changed
signal story_flag_triggered(flag: Story.Flag, value: bool)

enum AccessFrom { NONE, MENU, BATTLE, PARTY, INVENTORY, STORE }

const DEFAULT_DELAY: float = 1.0
const GAME_WIDTH := 1280
const GAME_HEIGHT := 720
@warning_ignore_restore("unused_signal")
