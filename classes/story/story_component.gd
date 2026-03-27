class_name StoryComponent
extends Node

@export var story_flag: Story.Flag = Story.Flag.NONE
@export var value: bool = true


func trigger() -> void:
	assert(story_flag != Story.Flag.NONE)
	Global.story_flag_triggered.emit(story_flag, value)
