extends GutTest


func test_random_action_block_status_blocks_when_chance_is_one() -> void:
	var status := RandomActionBlockStatus.new()
	status.block_chance = 1.0
	status.action_block_message = "%s cant move!"
	var o := _make_monster("Owner")
	var instance := StatusInstance.new(status, o, 2)

	@warning_ignore("redundant_await")
	await status.on_turn_start(instance, o, null)

	assert_false(status.can_attempt_action(instance, o, null))
	assert_eq(status.get_action_block_text(instance, o), ["Owner cant move!"])


func test_forced_action_block_status_expires_when_remove_chance_is_one() -> void:
	var status := ForcedActionBlockStatus.new()
	status.remove_chance = 1.0
	var o := _make_monster("Owner")
	var instance := StatusInstance.new(status, o, 2)

	@warning_ignore("redundant_await")
	await status.on_turn_start(instance, o, null)

	assert_true(instance.is_expired())
	assert_true(status.can_attempt_action(instance, o, null))


func _make_monster(monster_name: String) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.primary_type = TypeChart.Type.NONE
	monster.create_stat_multis()
	return monster
