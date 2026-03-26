extends GutTest


func test_random_action_block_status_blocks_when_chance_is_one() -> void:
	var status := RandomActionBlockStatus.new()
	status.block_chance = 1.0
	status.action_block_message = "%s cant move!"
	var owner := _make_monster("Owner")
	var instance := StatusInstance.new(status, owner, 2)

	await status.on_turn_start(instance, owner, null)

	assert_false(status.can_attempt_action(instance, owner, null))
	assert_eq(status.get_action_block_text(instance, owner), ["Owner cant move!"])


func test_forced_action_block_status_expires_when_remove_chance_is_one() -> void:
	var status := ForcedActionBlockStatus.new()
	status.remove_chance = 1.0
	var owner := _make_monster("Owner")
	var instance := StatusInstance.new(status, owner, 2)

	await status.on_turn_start(instance, owner, null)

	assert_true(instance.is_expired())
	assert_true(status.can_attempt_action(instance, owner, null))


func _make_monster(monster_name: String) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.primary_type = TypeChart.Type.NONE
	monster.create_stat_multis()
	return monster
