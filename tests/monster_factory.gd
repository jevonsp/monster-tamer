## Shared factories for GUT tests (not a GutTest script — keep filename without `test_` prefix).
##
## Leak tracking: Monster and StatusInstance form reference cycles (statuses[] <-> owner).
## RefCounted is freed by refcount only, so cycles survive until exit ("resources still in use").
## cleanup_round() breaks those cycles for monsters created via make_monster().
class_name MonsterFactory
extends RefCounted

static var _created: Array[Monster] = []


static func make_monster(
		name: String = "TestMon",
		level: int = 1,
		primary_type: TypeChart.Type = TypeChart.Type.NONE,
		secondary_type: Variant = null,
		attack: int = 20,
		defense: int = 20,
		special_attack: int = 20,
		special_defense: int = 20,
		speed: int = 20,
		max_hitpoints: int = 80,
		current_hitpoints: int = -1,
		is_player_monster: bool = false,
) -> Monster:
	var hp := max_hitpoints if current_hitpoints < 0 else current_hitpoints
	var m := Monster.new()
	m.name = name
	m.level = level
	m.primary_type = primary_type
	m.secondary_type = secondary_type
	m.attack = attack
	m.defense = defense
	m.special_attack = special_attack
	m.special_defense = special_defense
	m.speed = speed
	m.max_hitpoints = max_hitpoints
	m.current_hitpoints = hp
	m.is_player_monster = is_player_monster
	m.create_stat_multis()
	_created.append(m)
	return m


## Clears owner links and embedded refs so [Monster] instances from [method make_monster] can drop to refcount 0.
static func release_monster_for_test(m: Monster) -> void:
	if m == null:
		return
	m.held_item = null
	m.monster_data = null
	for si in m.statuses.duplicate():
		si.owner = null
	m.statuses.clear()
	m.move_pp.clear()
	m.moves.clear()
	m.stat_stages_and_multis = null


## Call from [method GutTest.after_each] (see [code]monster_tamer_test.gd[/code]) after other teardown.
static func cleanup_round() -> void:
	for m in _created:
		if m != null and is_instance_valid(m):
			release_monster_for_test(m)
	_created.clear()


## Returns [BattleContext, nodes_to_free: Array[Node]]
static func make_battle_context() -> Array:
	var handler := Node.new()
	var battle := Control.new()
	return [BattleContext.new(handler, battle), [handler, battle]]


static func free_if_valid(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.free()
