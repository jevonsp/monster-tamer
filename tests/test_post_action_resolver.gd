extends "res://tests/monster_tamer_test.gd"

const PostActionResolverScript := preload("res://battle/post_action_resolver.gd")
const TH := preload("res://tests/monster_factory.gd")


class FakeForcedSwitchHandler:
	extends Node
	var enemy_switch_called: bool = false
	var player_switch_called: bool = false

	func force_enemy_send_new_monster(_handler: Node) -> void:
		enemy_switch_called = true

	func force_player_send_new_monster(_handler: Node) -> void:
		player_switch_called = true


class FakeBattle:
	extends Control
	var player_actor: Monster
	var enemy_actor: Monster
	var player_party: Array[Monster] = []
	var enemy_party: Array[Monster] = []
	var enemy_trainer = null
	var ended: bool = false

	func end_battle() -> void:
		ended = true


class FakeHandler:
	extends Node
	var is_escaped: bool = false


var _battle: FakeBattle
var _resolver: Node
var _handler: FakeHandler
var _forced_switch: FakeForcedSwitchHandler


func before_each() -> void:
	_battle = FakeBattle.new()
	_battle.name = "Battle"
	_forced_switch = FakeForcedSwitchHandler.new()
	_forced_switch.name = "ForcedSwitchHandler"
	_battle.add_child(_forced_switch)
	_resolver = PostActionResolverScript.new()
	_resolver.name = "PostActionResolver"
	_battle.add_child(_resolver)
	_handler = FakeHandler.new()
	add_child_autoqfree(_battle)
	autofree(_handler)
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)
	if not Battle.send_monster_death_experience.is_connected(_on_send_monster_death_experience):
		Battle.send_monster_death_experience.connect(_on_send_monster_death_experience)


func after_each() -> void:
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)
	if Battle.send_monster_death_experience.is_connected(_on_send_monster_death_experience):
		Battle.send_monster_death_experience.disconnect(_on_send_monster_death_experience)
	if is_instance_valid(_battle):
		_battle.free()
	_battle = null
	_resolver = null
	_handler = null
	_forced_switch = null
	super.after_each()


func test_escape_ends_battle_immediately() -> void:
	_handler.is_escaped = true
	var target := TH.make_monster("Enemy", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)

	var ended: bool = await _resolver.handle_post_action(target, _handler)

	assert_true(ended)
	assert_true(_battle.ended)


func test_capture_ends_battle() -> void:
	_battle.player_actor = TH.make_monster("Player", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30, -1, true)
	_battle.enemy_actor = TH.make_monster("Enemy", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)
	_battle.enemy_actor.is_captured = true

	var ended: bool = await _resolver.handle_post_action(_battle.enemy_actor, _handler)

	assert_true(ended)
	assert_true(_battle.ended)


func test_enemy_forced_switch_when_enemy_fainted_but_party_has_backup() -> void:
	_battle.player_actor = TH.make_monster("Player", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30, -1, true)
	_battle.enemy_actor = TH.make_monster("Enemy", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)
	_battle.enemy_actor.is_fainted = true
	var backup := TH.make_monster("Backup", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)
	_battle.enemy_party = [_battle.enemy_actor, backup]

	var ended: bool = await _resolver.handle_post_action(_battle.enemy_actor, _handler)

	assert_false(ended)
	assert_false(_battle.ended)
	assert_true(_forced_switch.enemy_switch_called)


func test_player_forced_switch_when_player_fainted_but_party_has_backup() -> void:
	_battle.player_actor = TH.make_monster("Player", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30, -1, true)
	_battle.player_actor.is_fainted = true
	_battle.enemy_actor = TH.make_monster("Enemy", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)
	_battle.player_party = [_battle.player_actor, TH.make_monster("Backup", 8, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30, -1, true)]

	var ended: bool = await _resolver.handle_post_action(_battle.player_actor, _handler)

	assert_false(ended)
	assert_false(_battle.ended)
	assert_true(_forced_switch.player_switch_called)


func _on_send_text_box(
	_object,
	_text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	call_deferred("_emit_text_box_complete")


func _on_send_monster_death_experience(_amount: int) -> void:
	call_deferred("_emit_player_done_giving_exp")


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()


func _emit_player_done_giving_exp() -> void:
	Battle.player_done_giving_exp.emit()
