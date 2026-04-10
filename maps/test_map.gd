extends TileMapLayer

## Deck-only TileMapLayer: set TRUE so Global.bridge_map is set (required for height on bridge tiles).
## Ground + stairs layer: leave FALSE so Global.ground_map / world_map are set.
## TileSet custom data: "is_elevated" on stairs and bridge *deck* tiles (bridge layer).
## "under_bridge_deck" on *ground* tiles where the path runs under overlay art (same grid as deck).
## Bridge layer height uses only is_elevated (not "any cell painted") so underpasses are not forced to band 1.
@export var register_as_bridge_overlay: bool = false


func _ready() -> void:
	if register_as_bridge_overlay:
		Global.bridge_map = self
		FieldMaps.bridge = self
	else:
		Global.ground_map = self
		Global.world_map = self
		FieldMaps.ground = self
	Global.maps[z_index] = self
