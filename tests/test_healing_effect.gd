extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")


func before_each() -> void:
	if not Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.connect(_on_send_hitpoints_change)
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.disconnect(_on_send_hitpoints_change)
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)
	super.after_each()


func test_healing_effect_use_fails_when_target_is_full_health() -> void:
	var effect := HealingEffect.new()
	effect.base_healing = 20
	var target := TH.make_monster("HealMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 100)
	target.current_hitpoints = target.max_hitpoints

	await effect.use(target)

	assert_eq(target.current_hitpoints, target.max_hitpoints)


func test_healing_effect_use_revives_and_heals() -> void:
	var effect := HealingEffect.new()
	effect.base_healing = 20
	effect.revives = true
	var target := TH.make_monster("HealMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 100)
	target.current_hitpoints = 0
	target.is_fainted = true

	await effect.use(target)

	assert_true(target.current_hitpoints > 0)
	assert_false(target.is_fainted)


func _on_send_hitpoints_change(_target: Monster, _hp: int) -> void:
	call_deferred("_emit_hitpoints_animation_complete")


func _on_send_text_box(
	_object,
	_text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	call_deferred("_emit_text_box_complete")


func _emit_hitpoints_animation_complete() -> void:
	Battle.hitpoints_animation_complete.emit()


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()
