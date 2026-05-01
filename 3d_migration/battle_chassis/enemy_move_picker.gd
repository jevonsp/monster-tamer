class_name EnemyMovePicker
extends RefCounted

var monster: Monster = null


func _init(m: Monster) -> void:
	monster = m


func pick_move() -> Move:
	if not monster:
		return null

	var usable_moves: Array[Move] = []
	for i in monster.moves.size():
		var move = monster.moves[i]
		print(monster.move_pp)
		if move and monster.move_pp[move] > 0:
			usable_moves.append(move)

	var picked_move = usable_moves.pick_random()

	return picked_move
