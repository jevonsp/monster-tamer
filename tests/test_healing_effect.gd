extends GutTest


func before_each() -> void:
	if not Global.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Global.send_hitpoints_change.connect(_on_send_hitpoints_change)
	if not Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Global.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Global.send_hitpoints_change.disconnect(_on_send_hitpoints_change)
	if Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.disconnect(_on_send_text_box)


func test_healing_effect_use_fails_when_target_is_full_health() -> void:
	var effect := HealingEffect.new()
	effect.base_healing = 20
	var target := _make_monster()
	target.current_hitpoints = target.max_hitpoints

	await effect.use(target)

	assert_eq(target.current_hitpoints, target.max_hitpoints)


func test_healing_effect_use_revives_and_heals() -> void:
	var effect := HealingEffect.new()
	effect.base_healing = 20
	effect.revives = true
	var target := _make_monster()
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
	Global.hitpoints_animation_complete.emit()


func _emit_text_box_complete() -> void:
	Global.text_box_complete.emit()


func _make_monster() -> Monster:
	var monster := Monster.new()
	monster.name = "HealMon"
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 10
	monster.defense = 10
	monster.special_attack = 10
	monster.special_defense = 10
	monster.speed = 10
	monster.max_hitpoints = 100
	monster.current_hitpoints = 100
	monster.create_stat_multis()
	return monster
