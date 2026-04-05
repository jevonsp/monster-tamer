extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")

var shown: Array[Array] = []
var _context_nodes: Array[Node] = []


func before_each() -> void:
	shown.clear()
	_context_nodes.clear()
	if not Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.connect(_on_send_hitpoints_change)
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.disconnect(_on_send_hitpoints_change)
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)
	TH.free_if_valid(_context_nodes)
	_context_nodes.clear()
	super.after_each()


func test_dot_status_uses_percent_damage_with_minimum_one() -> void:
	var status := DoTStatus.new()
	status.status_name = "Poison"
	status.is_flat_damage = false
	status.percent_damage_per_turn = 1 / 8.0
	var target := TH.make_monster("DotMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 5, 5)
	var ctx_pack := TH.make_battle_context()
	var context: BattleContext = ctx_pack[0]
	_context_nodes.append_array(ctx_pack[1])

	await status.on_turn_end(StatusInstance.new(status, target, 3), target, context)

	assert_eq(target.current_hitpoints, 4)
	assert_eq(shown[0], ["DotMon was hurt by it's Poison."])


func test_dot_status_uses_flat_damage_when_enabled() -> void:
	var status := DoTStatus.new()
	status.status_name = "Burn"
	status.is_flat_damage = true
	status.flat_damage_per_turn = 3
	var target := TH.make_monster("DotMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 20, 20)
	var ctx_pack := TH.make_battle_context()
	var context: BattleContext = ctx_pack[0]
	_context_nodes.append_array(ctx_pack[1])

	await status.on_turn_end(StatusInstance.new(status, target, 3), target, context)

	assert_eq(target.current_hitpoints, 17)


func _on_send_hitpoints_change(_target: Monster, _hp: int) -> void:
	call_deferred("_emit_hitpoints_animation_complete")


func _on_send_text_box(
		_object,
		text: Array[String],
		_auto_complete: bool,
		_is_question: bool,
		_toggles_player: bool,
) -> void:
	shown.append(text.duplicate())
	call_deferred("_emit_text_box_complete")


func _emit_hitpoints_animation_complete() -> void:
	Battle.hitpoints_animation_complete.emit()


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()
