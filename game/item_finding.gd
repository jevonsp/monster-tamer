class_name ItemFinding
extends RefCounted

const BASE_BALL = preload("uid://dpiumhuub3udr")


func get_chance_for_route() -> float:
	return 0.05


func get_item_for_route() -> Item:
	var item = BASE_BALL.duplicate()
	return item
