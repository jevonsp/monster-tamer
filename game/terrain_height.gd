class_name TerrainHeight


static func _ground() -> TileMapLayer:
	if FieldMaps.ground != null:
		return FieldMaps.ground
	return Global.ground_map


static func _bridge() -> TileMapLayer:
	if FieldMaps.bridge != null:
		return FieldMaps.bridge
	return Global.bridge_map


## World-space feet position → discrete band (0 = ground, 1 = elevated / bridge deck).
static func resolve(feet_global: Vector2) -> int:
	var want_height: int = 0
	var g: TileMapLayer = _ground()
	var ground_cell: Vector2i = Vector2i.ZERO
	var suppress_bridge_overlay: bool = false
	if g != null:
		ground_cell = g.local_to_map(g.to_local(feet_global))
		if TileChecker.terrain_height_level(ground_cell, g) == 1:
			want_height = 1
		suppress_bridge_overlay = TileChecker.is_under_bridge_deck(ground_cell, g)
	var b: TileMapLayer = _bridge()
	if b != null and not suppress_bridge_overlay:
		var bridge_cell: Vector2i = b.local_to_map(b.to_local(feet_global))
		# Only `is_elevated` on the bridge layer counts. Any-painted-cell was wrong for underpasses that share
		# the same grid as deck overlay art (feet map to a bridge tile while walking the tunnel).
		if TileChecker.terrain_height_level(bridge_cell, b) == 1:
			want_height = 1
	return want_height


## Ground and bridge cells under `feet_global` for debug / tooling.
static func cells_under_feet(feet_global: Vector2) -> Dictionary:
	var out: Dictionary = {}
	var g: TileMapLayer = _ground()
	if g != null:
		out["ground_cell"] = g.local_to_map(g.to_local(feet_global))
	else:
		out["ground_cell"] = Vector2i.ZERO
	var b: TileMapLayer = _bridge()
	if b != null:
		out["bridge_cell"] = b.local_to_map(b.to_local(feet_global))
	else:
		out["bridge_cell"] = Vector2i.ZERO
	return out
