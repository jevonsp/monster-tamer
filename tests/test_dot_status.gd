extends GutTest

var shown: Array[Array] = []


func before_each() -> void:
	shown.clear()
	if not Global.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Global.send_hitpoints_change.connect(_on_send_hitpoints_change)
	if not Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Global.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Global.send_hitpoints_change.disconnect(_on_send_hitpoints_change)
	if Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.disconnect(_on_send_text_box)


func test_dot_status_uses_percent_damage_with_minimum_one() -> void:
	var status := DoTStatus.new()
	status.status_name = "Poison"
	status.is_flat_damage = false
	status.percent_damage_per_turn = 1 / 8.0
	var target := _make_monster(5, 5)
	var context := _make_context()

	await status.on_turn_end(StatusInstance.new(status, target, 3), target, context)

	assert_eq(target.current_hitpoints, 4)
	assert_eq(shown[0], ["DotMon was hurt by it's Poison."])


func test_dot_status_uses_flat_damage_when_enabled() -> void:
	var status := DoTStatus.new()
	status.status_name = "Burn"
	status.is_flat_damage = true
	status.flat_damage_per_turn = 3
	var target := _make_monster(20, 20)

	await status.on_turn_end(StatusInstance.new(status, target, 3), target, _make_context())

	assert_eq(target.current_hitpoints, 17)


func _on_send_hitpoints_change(_target: Monster, _hp: int) -> void:
	Global.hitpoints_animation_complete.emit()


func _on_send_text_box(
		_object: Node,
		text: Array[String],
		_auto_complete: bool,
		_is_question: bool,
		_toggles_player: bool,
) -> void:
	shown.append(text.duplicate())
	Global.text_box_complete.emit()


func _make_context() -> BattleContext:
	return BattleContext.new(Node.new(), Control.new())


func _make_monster(max_hp: int, current_hp: int) -> Monster:
	var monster := Monster.new()
	monster.name = "DotMon"
	monster.primary_type = TypeChart.Type.NONE
	monster.max_hitpoints = max_hp
	monster.current_hitpoints = current_hp
	monster.attack = 10
	monster.defense = 10
	monster.special_attack = 10
	monster.special_defense = 10
	monster.speed = 10
	monster.create_stat_multis()
	return monster
