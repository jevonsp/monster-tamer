class_name RemoveBlockerObject
extends BlockerObject

enum Permanence { IMPERMANENT, PERMANENT }
enum RemovalType { NONE, CUT, SMASH }

@export var permanence: Permanence = Permanence.IMPERMANENT
@export var removal_type: RemovalType = RemovalType.NONE
@export var removal_animation_blink_segments: int = 8
@export var removal_animation_start_duration: float = 0.1
@export_range(0.2, 0.95, 0.01) var removal_animation_speedup: float = 0.55

var _active_removal_tween: Tween


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
			toggle_mode(State.PASSABLE)
		RemovalType.CUT:
			await _animate_removal()
			toggle_mode(State.PASSABLE)
		RemovalType.SMASH:
			await _animate_removal()
			toggle_mode(State.PASSABLE)


func toggle_mode(new_state: State) -> void:
	state = new_state
	match state:
		State.NOT_PASSABLE:
			if _active_removal_tween != null and is_instance_valid(_active_removal_tween):
				_active_removal_tween.kill()
				_active_removal_tween = null
			modulate = Color.WHITE
			collision_shape_2d.disabled = false
			visible = true
		State.PASSABLE:
			if _active_removal_tween != null and is_instance_valid(_active_removal_tween):
				_active_removal_tween.kill()
				_active_removal_tween = null
			modulate = Color.WHITE
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


func _animate_removal() -> void:
	var duration: float = removal_animation_start_duration
	var target: CanvasItem = self
	target.modulate = Color.TRANSPARENT
	var count := 0
	while count < removal_animation_blink_segments:
		var toward_visible: bool = count % 2 == 0
		var end_color: Color = Color.WHITE if toward_visible else Color.TRANSPARENT
		var tween := create_tween()
		_active_removal_tween = tween
		tween.tween_property(target, "modulate", end_color, maxf(duration, 0.02)).set_trans(
			Tween.TRANS_LINEAR,
		)
		await tween.finished
		_active_removal_tween = null
		count += 1
		duration *= removal_animation_speedup
