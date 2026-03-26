extends GutTest


func before_each() -> void:
	if not Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Global.send_text_box.is_connected(_on_send_text_box):
		Global.send_text_box.disconnect(_on_send_text_box)


func test_teach_effect_returns_when_move_is_null() -> void:
	var effect := TeachEffect.new()
	var monster := _make_monster()
	effect.move = null

	await effect.use(monster)

	assert_true(monster.moves.is_empty())


func test_teach_effect_stops_when_move_already_known() -> void:
	var effect := TeachEffect.new()
	var move := Move.new()
	move.name = "Tackle"
	effect.move = move
	var monster := _make_monster()
	monster.moves = [move]

	await effect.use(monster)

	assert_eq(monster.moves.size(), 1)
	assert_eq(monster.moves[0], move)


func test_teach_effect_stops_when_target_cannot_learn_move() -> void:
	var effect := TeachEffect.new()
	var move := Move.new()
	move.name = "Flame"
	effect.move = move
	var monster := _make_monster()
	var data := MonsterData.new()
	data.learn_set = []
	monster.monster_data = data

	await effect.use(monster)

	assert_true(monster.moves.is_empty())


func _on_send_text_box(
	_object: Node,
	_text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	Global.text_box_complete.emit()


func _make_monster() -> Monster:
	var monster := Monster.new()
	monster.name = "TeachMon"
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 10
	monster.defense = 10
	monster.special_attack = 10
	monster.special_defense = 10
	monster.speed = 10
	monster.max_hitpoints = 50
	monster.current_hitpoints = 50
	monster.create_stat_multis()
	return monster
