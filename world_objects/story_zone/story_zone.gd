extends Area2D

var story_component: StoryComponent


func _ready() -> void:
	_set_story_component()


func _set_story_component() -> void:
	for child in get_children():
		if child is StoryComponent:
			story_component = child
			break


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_trigger()


func _trigger() -> void:
	if story_component:
		await Global.step_completed
		story_component.trigger()
