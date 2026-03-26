extends GutTest


func test_calculate_damage_applies_stab_and_type_efficacy() -> void:
	var effect := DamageEffect.new()
	effect.type = TypeChart.Type.FIRE
	effect.base_power = 50
	effect.damage_type = DamageEffect.DamageType.PHYSICAL
	var actor := _make_monster("Attacker")
	actor.primary_type = TypeChart.Type.FIRE
	var target := _make_monster("Target")
	target.primary_type = TypeChart.Type.GRASS

	var damage: int = effect.calculate_damage(actor, target)

	assert_gt(damage, 20)


func test_calculate_damage_applies_held_item_flat_and_percentage_modifiers() -> void:
	var effect := DamageEffect.new()
	effect.type = TypeChart.Type.NONE
	effect.base_power = 40
	var actor := _make_monster("Attacker")
	var target := _make_monster("Target")

	var attacker_item := Item.new()
	var attacker_held := HeldEffect.new()
	attacker_held.effect_type = HeldEffect.EffectType.TYPE_BOOST
	attacker_held.boost_type = HeldEffect.BoostType.FLAT
	attacker_held.flat_boost_amount = 10
	attacker_item.held_effect = attacker_held
	actor.held_item = attacker_item

	var defender_item := Item.new()
	var defender_held := HeldEffect.new()
	defender_held.effect_type = HeldEffect.EffectType.TYPE_BOOST
	defender_held.boost_type = HeldEffect.BoostType.PERCENTAGE
	defender_held.percentage_boost_amount = 2.0
	defender_item.held_effect = defender_held
	target.held_item = defender_item

	var damage: int = effect.calculate_damage(actor, target)

	assert_gt(damage, 0)
	assert_lt(damage, 20)


func test_calculate_critical_is_true_at_max_critical_stage() -> void:
	var effect := DamageEffect.new()
	var actor := _make_monster("Critter")
	actor.stat_stages_and_multis.stat_stages[Monster.Stat.CRITICAL] = 4

	assert_true(effect.calculate_critical(actor))


func _make_monster(monster_name: String) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.level = 20
	monster.primary_type = TypeChart.Type.NONE
	monster.secondary_type = null
	monster.attack = 40
	monster.defense = 30
	monster.special_attack = 40
	monster.special_defense = 30
	monster.speed = 20
	monster.max_hitpoints = 120
	monster.current_hitpoints = 120
	monster.create_stat_multis()
	return monster
