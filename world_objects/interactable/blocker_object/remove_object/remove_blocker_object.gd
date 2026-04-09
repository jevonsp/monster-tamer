class_name RemoveBlockerObject
extends BlockerObject

enum Permanence { IMPERMANENT, PERMANENT }
enum RemovalType { NONE, CUT, SMASH }

@export var permanence: Permanence = Permanence.IMPERMANENT
@export var removal_type: RemovalType = RemovalType.NONE


func _ready() -> void:
	toggle_mode(state)


func interact(body: Player) -> void:
	var ta: Array[String]
	if removal_type not in body.travel.get_available_removal_methods():
		ta = [cant_interact_text]
		Ui.send_text_box.emit(null, ta, false, false, true)
		await Ui.text_box_complete
		return

	ta = [question_interact_text]
	Ui.send_text_box.emit(self, ta, false, true, false)
	var answer = await Ui.answer_given
	await Ui.text_box_complete
	if not answer:
		return

	match removal_type:
		RemovalType.NONE:
			pass
		RemovalType.CUT, RemovalType.SMASH:
			toggle_mode(State.PASSABLE)


func toggle_mode(new_state: State) -> void:
	state = new_state
	match state:
		State.NOT_PASSABLE:
			collision_shape_2d.disabled = false
			visible = true
		State.PASSABLE:
			collision_shape_2d.disabled = true
			visible = false


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			match permanence:
				Permanence.PERMANENT:
					toggle_mode(data.state as State)
				Permanence.IMPERMANENT:
					toggle_mode(State.NOT_PASSABLE)
