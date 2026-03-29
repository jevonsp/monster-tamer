extends GutTest

const PartyHandlerScript = preload("res://player/party_handler.gd")

var party_handler: Node


func before_each() -> void:
	party_handler = PartyHandlerScript.new()
	party_handler.create_storage()


func after_each() -> void:
	if is_instance_valid(party_handler):
		party_handler.free()
	party_handler = null


func test_add_places_overflow_monsters_in_storage() -> void:
	for i in range(6):
		party_handler.add(_make_monster("Party%s" % i))
	var overflow := _make_monster("Overflow")

	party_handler.add(overflow)

	assert_eq(party_handler.party.size(), 6)
	assert_eq(party_handler.storage.find_key(overflow), 0)


func test_deposit_and_withdraw_update_party_and_storage() -> void:
	var mon := _make_monster("StorageMon")
	party_handler.add(mon)

	party_handler.deposit_monster(mon)
	assert_false(party_handler.party.has(mon))
	assert_ne(party_handler.storage.find_key(mon), null)

	party_handler.withdraw_monster(mon)
	assert_true(party_handler.party.has(mon))
	assert_eq(party_handler.storage.find_key(mon), null)


func test_switch_moves_returns_early_on_invalid_indexes() -> void:
	var mon := _make_monster("Mover")
	var move_a := Move.new()
	move_a.name = "A"
	var move_b := Move.new()
	move_b.name = "B"
	mon.moves = [move_a, move_b]
	party_handler.add(mon)

	party_handler.on_switch_moves(mon, -1, 1)

	assert_eq(mon.moves[0], move_a)
	assert_eq(mon.moves[1], move_b)


func _make_monster(monster_name: String) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.primary_type = TypeChart.Type.NONE
	monster.attack = 10
	monster.defense = 10
	monster.special_attack = 10
	monster.special_defense = 10
	monster.speed = 10
	monster.max_hitpoints = 30
	monster.current_hitpoints = 30
	monster.create_stat_multis()
	return monster
