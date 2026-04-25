@tool
class_name ProgressBlockerObject
extends CellObject

static var prompted_once: bool = false

@export var flag_requirement: Story.Flag = Story.Flag.BADGE_ONE
@export_multiline() var requirement_text: Array[String] = ["You don't have the requirements to pass."]

@onready var sprite_3d: Sprite3D = $Sprite3D


func _ready() -> void:
	super()
	_blocks_player = true
	_is_active = true
	_masks_player = false


func interact(player: Player3D) -> void:
	if not _has_requirment():
		Ui.send_text_box.emit(null, requirement_text, true, false, false)
		await Ui.text_box_complete
		return
	else:
		if not prompted_once:
			Ui.send_text_box.emit(null, ["Would you like to destroy it?"], false, true, false)
			var answer = await Ui.answer_given
			if answer:
				prompted_once = true
			else:
				return
	super(player)
	_deactivate()


func _has_requirment() -> bool:
	return PlayerContext3D.player.story_flag_handler.story_flags[flag_requirement]


func _deactivate() -> void:
	pass
