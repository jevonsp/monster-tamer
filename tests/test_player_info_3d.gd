extends "res://tests/monster_tamer_test.gd"

const _Player3DScene := preload("res://3d_migration/character_3d/player_3d/player_3d.tscn")

var player: Player3D
var info: PlayerInfo3D


func before_each() -> void:
	player = _Player3DScene.instantiate() as Player3D
	add_child_autofree(player)
	info = player.get_node("PlayerInfoHandler") as PlayerInfo3D


func after_each() -> void:
	player = null
	info = null
	super.after_each()


func test_respawn_point_vector2_sets_player_respawn_xz() -> void:
	await get_tree().process_frame
	info.respawn_point = Vector2(12.0, 34.0)
	var expected := Vector3(12.0, player.global_position.y, 34.0)
	assert_eq(player.respawn_point, expected)
	assert_eq(info.player_info["respawn_point"], Vector2(12.0, 34.0))


func test_is_sidescrolling_routes_to_travel_handler() -> void:
	await get_tree().process_frame
	assert_true(is_instance_valid(info.travel_handler))
	info.is_sidescrolling = true
	assert_true(info.travel_handler.is_sidescrolling)
	info.is_sidescrolling = false
	assert_false(info.travel_handler.is_sidescrolling)


func test_update_info_applies_dictionary_fields() -> void:
	await get_tree().process_frame
	info.player_info = {
		"player_name": "Test3D",
		"play_time": 42,
	}
	info.update_info()
	assert_eq(info.player_name, "Test3D")
	assert_eq(info.play_time, 42)
