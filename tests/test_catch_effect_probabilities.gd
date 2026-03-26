extends GutTest


func test_attempt_catch_returns_expected_result_payload_shape() -> void:
	var target := _make_monster(100, 100)
	var item := Item.new()
	item.catch_effect = CatchEffect.new()
	item.catch_effect.catch_rate_modifier = 1.0

	var result := target.attempt_catch(item, _make_monster(100, 100))

	assert_true(result.has("times"))
	assert_true(result.has("success"))
	assert_typeof(result["times"], TYPE_INT)
	assert_typeof(result["success"], TYPE_BOOL)


func test_attempt_catch_is_guaranteed_when_rate_caps_to_255() -> void:
	var target := _make_monster(100, 1)
	var item := Item.new()
	item.catch_effect = CatchEffect.new()
	item.catch_effect.catch_rate_modifier = 99999.0

	var result := target.attempt_catch(item, _make_monster(100, 100))

	assert_true(result["success"])


func _make_monster(max_hp: int, current_hp: int) -> Monster:
	var monster := Monster.new()
	monster.name = "WildMon"
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 10
	monster.defense = 10
	monster.special_attack = 10
	monster.special_defense = 10
	monster.speed = 10
	monster.max_hitpoints = max_hp
	monster.current_hitpoints = current_hp
	monster.create_stat_multis()
	return monster
