class_name ProgressBlockerObject
extends CellObject

enum Permanence { IMPERMANENT, PERMANENT }
enum RemovalType { NONE, CUT, SMASH }

static var prompted_once: bool = false

@export var permanence: Permanence = Permanence.IMPERMANENT
@export var removal_type: RemovalType = RemovalType.NONE
@export_subgroup("Text")
@export_multiline() var requirement_text: Array[String] = ["You don't have the requirements to pass."]
@export_multiline() var question_text: Array[String] = ["Would you like to destroy it?"]


func _ready() -> void:
	super()
	_blocks_player = true
	_is_active = true
	_masks_player = false
	add_to_group("save_object")


func interact(player: Player3D) -> void:
	if not _has_requirement():
		Ui.send_text_box.emit(null, requirement_text, true, false, false)
		await Ui.text_box_complete
		return
	else:
		if not prompted_once:
			Ui.send_text_box.emit(null, question_text, false, true, false)
			var answer = await Ui.answer_given
			if answer:
				prompted_once = true
			else:
				return

	super(player)

	deactivate()


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			match permanence:
				Permanence.IMPERMANENT:
					pass
				Permanence.PERMANENT:
					_is_active = data.is_active
					_blocks_player = data.blocks_player
					_masks_player = data.masks_player
					visible = data.is_visible

	_update()


func _has_requirement() -> bool:
	return removal_type in FieldCapability.get_available_removal_methods()
