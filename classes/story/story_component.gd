class_name StoryComponent
extends Node

@export var story_flag: Story.Flag = Story.Flag.NONE
@export var value: bool = true


func trigger() -> void:
	if story_flag == Story.Flag.NONE:
		printerr("NO FLAG ASSIGNED TO %s at %s" % self, get_path())
		return

	Global.story_flag_triggered.emit(story_flag, value)
