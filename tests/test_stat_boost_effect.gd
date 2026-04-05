extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")

var stat_animation_calls: int = 0
var _context_nodes: Array[Node] = []


func before_each() -> void:
	stat_animation_calls = 0
	_context_nodes.clear()
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)
	if not Battle.send_stat_change_animation.is_connected(_on_send_stat_change_animation):
		Battle.send_stat_change_animation.connect(_on_send_stat_change_animation)


func after_each() -> void:
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)
	if Battle.send_stat_change_animation.is_connected(_on_send_stat_change_animation):
		Battle.send_stat_change_animation.disconnect(_on_send_stat_change_animation)
	TH.free_if_valid(_context_nodes)
	_context_nodes.clear()
	super.after_each()


func test_stat_boost_effect_applies_to_self_when_self_targeting() -> void:
	var effect := StatBoostEffect.new()
	effect.stat = Monster.Stat.ATTACK
	effect.stage_amount = 2
	effect.is_self_targeting = true
	var actor := TH.make_monster("Actor", 10, TypeChart.Type.NONE, null, 20, 20, 20, 20, 20, 60)
	var target := TH.make_monster("Target", 10, TypeChart.Type.NONE, null, 20, 20, 20, 20, 20, 60)
	var ctx_pack := TH.make_battle_context()
	var context: BattleContext = ctx_pack[0]
	_context_nodes.append_array(ctx_pack[1])

	await effect.apply(actor, target, context)

	assert_eq(actor.stat_stages_and_multis.stat_stages[Monster.Stat.ATTACK], 2)
	assert_eq(target.stat_stages_and_multis.stat_stages[Monster.Stat.ATTACK], 0)
	assert_eq(stat_animation_calls, 1)


func test_stat_boost_effect_applies_to_target_when_not_self_targeting() -> void:
	var effect := StatBoostEffect.new()
	effect.stat = Monster.Stat.DEFENSE
	effect.stage_amount = -1
	effect.is_self_targeting = false
	var actor := TH.make_monster("Actor", 10, TypeChart.Type.NONE, null, 20, 20, 20, 20, 20, 60)
	var target := TH.make_monster("Target", 10, TypeChart.Type.NONE, null, 20, 20, 20, 20, 20, 60)
	var ctx_pack := TH.make_battle_context()
	var context: BattleContext = ctx_pack[0]
	_context_nodes.append_array(ctx_pack[1])

	await effect.apply(actor, target, context)

	assert_eq(target.stat_stages_and_multis.stat_stages[Monster.Stat.DEFENSE], -1)
	assert_eq(actor.stat_stages_and_multis.stat_stages[Monster.Stat.DEFENSE], 0)


func test_stat_boost_effect_blocks_when_stage_would_exceed_cap() -> void:
	var effect := StatBoostEffect.new()
	effect.stat = Monster.Stat.SPEED
	effect.stage_amount = 1
	effect.is_self_targeting = true
	var actor := TH.make_monster("Actor", 10, TypeChart.Type.NONE, null, 20, 20, 20, 20, 20, 60)
	actor.stat_stages_and_multis.stat_stages[Monster.Stat.SPEED] = 6
	var ctx_pack := TH.make_battle_context()
	var context: BattleContext = ctx_pack[0]
	_context_nodes.append_array(ctx_pack[1])

	await effect.apply(actor, TH.make_monster("Target", 10), context)

	assert_eq(actor.stat_stages_and_multis.stat_stages[Monster.Stat.SPEED], 6)
	assert_eq(stat_animation_calls, 0)


func _on_send_text_box(
		_object,
		_text: Array[String],
		_auto_complete: bool,
		_is_question: bool,
		_toggles_player: bool,
) -> void:
	call_deferred("_emit_text_box_complete")


func _on_send_stat_change_animation(
		_monster: Monster,
		_stat: Monster.Stat,
		_amount: int,
) -> void:
	stat_animation_calls += 1
	call_deferred("_emit_stat_change_animation_complete")


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()


func _emit_stat_change_animation_complete() -> void:
	Battle.stat_change_animation_complete.emit()
