extends GutTest

var hit_reactions: int = 0


func before_each() -> void:
	hit_reactions = 0
	if not Global.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Global.send_hitpoints_change.connect(_on_send_hitpoints_change)
	if not Global.send_sprite_shake.is_connected(_on_send_sprite_shake):
		Global.send_sprite_shake.connect(_on_send_sprite_shake)
	if not Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Global.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Global.send_hitpoints_change.disconnect(_on_send_hitpoints_change)
	if Global.send_sprite_shake.is_connected(_on_send_sprite_shake):
		Global.send_sprite_shake.disconnect(_on_send_sprite_shake)
	if Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.disconnect(_on_send_text_box)


func test_confusion_sets_override_flag_when_self_hit_occurs() -> void:
	var status := ConfusionStatus.new()
	status.self_hit_chance = 1.0
	var instance := StatusInstance.new(status, _make_monster(), 3)
	var move := Move.new()

	status.on_turn_start(instance, instance.owner, null)

	assert_true(status.has_action_override(instance, instance.owner, null, move))


func test_confusion_execute_override_deals_self_damage_and_clears_flag() -> void:
	var status := ConfusionStatus.new()
	status.self_hit_chance = 1.0
	status.self_hit_power = 30
	var acting_monster := _make_monster()
	var instance := StatusInstance.new(status, acting_monster, 3)
	var context := _make_context()
	instance.runtime_data["confusion_self_hit"] = true

	await status.execute_action_override(instance, acting_monster, acting_monster, context, Move.new())

	assert_lt(acting_monster.current_hitpoints, acting_monster.max_hitpoints)
	assert_eq(hit_reactions, 1)
	assert_eq(instance.runtime_data["confusion_self_hit"], false)


func _on_send_hitpoints_change(_target: Monster, _hp: int) -> void:
	Global.hitpoints_animation_complete.emit()


func _on_send_sprite_shake(_target: Monster) -> void:
	hit_reactions += 1


func _on_send_text_box(
	_object: Node,
	_text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	Global.text_box_complete.emit()


func _make_context() -> BattleContext:
	return BattleContext.new(Node.new(), Control.new())


func _make_monster() -> Monster:
	var monster := Monster.new()
	monster.name = "Confused"
	monster.level = 15
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 35
	monster.defense = 30
	monster.special_attack = 20
	monster.special_defense = 20
	monster.speed = 20
	monster.max_hitpoints = 90
	monster.current_hitpoints = 90
	monster.create_stat_multis()
	return monster
