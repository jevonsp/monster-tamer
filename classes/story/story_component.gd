class_name StoryComponent extends Node

@export var story_flag: Story.Flag = Story.Flag.NONE
@export var value: bool = false

func trigger() -> void:
	Global.story_flag_triggered.emit(story_flag, value)
