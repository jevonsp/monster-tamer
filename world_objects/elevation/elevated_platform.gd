extends Node2D

@onready var left_rail: StaticBody2D = $LeftRail
@onready var right_rail: StaticBody2D = $RightRail
@onready var elevated_area: Area2D = $ElevatedArea


func _on_player_height_level_changed(height_level: int) -> void:
	match height_level:
		0:
			left_rail.process_mode = Node.PROCESS_MODE_DISABLED
			right_rail.process_mode = Node.PROCESS_MODE_DISABLED
		1:
			left_rail.process_mode = Node.PROCESS_MODE_INHERIT
			right_rail.process_mode = Node.PROCESS_MODE_INHERIT
