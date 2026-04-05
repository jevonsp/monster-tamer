extends "res://tests/monster_tamer_test.gd"

const PostActionResolverScript := preload("res://battle/post_action_resolver.gd")
const TurnExecutorScript := preload("res://battle/turn_executor.gd")
const TH := preload("res://tests/monster_factory.gd")

var battle: FakeBattle
var turn_executor: Node
var post_action_resolver: Node
var handler: FakeHandler


func before_each() -> void:
	battle = FakeBattle.new()
	battle.name = "Battle"

	var forced_switch_handler := Node.new()
	forced_switch_handler.name = "ForcedSwitchHandler"
	battle.add_child(forced_switch_handler)

	post_action_resolver = PostActionResolverScript.new()
	post_action_resolver.name = "PostActionResolver"
	battle.add_child(post_action_resolver)

	turn_executor = TurnExecutorScript.new()
	turn_executor.name = "TurnExecutor"
	battle.add_child(turn_executor)

	handler = FakeHandler.new()
	add_child_autoqfree(battle)
	autofree(handler)


func after_each() -> void:
	if is_instance_valid(battle):
		battle.free()
	battle = null
	turn_executor = null
	post_action_resolver = null
	handler = null
	super.after_each()


func test_successful_capture_ends_battle_before_turn_reset_flow() -> void:
	var player := TH.make_monster("PlayerMon", 5, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 20, -1, true)
	var enemy := TH.make_monster("WildMon", 5, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 20)
	battle.player_actor = player
	battle.enemy_actor = enemy
	battle.player_party = [player]
	battle.enemy_party = [enemy]

	await get_tree().process_frame

	var turn_queue: Array[Dictionary] = [
		{
			"action": CaptureAction.new(),
			"actor": player,
			"target": enemy,
		},
	]

	var battle_ended: bool = await turn_executor.execute_turn_queue(
		handler,
		turn_queue,
		post_action_resolver,
	)

	assert_true(battle_ended)
	assert_true(battle.ended)
	assert_true(enemy.is_captured)


class FakeBattle:
	extends Control

	var player_actor: Monster
	var enemy_actor: Monster
	var player_party: Array[Monster] = []
	var enemy_party: Array[Monster] = []
	var enemy_trainer: Trainer = null
	var ended: bool = false

	func end_battle() -> void:
		ended = true


class FakeHandler:
	extends Node

	var is_escaped: bool = false


class CaptureAction:
	extends RefCounted

	var priority: int = 0

	func execute(_actor: Monster, target: Monster, _battle_context: BattleContext) -> void:
		target.is_captured = true
