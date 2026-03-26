@tool
class_name ShopKeeper
extends NPC


func interact(_body: CharacterBody2D) -> void:
	await _say_dialogue()
