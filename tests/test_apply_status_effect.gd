extends GutTest

var shown_text: Array[Array] = []

func before_each() -> void:
	shown_text.clear()
	if not Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.disconnect(_on_send_text_box)


func test_apply_status_effect_applies_when_chance_is_one() -> void:
	var effect := ApplyStatusEffect.new()
	var status := StatusData.new()
	status.status_id = "unit_status"
	status.status_name = "UnitStatus"
	effect.status_data = status
	effect.application_chance = 1.0
	var target := _make_monster("Target")
	var context := _make_context()

	await effect.apply(_make_monster("Actor"), target, context)

	assert_true(target.has_status_id("unit_status"))
	assert_eq(shown_text.size(), 1)


func test_apply_status_effect_does_not_apply_when_chance_is_zero() -> void:
	var effect := ApplyStatusEffect.new()
	var status := StatusData.new()
	status.status_id = "never_status"
	status.status_name = "NeverStatus"
	effect.status_data = status
	effect.application_chance = 0.0
	var target := _make_monster("Target")
	var context := _make_context()

	await effect.apply(_make_monster("Actor"), target, context)

	assert_false(target.has_status_id("never_status"))
	assert_eq(shown_text.size(), 0)


func test_apply_status_effect_respects_slot_conflicts() -> void:
	var effect := ApplyStatusEffect.new()
	var status_one := StatusData.new()
	status_one.status_id = "main_one"
	status_one.status_name = "MainOne"
	status_one.status_slot = StatusData.StatusSlot.MAIN
	var status_two := StatusData.new()
	status_two.status_id = "main_two"
	status_two.status_name = "MainTwo"
	status_two.status_slot = StatusData.StatusSlot.MAIN
	var target := _make_monster("Target")
	var context := _make_context()
	await target.add_status(status_one)

	effect.status_data = status_two
	effect.application_chance = 1.0
	await effect.apply(_make_monster("Actor"), target, context)

	assert_true(target.has_status_id("main_one"))
	assert_false(target.has_status_id("main_two"))
	assert_eq(shown_text[-1], ["But it failed!"])


func _on_send_text_box(
	_object: Node,
	text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	shown_text.append(text.duplicate())
	Global.text_box_complete.emit()


func _make_context() -> BattleContext:
	return BattleContext.new(Node.new(), Control.new())


func _make_monster(monster_name: String) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.level = 10
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 20
	monster.defense = 20
	monster.special_attack = 20
	monster.special_defense = 20
	monster.speed = 20
	monster.max_hitpoints = 80
	monster.current_hitpoints = 80
	monster.create_stat_multis()
	return monster
