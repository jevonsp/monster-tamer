extends Node

const BASE_BALL = preload("uid://bxx0p3qhlq7yk")


func get_chance_for_route() -> float:
	return 0.05


func get_item_for_route() -> Item:
	var item = BASE_BALL.duplicate()
	return item
