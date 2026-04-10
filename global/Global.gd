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
## Ground layer: collision, stairs (`is_elevated`), water checks, etc.
var ground_map: TileMapLayer
## Optional overlay: bridge deck only (no ground). Any cell with a tile counts as elevated.
var bridge_map: TileMapLayer
## Same as ground_map; kept for older references.
var world_map: TileMapLayer
var maps: Dictionary[int, TileMapLayer] = { }
