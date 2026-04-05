extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")


func test_attempt_catch_returns_expected_result_payload_shape() -> void:
	var target := TH.make_monster("WildMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 100, 100)
	var item := Item.new()
	item.catch_effect = CatchEffect.new()
	item.catch_effect.catch_rate_modifier = 1.0

	var result := target.attempt_catch(item, TH.make_monster("Actor", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 100, 100))

	assert_true(result.has("times"))
	assert_true(result.has("success"))
	assert_typeof(result["times"], TYPE_INT)
	assert_typeof(result["success"], TYPE_BOOL)


func test_attempt_catch_is_guaranteed_when_rate_caps_to_255() -> void:
	var target := TH.make_monster("WildMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 100, 1)
	var item := Item.new()
	item.catch_effect = CatchEffect.new()
	item.catch_effect.catch_rate_modifier = 99999.0

	var result := target.attempt_catch(item, TH.make_monster("Actor", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 100, 100))

	assert_true(result["success"])
