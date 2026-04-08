extends Control

signal crossfade_segment_completed

var processing: bool = false
var is_animating: bool = false
var ta: Array[String] = []
var old_species_name: String
var new_species_name: String
var _cancelled: bool = false
var _active_tween: Tween

@onready var old_texture_rect: TextureRect = $OldTextureRect
@onready var new_texture_rect: TextureRect = $NewTextureRect


func _ready() -> void:
	_connect_signals()


func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("yes"):
		if not is_animating:
			return
		_finish_evolution(new_species_name)
	if event.is_action_pressed("no"):
		if not is_animating:
			return
		_cancel_evolution(old_species_name)


func clean_up() -> void:
	old_species_name = ""
	new_species_name = ""
	_cancelled = false


func _connect_signals() -> void:
	EvolutionHandler.evolution_screen_requested.connect(_start_evolution_process)


func _start_evolution_process(monster: Monster, entry: Entry) -> void:
	old_species_name = monster.monster_data.species
	new_species_name = entry.finish_monster.species
	ta = ["What...? Your %s is evolving!" % [old_species_name]]
	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	_cancelled = false
	_set_up_screen(monster, entry)
	_toggle_visible()
	await _animate_evolution()

	if not _cancelled:
		await _finish_evolution(new_species_name)


func _finish_evolution(n: String) -> void:
	EvolutionHandler.evolution_result.emit(EvolutionHandler.Result.COMPLETE)

	processing = false
	ta = ["Congratulations~\nYour %s evolved into a %s!" % [old_species_name, n]]

	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	visible = false
	EvolutionHandler.finish_evolve()

	clean_up()


func _cancel_evolution(n: String) -> void:
	_cancelled = true
	EvolutionHandler.evolution_result.emit(EvolutionHandler.Result.CANCEL)
	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()
		_active_tween = null
	crossfade_segment_completed.emit()

	old_texture_rect.modulate = Color.WHITE
	new_texture_rect.modulate = Color.TRANSPARENT

	processing = false
	ta = ["Your %s did not evolve." % [n]]

	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	visible = false
	EvolutionHandler.finish_evolve()

	clean_up()


func _toggle_visible() -> void:
	visible = not visible
	processing = visible


func _set_up_screen(monster: Monster, entry: Entry) -> void:
	old_texture_rect.texture = monster.monster_data.texture
	new_texture_rect.texture = entry.finish_monster.texture

	new_texture_rect.modulate = Color.TRANSPARENT


func _animate_evolution() -> void:
	is_animating = true

	var time := 1.5
	var count := 0

	while count < 15:
		if _cancelled:
			break
		var is_toward_new := count % 2 == 0
		await _crossfade(is_toward_new, time)
		if _cancelled:
			break
		count += 1
		time *= .75

	is_animating = false


func _crossfade(show_new_monster: bool, duration: float) -> void:
	if _cancelled:
		return
	var old_target := Color.TRANSPARENT if show_new_monster else Color.WHITE
	var new_target := Color.WHITE if show_new_monster else Color.TRANSPARENT
	var tween = get_tree().create_tween()
	_active_tween = tween
	tween.tween_property(old_texture_rect, "modulate", old_target, duration).set_trans(
		Tween.TRANS_SINE,
	).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(new_texture_rect, "modulate", new_target, duration).set_trans(
		Tween.TRANS_SINE,
	).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_crossfade_tween_finished, CONNECT_ONE_SHOT)
	await crossfade_segment_completed
	_active_tween = null


func _on_crossfade_tween_finished() -> void:
	if not _cancelled:
		crossfade_segment_completed.emit()
