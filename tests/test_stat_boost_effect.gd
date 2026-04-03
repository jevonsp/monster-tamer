extends GutTest

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
	for node in _context_nodes:
		if is_instance_valid(node):
			node.free()
	_context_nodes.clear()


func test_stat_boost_effect_applies_to_self_when_self_targeting() -> void:
	var effect := StatBoostEffect.new()
	effect.stat = Monster.Stat.ATTACK
	effect.stage_amount = 2
	effect.is_self_targeting = true
	var actor := _make_monster("Actor")
	var target := _make_monster("Target")
	var context := _make_context()

	await effect.apply(actor, target, context)

	assert_eq(actor.stat_stages_and_multis.stat_stages[Monster.Stat.ATTACK], 2)
	assert_eq(target.stat_stages_and_multis.stat_stages[Monster.Stat.ATTACK], 0)
	assert_eq(stat_animation_calls, 1)


func test_stat_boost_effect_applies_to_target_when_not_self_targeting() -> void:
	var effect := StatBoostEffect.new()
	effect.stat = Monster.Stat.DEFENSE
	effect.stage_amount = -1
	effect.is_self_targeting = false
	var actor := _make_monster("Actor")
	var target := _make_monster("Target")
	var context := _make_context()

	await effect.apply(actor, target, context)

	assert_eq(target.stat_stages_and_multis.stat_stages[Monster.Stat.DEFENSE], -1)
	assert_eq(actor.stat_stages_and_multis.stat_stages[Monster.Stat.DEFENSE], 0)


func test_stat_boost_effect_blocks_when_stage_would_exceed_cap() -> void:
	var effect := StatBoostEffect.new()
	effect.stat = Monster.Stat.SPEED
	effect.stage_amount = 1
	effect.is_self_targeting = true
	var actor := _make_monster("Actor")
	actor.stat_stages_and_multis.stat_stages[Monster.Stat.SPEED] = 6
	var context := _make_context()

	await effect.apply(actor, _make_monster("Target"), context)

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


func _make_context() -> BattleContext:
	var handler := Node.new()
	var battle := Control.new()
	_context_nodes.append(handler)
	_context_nodes.append(battle)
	return BattleContext.new(handler, battle)


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
	monster.max_hitpoints = 60
	monster.current_hitpoints = 60
	monster.create_stat_multis()
	return monster
