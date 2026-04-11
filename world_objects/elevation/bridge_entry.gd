@tool
extends Node2D

const TILE_SIZE: float = TileMover.TILE_SIZE

@export var bridge_width_in_tiles: int = 1:
	set(value):
		bridge_width_in_tiles = value
		if not is_node_ready():
			return
		if Engine.is_editor_hint():
			_update_bridge_width()
			_update_stair_width()

@onready var right_rail: StaticBody2D = $ElevatedPlatform/RightRail
@onready var ele_changer_coll_shape: CollisionShape2D = $ElevationChanger/CollisionShape2D


func _ready() -> void:
	_ensure_unique_stair_shape()
	if Engine.is_editor_hint():
		_update_bridge_width()
		_update_stair_width()
		return
	if visible:
		visible = false


func _update_bridge_width() -> void:
	const BASE_DIST: int = 2
	const START = TILE_SIZE * BASE_DIST
	var target_pos = START + ((bridge_width_in_tiles - 1) * TILE_SIZE)

	right_rail.position.x = target_pos


func _update_stair_width() -> void:
	const BASE_WIDTH := TILE_SIZE - 1
	const BASE_X_POS := TILE_SIZE / 2
	var target_width = BASE_WIDTH + ((bridge_width_in_tiles - 1) * TILE_SIZE)
	var target_position = BASE_X_POS + (BASE_X_POS * (bridge_width_in_tiles - 1))
	var shape := ele_changer_coll_shape.shape as RectangleShape2D
	if shape == null:
		return
	ele_changer_coll_shape.position.x = target_position
	shape.size.x = target_width


func _ensure_unique_stair_shape() -> void:
	var shape := ele_changer_coll_shape.shape
	if shape == null:
		return
	if shape.resource_local_to_scene:
		return
	var unique_shape := shape.duplicate()
	unique_shape.resource_local_to_scene = true
	ele_changer_coll_shape.shape = unique_shape
