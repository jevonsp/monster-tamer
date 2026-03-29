extends GutTest

const ActionQueueBuilderScript = preload("res://battle/action_queue_builder.gd")


class FakeBattle:
	extends Control

	var player_actor: Monster
	var enemy_actor: Monster
	var is_wild_battle: bool = false


func test_add_action_to_queue_returns_false_for_null() -> void:
	var builder = ActionQueueBuilderScript.new()
	var battle := FakeBattle.new()
	var queue: Array[Dictionary] = []

	assert_false(builder.add_action_to_queue(null, null, battle, queue))
	assert_eq(queue.size(), 0)
	battle.free()


func test_add_action_to_queue_uses_self_targeting_move_target() -> void:
	var builder = ActionQueueBuilderScript.new()
	var battle := FakeBattle.new()
	var actor := _make_monster("Actor")
	var enemy := _make_monster("Enemy")
	var move := Move.new()
	move.is_self_targeting = true
	battle.player_actor = actor
	battle.enemy_actor = enemy
	var queue: Array[Dictionary] = []

	builder.add_action_to_queue(move, actor, battle, queue)

	assert_eq(queue.size(), 1)
	assert_eq(queue[0]["target"], actor)
	battle.free()


func test_healing_item_targets_actor_and_catch_item_targets_enemy() -> void:
	var builder = ActionQueueBuilderScript.new()
	var battle := FakeBattle.new()
	var actor := _make_monster("Actor")
	var enemy := _make_monster("Enemy")
	battle.player_actor = actor
	battle.enemy_actor = enemy

	var healing_item := Item.new()
	healing_item.use_effect = HealingEffect.new()
	var catch_item := Item.new()
	catch_item.catch_effect = CatchEffect.new()
	var queue: Array[Dictionary] = []

	builder.add_action_to_queue(healing_item, actor, battle, queue)
	builder.add_action_to_queue(catch_item, actor, battle, queue)

	assert_eq(queue[0]["target"], actor)
	assert_eq(queue[1]["target"], enemy)
	battle.free()


func test_enemy_move_selection_prefers_effective_non_redundant_move() -> void:
	var builder = ActionQueueBuilderScript.new()
	var battle := FakeBattle.new()
	var player := _make_monster("Player")
	player.primary_type = TypeChart.Type.GRASS
	var enemy := _make_monster("Enemy")
	battle.player_actor = player
	battle.enemy_actor = enemy

	var bad_move := Move.new()
	bad_move.type = TypeChart.Type.WATER

	var good_move := Move.new()
	good_move.type = TypeChart.Type.FIRE

	var status_data := StatusData.new()
	status_data.status_name = "burn"
	var status_effect := ApplyStatusEffect.new()
	status_effect.status_data = status_data
	good_move.effects = [status_effect]

	await player.add_status(status_data)
	enemy.moves = [bad_move, good_move]

	var selected: Move = builder.get_enemy_move_from_battle(battle)
	assert_eq(selected, good_move)
	battle.free()


func test_enemy_stat_boost_over_cap_is_penalized() -> void:
	var builder = ActionQueueBuilderScript.new()
	var battle := FakeBattle.new()
	var player := _make_monster("Player")
	var enemy := _make_monster("Enemy")
	battle.player_actor = player
	battle.enemy_actor = enemy

	enemy.stat_stages_and_multis.stat_stages[Monster.Stat.ATTACK] = 6
	var boost_effect := StatBoostEffect.new()
	boost_effect.stat = Monster.Stat.ATTACK
	boost_effect.stage_amount = 1
	var boost_move := Move.new()
	boost_move.type = TypeChart.Type.FIRE
	boost_move.effects = [boost_effect]

	var neutral_move := Move.new()
	neutral_move.type = TypeChart.Type.NONE

	enemy.moves = [boost_move, neutral_move]
	var selected: Move = builder.get_enemy_move_from_battle(battle)
	assert_eq(selected, neutral_move)
	battle.free()


func _make_monster(monster_name: String) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.level = 10
	monster.primary_type = TypeChart.Type.NONE
	monster.speed = 20
	monster.attack = 20
	monster.defense = 20
	monster.special_attack = 20
	monster.special_defense = 20
	monster.max_hitpoints = 100
	monster.current_hitpoints = 100
	monster.create_stat_multis()
	return monster
