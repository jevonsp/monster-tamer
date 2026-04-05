extends "res://tests/monster_tamer_test.gd"

const TH := preload("res://tests/monster_factory.gd")


func test_single_type_efficacy_lookup() -> void:
	var defender := TH.make_monster("Def", 1, TypeChart.Type.GRASS, null)

	var efficacy := TypeChart.get_attacking_type_efficacy(TypeChart.Type.FIRE, defender)

	assert_eq(efficacy, TypeChart.SUPER_EFFECTIVE)


func test_dual_type_efficacy_multiplies_primary_and_secondary() -> void:
	var defender := TH.make_monster("Def", 1, TypeChart.Type.GRASS, TypeChart.Type.EARTH)

	var efficacy := TypeChart.get_attacking_type_efficacy(TypeChart.Type.FIRE, defender)

	assert_eq(efficacy, 1.0)
