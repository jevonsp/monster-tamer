extends GutTest


func test_get_effective_stat_applies_stage_multiplier_and_status_modifier() -> void:
	var monster := _make_monster()
	monster.speed = 40
	monster.stat_stages_and_multis.stat_stages[Monster.Stat.SPEED] = 1
	var status := StatModifierStatus.new()
	status.stat = Monster.Stat.SPEED
	status.multiplier = 0.5
	await monster.add_status(status)

	var effective_speed := monster.get_effective_speed()

	assert_eq(effective_speed, 30.0)


func test_main_status_conflicts_and_separate_status_refreshes() -> void:
	var monster := _make_monster()
	var burn := StatusData.new()
	burn.status_id = "burn"
	burn.status_name = "Burn"
	burn.status_slot = StatusData.StatusSlot.MAIN
	var poison := StatusData.new()
	poison.status_id = "poison"
	poison.status_name = "Poison"
	poison.status_slot = StatusData.StatusSlot.MAIN
	var confusion := StatusData.new()
	confusion.status_id = "confusion"
	confusion.status_name = "Confusion"
	confusion.status_slot = StatusData.StatusSlot.SEPARATE

	assert_eq(await monster.add_status(burn, 3), Monster.StatusApplyResult.APPLIED)
	assert_eq(await monster.add_status(poison, 3), Monster.StatusApplyResult.BLOCKED_SLOT_CONFLICT)
	assert_eq(await monster.add_status(confusion, 2), Monster.StatusApplyResult.APPLIED)
	assert_eq(await monster.add_status(confusion, 5), Monster.StatusApplyResult.REFRESHED)
	assert_eq(monster.get_status_by_id("confusion").remaining_turns, 5)


func test_gain_exp_crosses_level_threshold() -> void:
	var monster := _make_monster()
	monster.level = 1
	monster.experience = 0
	monster.monster_data = MonsterData.new()

	await monster.gain_exp(60, false)

	assert_eq(monster.level, 2)
	assert_eq(monster.experience, 60)


func _make_monster() -> Monster:
	var monster := Monster.new()
	monster.name = "CoreMon"
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 20
	monster.defense = 20
	monster.special_attack = 20
	monster.special_defense = 20
	monster.speed = 20
	monster.max_hitpoints = 80
	monster.current_hitpoints = 80
	monster.create_stat_multis()
	return monster
