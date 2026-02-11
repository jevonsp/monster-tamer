extends Node2D

func _ready() -> void:
	Global.send_move_animation.connect(_on_move_animation_recieved)


func _on_move_animation_recieved(scene: PackedScene) -> void:
	print_debug("Move Animation Recieved")
	var animation = scene.instantiate()
	add_child(animation)
