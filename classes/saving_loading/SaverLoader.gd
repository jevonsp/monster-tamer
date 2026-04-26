extends Node
## Saves Data at ~/.local/share/godot/app_userdata/

const MAIN = preload("res://main/main.tscn")
const TITLE_SCREEN = preload("uid://bwmithvrs81lb")

var loaded_scene: Node

@onready var game_root = $"."


func load_level(scene: PackedScene) -> Node:
	var new_scene = scene.instantiate()
	set_loaded_level(new_scene)
	toggle_visible()
	game_root.add_child(new_scene)
	return new_scene


func set_loaded_level(node: Node) -> void:
	loaded_scene = node


func toggle_visible() -> void:
	loaded_scene.visible = not loaded_scene.visible


func save_game() -> void:
	var saved_game: SavedGame = SavedGame.new()

	var player: Player3D = PlayerContext3D.player
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


func save_game_exists() -> bool:
	return FileAccess.file_exists("user://savegame.tres")


func save_player(saved_game: SavedGame, player: Player3D) -> SavedGame:
	saved_game.player_position = player.global_position
	saved_game.player_party = player.party_handler.party
	saved_game.player_storage = player.party_handler.storage
	saved_game.player_inventory = player.inventory_handler.inventory
	saved_game.player_money = player.inventory_handler.money
	saved_game.story_flags = player.story_flag_handler.story_flags

	saved_game.player_info = player.player_info_handler.player_info
	saved_game.travel_info = player.travel_handler.get_travel_dictionary()

	return saved_game


func load_player(saved_game: SavedGame, player: Player3D):
	player.global_position = saved_game.player_position
	player.party_handler.party = saved_game.player_party
	player.party_handler.storage = saved_game.player_storage
	player.inventory_handler.inventory = saved_game.player_inventory
	player.inventory_handler.money = saved_game.player_money
	player.story_flag_handler.story_flags = saved_game.story_flags
	player.player_info_handler.player_info = saved_game.player_info

	player.player_info_handler.update_info()
	player.travel_handler.set_travel_info(saved_game.travel_info)

	NuzlockeTracker.hydrate_from_save()
	GameOptions.control_scheme = player.info.input_layout
	save_config()


func save_config() -> void:
	var config = ConfigFile.new()

	config.set_value("settings", "control_scheme", GameOptions.control_scheme)
	config.set_value("settings", "is_forgetful_saver", GameOptions.is_forgetful_saver)

	config.set_value("game", "game_variant", GameOptions.game_variant)

	config.save("user://settings.cfg")


func load_config() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		save_config()
	else:
		var cs = config.get_value("settings", "control_scheme", GameOptions.control_scheme)
		if typeof(cs) != TYPE_INT:
			cs = GameOptions.control_scheme
		GameOptions.control_scheme = clampi(int(cs), 0, GameOptions.ControlScheme.size() - 1) as GameOptions.ControlScheme

		var fs = config.get_value("settings", "is_forgetful_saver", GameOptions.is_forgetful_saver)
		GameOptions.is_forgetful_saver = fs if typeof(fs) == TYPE_BOOL else false

		var gv = config.get_value("game", "game_variant", GameOptions.game_variant)
		if typeof(gv) != TYPE_INT:
			gv = GameOptions.game_variant
		GameOptions.game_variant = clampi(int(gv), 0, GameOptions.GameVariant.size() - 1) as GameOptions.GameVariant

	InputRemapper.apply(GameOptions.control_scheme)


func switch_to_title() -> void:
	get_tree().change_scene_to_packed(TITLE_SCREEN)
