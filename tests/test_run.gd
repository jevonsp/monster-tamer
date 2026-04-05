extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")


class FakeAnimationPlayer:
	extends Node
	var switch_out_calls: int = 0

	func play_monster_switch_out(_actor: Monster) -> void:
		switch_out_calls += 1


class FakeVisibilityFocusHandler:
	extends Node
	var animation_player := FakeAnimationPlayer.new()

	func _init() -> void:
		add_child(animation_player)


class FakeTurnExecutor:
	extends Node
	var run_count: int = 0


class FakeBattle:
	extends Control
	var turn_executor := FakeTurnExecutor.new()
	var visibility_focus_handler := FakeVisibilityFocusHandler.new()

	func _init() -> void:
		add_child(turn_executor)
		add_child(visibility_focus_handler)


class FakeHandler:
	extends Node
	var is_escaped: bool = false


var shown: Array[String] = []
var _cleanup_nodes: Array[Node] = []


func before_each() -> void:
	shown.clear()
	_cleanup_nodes.clear()
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)
	for node in _cleanup_nodes:
		if is_instance_valid(node):
			node.free()
	_cleanup_nodes.clear()
	super.after_each()


func test_run_fails_when_escape_odds_are_zero() -> void:
	var action := Run.new()
	var actor := TH.make_monster("Slow", 5, TypeChart.Type.NONE, null, 10, 10, 10, 10, 0, 20)
	var target := TH.make_monster("Fast", 5, TypeChart.Type.NONE, null, 10, 10, 10, 10, 100, 20)
	var battle := FakeBattle.new()
	var handler := FakeHandler.new()
	_cleanup_nodes.append(battle)
	_cleanup_nodes.append(handler)
	var context := BattleContext.new(handler, battle)
	battle.turn_executor.run_count = 0

	await action.execute(actor, target, context)

	assert_false(handler.is_escaped)
	assert_eq(battle.visibility_focus_handler.animation_player.switch_out_calls, 0)


func test_run_succeeds_when_escape_odds_are_well_above_roll_cap() -> void:
	var action := Run.new()
	var actor := TH.make_monster("Fast", 5, TypeChart.Type.NONE, null, 10, 10, 10, 10, 300, 20)
	var target := TH.make_monster("Slow", 5, TypeChart.Type.NONE, null, 10, 10, 10, 10, 1, 20)
	var battle := FakeBattle.new()
	var handler := FakeHandler.new()
	_cleanup_nodes.append(battle)
	_cleanup_nodes.append(handler)
	var context := BattleContext.new(handler, battle)
	battle.turn_executor.run_count = 10

	await action.execute(actor, target, context)

	assert_true(handler.is_escaped)
	assert_eq(battle.visibility_focus_handler.animation_player.switch_out_calls, 1)


func _on_send_text_box(
	_object,
	text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	shown.append_array(text)
	call_deferred("_emit_text_box_complete")


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()
