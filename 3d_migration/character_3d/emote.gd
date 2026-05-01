class_name Emote
extends AnimatedSprite3D

signal emote_finished

enum Type { EXCLAIM, QUESTION, HEART, SMILE }

const LOW_POS := 0.06
const HIGH_POS := 0.18
const RISE_TIME := 0.9
const WIGGLE_TIME := 1.0

var _active_tween: Tween
var _wiggle_tween: Tween
var _can_cancel: bool = false


func _ready() -> void:
	position.y = LOW_POS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _can_cancel:
		return
	if event.is_action_pressed("yes"):
		_finish_emote()
	elif event.is_action_pressed("no"):
		_finish_emote()


func play_emote(emote_name: StringName, autocomplete: bool = true) -> void:
	_kill_tween()
	stop()
	position.y = LOW_POS
	visible = true
	_can_cancel = false

	_active_tween = create_tween()
	_active_tween.tween_property(self, "position:y", HIGH_POS, RISE_TIME)

	animation = &"bubble"
	frame = 0
	play(&"bubble")
	var duration := 9.0 / sprite_frames.get_animation_speed(&"bubble")
	await get_tree().create_timer(duration).timeout

	animation = emote_name
	frame = 0
	play(emote_name)
	stop()
	_can_cancel = true
	if autocomplete:
		wiggle()
		await get_tree().create_timer(WIGGLE_TIME).timeout
		_finish_emote()
	else:
		wiggle()


func wiggle(amplitude: float = 0.02, step_time: float = 0.25) -> void:
	if _wiggle_tween and _wiggle_tween.is_valid():
		_wiggle_tween.kill()
	var base_y := position.y
	_wiggle_tween = create_tween().set_loops()
	_wiggle_tween.tween_property(self, "position:y", base_y + amplitude, step_time)
	_wiggle_tween.tween_property(self, "position:y", base_y - amplitude, step_time)
	_wiggle_tween.tween_property(self, "position:y", base_y, step_time)


func stop_wiggle() -> void:
	if _wiggle_tween and _wiggle_tween.is_valid():
		_wiggle_tween.kill()


func _finish_emote() -> void:
	if _wiggle_tween and _wiggle_tween.is_valid():
		_wiggle_tween.kill()
	visible = false
	_can_cancel = false
	emote_finished.emit()


func _kill_tween() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()


func _play_bubble_then(emote_name: StringName) -> void:
	animation = &"bubble"
	frame = 0
	play(&"bubble")
	var duration := 9.0 / sprite_frames.get_animation_speed(&"bubble")
	await get_tree().create_timer(duration).timeout
	animation = emote_name
	stop()
