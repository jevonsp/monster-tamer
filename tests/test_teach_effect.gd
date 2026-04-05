extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")


func before_each() -> void:
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)


func after_each() -> void:
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)
	super.after_each()


func test_teach_effect_returns_when_move_is_null() -> void:
	var effect := TeachEffect.new()
	var monster := TH.make_monster("TeachMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 50)
	effect.move = null

	await effect.use(monster)

	assert_true(monster.moves.is_empty())


func test_teach_effect_stops_when_move_already_known() -> void:
	var effect := TeachEffect.new()
	var move := Move.new()
	move.name = "Tackle"
	effect.move = move
	var monster := TH.make_monster("TeachMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 50)
	monster.moves = [move]

	await effect.use(monster)

	assert_eq(monster.moves.size(), 1)
	assert_eq(monster.moves[0], move)


func test_teach_effect_stops_when_target_cannot_learn_move() -> void:
	var effect := TeachEffect.new()
	var move := Move.new()
	move.name = "Flame"
	effect.move = move
	var monster := TH.make_monster("TeachMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 50)
	var data := MonsterData.new()
	data.learn_set = []
	monster.monster_data = data

	await effect.use(monster)

	assert_true(monster.moves.is_empty())


func _on_send_text_box(
	_object,
	_text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	call_deferred("_emit_text_box_complete")


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()
