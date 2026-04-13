class_name GrassTile
extends EncounterZone


func _ready() -> void:
	super()
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	for body in get_overlapping_bodies():
		if body is Player:
			_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).grass_overlap_enter()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).grass_overlap_exit()
