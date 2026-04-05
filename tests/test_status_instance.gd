extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")


func test_tick_duration_reduces_remaining_turns_until_expired() -> void:
	var status := StatusData.new()
	status.default_duration = 2
	var instance := StatusInstance.new(status, TH.make_monster(), -1)

	instance.tick_duration()
	assert_eq(instance.remaining_turns, 1)
	assert_false(instance.is_expired())

	instance.tick_duration()
	assert_eq(instance.remaining_turns, 0)
	assert_true(instance.is_expired())


func test_reset_turn_state_clears_flags_and_runtime_data() -> void:
	var instance := StatusInstance.new(StatusData.new(), TH.make_monster(), 3)
	instance.blocks_action_this_turn = true
	instance.runtime_data["key"] = true

	instance.reset_turn_state()

	assert_false(instance.blocks_action_this_turn)
	assert_eq(instance.runtime_data.size(), 0)
