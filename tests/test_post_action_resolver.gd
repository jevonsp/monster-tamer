extends GutTest

const PostActionResolverScript = preload("res://battle/post_action_resolver.gd")


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
	if not Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.connect(_on_send_text_box)
	if not Global.send_monster_death_experience.is_connected(_on_send_monster_death_experience):
		Global.send_monster_death_experience.connect(_on_send_monster_death_experience)


func after_each() -> void:
	if Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.disconnect(_on_send_text_box)
	if Global.send_monster_death_experience.is_connected(_on_send_monster_death_experience):
		Global.send_monster_death_experience.disconnect(_on_send_monster_death_experience)
	if is_instance_valid(_battle):
		_battle.free()
	_battle = null
	_resolver = null
	_handler = null
	_forced_switch = null


func test_escape_ends_battle_immediately() -> void:
	_handler.is_escaped = true
	var target := _make_monster("Enemy", false)

	var ended: bool = await _resolver.handle_post_action(target, _handler)

	assert_true(ended)
	assert_true(_battle.ended)


func test_capture_ends_battle() -> void:
	_battle.player_actor = _make_monster("Player", true)
	_battle.enemy_actor = _make_monster("Enemy", false)
	_battle.enemy_actor.is_captured = true

	var ended: bool = await _resolver.handle_post_action(_battle.enemy_actor, _handler)

	assert_true(ended)
	assert_true(_battle.ended)


func test_enemy_forced_switch_when_enemy_fainted_but_party_has_backup() -> void:
	_battle.player_actor = _make_monster("Player", true)
	_battle.enemy_actor = _make_monster("Enemy", false)
	_battle.enemy_actor.is_fainted = true
	var backup := _make_monster("Backup", false)
	_battle.enemy_party = [_battle.enemy_actor, backup]

	var ended: bool = await _resolver.handle_post_action(_battle.enemy_actor, _handler)

	assert_false(ended)
	assert_false(_battle.ended)
	assert_true(_forced_switch.enemy_switch_called)


func test_player_forced_switch_when_player_fainted_but_party_has_backup() -> void:
	_battle.player_actor = _make_monster("Player", true)
	_battle.player_actor.is_fainted = true
	_battle.enemy_actor = _make_monster("Enemy", false)
	_battle.player_party = [_battle.player_actor, _make_monster("Backup", true)]

	var ended: bool = await _resolver.handle_post_action(_battle.player_actor, _handler)

	assert_false(ended)
	assert_false(_battle.ended)
	assert_true(_forced_switch.player_switch_called)


func _make_monster(monster_name: String, is_player: bool) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.is_player_monster = is_player
	monster.level = 8
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 10
	monster.defense = 10
	monster.special_attack = 10
	monster.special_defense = 10
	monster.speed = 10
	monster.max_hitpoints = 30
	monster.current_hitpoints = 30
	monster.create_stat_multis()
	return monster


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
	Global.text_box_complete.emit()


func _emit_player_done_giving_exp() -> void:
	Global.player_done_giving_exp.emit()
