extends Node

@export var story_flags: Dictionary[Story.Flag, bool] = {
	Story.Flag.TUTORIAL_FINISHED: false,
	Story.Flag.BADGE_ONE: false,
	Story.Flag.BADGE_TWO: false,
	Story.Flag.BADGE_THREE: false,
	Story.Flag.BADGE_FOUR: false,
	Story.Flag.BADGE_FIVE: false,
	Story.Flag.BADGE_SIX: false,
	Story.Flag.BADGE_SEVEN: false,
	Story.Flag.BADGE_EIGHT: false,
}

func _ready() -> void:
	Global.story_flag_triggered.connect(_on_story_flag_triggered)


func _on_story_flag_triggered(flag: Story.Flag, value: bool) -> void:
	story_flags[flag] = value
