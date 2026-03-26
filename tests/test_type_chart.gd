extends GutTest


func test_single_type_efficacy_lookup() -> void:
	var defender := _make_monster(TypeChart.Type.GRASS, null)

	var efficacy := TypeChart.get_attacking_type_efficacy(TypeChart.Type.FIRE, defender)

	assert_eq(efficacy, TypeChart.SUPER_EFFECTIVE)


func test_dual_type_efficacy_multiplies_primary_and_secondary() -> void:
	var defender := _make_monster(TypeChart.Type.GRASS, TypeChart.Type.EARTH)

	var efficacy := TypeChart.get_attacking_type_efficacy(TypeChart.Type.FIRE, defender)

	assert_eq(efficacy, 1.0)


func _make_monster(primary: TypeChart.Type, secondary) -> Monster:
	var monster := Monster.new()
	monster.primary_type = primary
	monster.secondary_type = secondary
	monster.create_stat_multis()
	return monster
