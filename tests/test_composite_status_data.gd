extends GutTest


class TrackingStatus:
	extends StatusData
	var id: String = ""
	var can_act: bool = true
	var block_text: Array[String] = []
	var add_value: float = 0.0
	var calls: Array[String] = []

	func on_turn_start(_instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
		calls.append("%s:start" % id)

	func on_turn_end(_instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
		calls.append("%s:end" % id)

	func modify_effective_stat(
		_instance: StatusInstance,
		_owner: Monster,
		_stat: Monster.Stat,
		value: float
	) -> float:
		return value + add_value

	func can_attempt_action(
		_instance: StatusInstance,
		_owner: Monster,
		_context: BattleContext
	) -> bool:
		return can_act

	func get_action_block_text(_instance: StatusInstance, _owner: Monster) -> Array[String]:
		return block_text


func test_composite_invokes_child_hooks_in_order() -> void:
	var first := TrackingStatus.new()
	first.id = "first"
	var second := TrackingStatus.new()
	second.id = "second"
	var composite := CompositeStatusData.new()
	composite.child_statuses = [first, second]
	var instance := StatusInstance.new(composite, _make_monster(), 3)

	await composite.on_turn_start(instance, instance.owner, null)
	await composite.on_turn_end(instance, instance.owner, null)

	assert_eq(first.calls, ["first:start", "first:end"])
	assert_eq(second.calls, ["second:start", "second:end"])


func test_composite_stat_modification_chains_each_child() -> void:
	var first := TrackingStatus.new()
	first.add_value = 2.0
	var second := TrackingStatus.new()
	second.add_value = 3.0
	var composite := CompositeStatusData.new()
	composite.child_statuses = [first, second]
	var value := composite.modify_effective_stat(StatusInstance.new(), null, Monster.Stat.SPEED, 5.0)

	assert_eq(value, 10.0)


func test_composite_can_attempt_action_short_circuits_false() -> void:
	var first := TrackingStatus.new()
	first.can_act = true
	var second := TrackingStatus.new()
	second.can_act = false
	second.block_text = ["Blocked"]
	var composite := CompositeStatusData.new()
	composite.child_statuses = [first, second]
	var instance := StatusInstance.new(composite, _make_monster(), 2)

	assert_false(composite.can_attempt_action(instance, instance.owner, null))
	assert_eq(composite.get_action_block_text(instance, instance.owner), ["Blocked"])


func _make_monster() -> Monster:
	var monster := Monster.new()
	monster.primary_type = TypeChart.Type.NONE
	monster.create_stat_multis()
	return monster
