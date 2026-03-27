extends Node
## Path Info
## https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html
## ~/.local/share/godot/app_userdata/

const MAIN = preload("res://main/main.tscn")

var loaded_scene: Node2D

@onready var game_root = $"."


func load_level(scene: PackedScene) -> void:
	var new_scene = scene.instantiate()
	set_loaded_level(new_scene)
	toggle_visible()
	game_root.add_child(new_scene)


func set_loaded_level(node: Node) -> void:
	loaded_scene = node


func toggle_visible() -> void:
	loaded_scene.visible = not loaded_scene.visible


func save_game() -> void:
	var saved_game: SavedGame = SavedGame.new()

	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		saved_game = save_player(saved_game, player)

	var saved_data_array: Array[SavedData] = []
	get_tree().call_group("save_object", "on_save_game", saved_data_array)
	saved_game.saved_data_array = saved_data_array

	ResourceSaver.save(saved_game, "user://savegame.tres")


func load_game() -> void:
	var saved_game: SavedGame = ResourceLoader.load("user://savegame.tres") as SavedGame

	var player = get_tree().get_first_node_in_group("player")
	if player:
		load_player(saved_game, player)

	get_tree().call_group("save_object", "on_before_load_game")
	get_tree().call_group("save_object", "on_load_game", saved_game.saved_data_array)


func erase_saved_game() -> bool:
	if FileAccess.file_exists("user://savegame.tres"):
		DirAccess.remove_absolute("user://savegame.tres")
		return true
	return false


func save_player(saved_game: SavedGame, player: Player) -> SavedGame:
	saved_game.player_position = player.global_position
	saved_game.player_party = player.party_handler.party
	saved_game.player_storage = player.party_handler.storage
	saved_game.player_inventory = player.inventory_handler.inventory
	saved_game.player_money = player.inventory_handler.money
	saved_game.story_flags = player.story_flag_handler.story_flags

	return saved_game


func load_player(saved_game: SavedGame, player: Player):
	player.global_position = saved_game.player_position
	player.party_handler.party = saved_game.player_party
	player.party_handler.storage = saved_game.player_storage
	player.inventory_handler.inventory = saved_game.player_inventory
	player.inventory_handler.money = saved_game.player_money
	player.story_flag_handler.story_flags = saved_game.story_flags
