class_name RemoveBlockerObject
extends BlockerObject

enum Permanence { IMPERMANENT, PERMANENT }
enum RemovalType { NONE, CUT, SMASH }

@export var permanence: Permanence = Permanence.IMPERMANENT
@export var removal_type: RemovalType = RemovalType.NONE


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
	if answer:
		match removal_type:
			RemovalType.NONE:
				pass
			RemovalType.CUT:
				toggle_mode(State.PASSABLE)
			RemovalType.SMASH:
				pass


func toggle_mode(new_state: State) -> void:
	state = new_state

	match state:
		State.NOT_PASSABLE:
			collision_shape_2d.disabled = false
			visible = true
		State.PASSABLE:
			collision_shape_2d.disabled = true
			visible = false


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()

	new_saved_data.node_path = get_path()
	new_saved_data.state = state as int

	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			state = data.state as State
			match permanence:
				Permanence.IMPERMANENT:
					toggle_mode(State.NOT_PASSABLE)
