extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")
const BURN_STATUS = preload("res://statuses/burn.tres")
const CONFUSION_STATUS = preload("res://statuses/confusion.tres")
const FROZEN_STATUS = preload("res://statuses/frozen.tres")
const PARALYZE_STATUS = preload("res://statuses/paralyze.tres")
const POISON_STATUS = preload("res://statuses/poison.tres")
const SLEEP_STATUS = preload("res://statuses/sleep.tres")

var shown_text: Array[Array] = []
var hitpoint_updates: Array[int] = []
var shaken_targets: Array[Monster] = []
var context: BattleContext
var _context_nodes: Array[Node] = []


func before_each() -> void:
	shown_text.clear()
	hitpoint_updates.clear()
	shaken_targets.clear()
	_context_nodes.clear()
	var handler := Node.new()
	var battle := Control.new()
	_context_nodes.append(handler)
	_context_nodes.append(battle)
	context = BattleContext.new(handler, battle)
	_connect_global_test_hooks()


func after_each() -> void:
	_disconnect_global_test_hooks()
	for node in _context_nodes:
		if is_instance_valid(node):
			node.free()
	_context_nodes.clear()
	context = null
	shaken_targets.clear()
	hitpoint_updates.clear()
	shown_text.clear()
	super.after_each()


func test_burn_is_main_status_and_applies_attack_drop_and_dot() -> void:
	var monster := _make_monster()

	var result: Monster.StatusApplyResult = await monster.add_status(BURN_STATUS)

	assert_eq(result, Monster.StatusApplyResult.APPLIED)
	assert_eq(BURN_STATUS.status_slot, StatusData.StatusSlot.MAIN)
	assert_true(monster.has_status_id("burn"))
	assert_eq(monster.get_effective_stat(Monster.Stat.ATTACK), 15.0)

	await monster.tick_statuses_end(context)

	assert_eq(monster.current_hitpoints, 88)
	assert_eq(hitpoint_updates, [88])
	assert_eq(shown_text[0], ["TestMon was hurt by it's Burn."])


func test_poison_is_main_status_and_conflicts_with_other_main_statuses() -> void:
	var monster := _make_monster()
	await monster.add_status(BURN_STATUS)

	var conflict_result: Monster.StatusApplyResult = await monster.add_status(POISON_STATUS)

	assert_eq(conflict_result, Monster.StatusApplyResult.BLOCKED_SLOT_CONFLICT)
	assert_eq(POISON_STATUS.status_slot, StatusData.StatusSlot.MAIN)
	assert_false(monster.has_status_id("poison"))

	var clean_monster := _make_monster()
	var apply_result: Monster.StatusApplyResult = await clean_monster.add_status(POISON_STATUS)

	assert_eq(apply_result, Monster.StatusApplyResult.APPLIED)
	await clean_monster.tick_statuses_end(context)
	assert_eq(clean_monster.current_hitpoints, 88)
	assert_eq(shown_text[-1], ["TestMon was hurt by it's Poison."])


func test_paralyze_is_main_status_with_speed_penalty_and_block_text() -> void:
	var monster := _make_monster()
	var paralyze := PARALYZE_STATUS.duplicate(true)
	paralyze.child_statuses[1].block_chance = 1.0

	var result: Monster.StatusApplyResult = await monster.add_status(paralyze)

	assert_eq(result, Monster.StatusApplyResult.APPLIED)
	assert_eq(paralyze.status_slot, StatusData.StatusSlot.MAIN)
	assert_eq(monster.get_effective_speed(), 20.0)

	monster.reset_status_turn_state()
	await monster.tick_statuses_start(context)

	assert_false(monster.can_attempt_action(context))
	assert_eq(monster.get_action_block_text(), ["TestMon is fully paralyzed!"])


func test_sleep_blocks_action_and_expires_after_its_duration() -> void:
	var monster := _make_monster()
	var sleep := SLEEP_STATUS.duplicate(true)
	sleep.default_duration = 1

	var result: Monster.StatusApplyResult = await monster.add_status(sleep)

	assert_eq(result, Monster.StatusApplyResult.APPLIED)
	assert_eq(sleep.status_slot, StatusData.StatusSlot.MAIN)

	monster.reset_status_turn_state()
	await monster.tick_statuses_start(context)

	assert_false(monster.can_attempt_action(context))
	assert_eq(monster.get_action_block_text(), ["TestMon is fast asleep!"])

	await monster.tick_statuses_end(context)

	assert_false(monster.has_status_id("sleep"))
	assert_eq(monster.statuses.size(), 0)


func test_frozen_blocks_when_active_and_can_remove_itself_on_turn_start() -> void:
	var active_monster := _make_monster()
	var frozen_active := FROZEN_STATUS.duplicate(true)
	frozen_active.remove_chance = 0.0
	await active_monster.add_status(frozen_active)

	active_monster.reset_status_turn_state()
	await active_monster.tick_statuses_start(context)

	assert_false(active_monster.can_attempt_action(context))
	assert_eq(active_monster.get_action_block_text(), ["TestMon is frozen solid!"])

	var thawed_monster := _make_monster()
	var frozen_thaw := FROZEN_STATUS.duplicate(true)
	frozen_thaw.remove_chance = 1.0
	await thawed_monster.add_status(frozen_thaw)

	thawed_monster.reset_status_turn_state()
	await thawed_monster.tick_statuses_start(context)

	assert_true(thawed_monster.can_attempt_action(context))
	assert_false(thawed_monster.has_status_id("frozen"))


func test_confusion_is_separate_refreshes_and_can_self_hit() -> void:
	var monster := _make_monster()
	var confusion := CONFUSION_STATUS.duplicate(true)
	confusion.self_hit_chance = 1.0
	await monster.add_status(BURN_STATUS)

	var apply_result: Monster.StatusApplyResult = await monster.add_status(confusion, 2)
	var refresh_result: Monster.StatusApplyResult = await monster.add_status(confusion, 5)

	assert_eq(apply_result, Monster.StatusApplyResult.APPLIED)
	assert_eq(refresh_result, Monster.StatusApplyResult.REFRESHED)
	assert_eq(confusion.status_slot, StatusData.StatusSlot.SEPARATE)
	assert_true(monster.has_status_id("burn"))
	assert_true(monster.has_status_id("confusion"))
	assert_eq(monster.get_status_by_id("confusion").remaining_turns, 5)

	monster.reset_status_turn_state()
	await monster.tick_statuses_start(context)

	var move := Move.new()
	assert_true(monster.has_action_override(context, move))

	await monster.execute_action_override(monster, context, move)

	assert_eq(monster.current_hitpoints, 94)
	assert_eq(shaken_targets.size(), 1)
	assert_eq(shaken_targets[0], monster)
	assert_eq(shown_text[0], ["TestMon is confused!"])
	assert_eq(shown_text[1], ["TestMon hurt itself in its confusion!"])
	assert_eq(shown_text[2], ["It dealt 6 damage."])
	assert_false(monster.has_action_override(context, move))


func test_duplicate_main_status_is_rejected_without_refreshing_duration() -> void:
	var monster := _make_monster()
	var burn := BURN_STATUS.duplicate(true)
	burn.default_duration = 4
	await monster.add_status(burn, 4)

	var result: Monster.StatusApplyResult = await monster.add_status(burn, 1)

	assert_eq(result, Monster.StatusApplyResult.BLOCKED_DUPLICATE)
	assert_eq(monster.statuses.size(), 1)
	assert_eq(monster.get_status_by_id("burn").remaining_turns, 4)


func _make_monster() -> Monster:
	return TH.make_monster(
		"TestMon",
		10,
		TypeChart.Type.NONE,
		null,
		30,
		30,
		30,
		30,
		40,
		100,
	)


func _connect_global_test_hooks() -> void:
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)
	if not Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.connect(_on_send_hitpoints_change)
	if not Battle.send_sprite_shake.is_connected(_on_send_sprite_shake):
		Battle.send_sprite_shake.connect(_on_send_sprite_shake)


func _disconnect_global_test_hooks() -> void:
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)
	if Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.disconnect(_on_send_hitpoints_change)
	if Battle.send_sprite_shake.is_connected(_on_send_sprite_shake):
		Battle.send_sprite_shake.disconnect(_on_send_sprite_shake)


func _on_send_text_box(
		_object,
		text: Array[String],
		_auto_complete: bool,
		_is_question: bool,
		_toggles_player: bool,
) -> void:
	shown_text.append(text.duplicate())
	call_deferred("_emit_text_box_complete")


func _on_send_hitpoints_change(_target: Monster, new_hp: int) -> void:
	hitpoint_updates.append(new_hp)
	call_deferred("_emit_hitpoints_animation_complete")


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()


func _emit_hitpoints_animation_complete() -> void:
	Battle.hitpoints_animation_complete.emit()


func _on_send_sprite_shake(target: Monster) -> void:
	shaken_targets.append(target)
