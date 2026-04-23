extends "res://tests/monster_tamer_test.gd"

const PartyHandler3DScript := preload("res://3d_migration/player_handlers/party_handler_3d.gd")
const TH := preload("res://tests/monster_factory.gd")

var party_handler: Node


func before_each() -> void:
	party_handler = PartyHandler3DScript.new()
	party_handler.create_storage()


func after_each() -> void:
	if is_instance_valid(party_handler):
		party_handler.free()
	party_handler = null
	super.after_each()


func test_add_places_overflow_monsters_in_storage() -> void:
	for i in range(6):
		party_handler.add(TH.make_monster("Party%s" % i, 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30))
	var overflow := TH.make_monster("Overflow", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)

	party_handler.add(overflow)

	assert_eq(party_handler.party.size(), 6)
	assert_eq(party_handler.storage.find_key(overflow), 0)


func test_deposit_and_withdraw_update_party_and_storage() -> void:
	var mon := TH.make_monster("StorageMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)
	party_handler.add(mon)

	party_handler.deposit_monster(mon)
	assert_false(party_handler.party.has(mon))
	assert_ne(party_handler.storage.find_key(mon), null)

	party_handler.withdraw_monster(mon)
	assert_true(party_handler.party.has(mon))
	assert_eq(party_handler.storage.find_key(mon), null)


func test_switch_moves_returns_early_on_invalid_indexes() -> void:
	var mon := TH.make_monster("Mover", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 30)
	var move_a := Move.new()
	move_a.name = "A"
	var move_b := Move.new()
	move_b.name = "B"
	mon.moves = [move_a, move_b]
	party_handler.add(mon)

	party_handler.on_switch_moves(mon, -1, 1)

	assert_eq(mon.moves[0], move_a)
	assert_eq(mon.moves[1], move_b)
