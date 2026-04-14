extends Node
## Saves Data at ~/.local/share/godot/app_userdata/

const MAIN = preload("res://maps/vertical_slice/vertical_slice.tscn")
const TITLE_SCREEN = preload("uid://bwmithvrs81lb")

var loaded_scene: Node2D

@onready var game_root = $"."


func load_level(scene: PackedScene) -> Node2D:
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


func save_game_exists() -> bool:
	return FileAccess.file_exists("user://savegame.tres")


func save_player(saved_game: SavedGame, player: Player) -> SavedGame:
	saved_game.player_position = player.global_position
	saved_game.player_party = player.party.party
	saved_game.player_storage = player.party.storage
	saved_game.player_inventory = player.inventory.inventory
	saved_game.player_money = player.inventory.money
	saved_game.story_flags = player.story_flags.story_flags
	saved_game.player_info = player.info.player_info

	return saved_game


func load_player(saved_game: SavedGame, player: Player):
	player.global_position = saved_game.player_position
	player.party.party = saved_game.player_party
	player.party.storage = saved_game.player_storage
	player.inventory.inventory = saved_game.player_inventory
	player.inventory.money = saved_game.player_money
	player.story_flags.story_flags = saved_game.story_flags
	player.info.player_info = saved_game.player_info
	player.info.update_info()
	NuzlockeTracker.hydrate_from_save(player.info)
	Options.control_scheme = player.info.input_layout
	save_config()


func save_config() -> void:
	var config = ConfigFile.new()

	config.set_value("settings", "control_scheme", Options.control_scheme)
	config.set_value("settings", "is_forgetful_saver", Options.is_forgetful_saver)

	config.set_value("game", "game_variant", Options.game_variant)

	config.save("user://settings.cfg")


func load_config() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		save_config()
	else:
		var cs = config.get_value("settings", "control_scheme", Options.control_scheme)
		if typeof(cs) != TYPE_INT:
			cs = Options.control_scheme
		Options.control_scheme = clampi(int(cs), 0, Options.ControlScheme.size() - 1) as Options.ControlScheme

		var fs = config.get_value("settings", "is_forgetful_saver", Options.is_forgetful_saver)
		Options.is_forgetful_saver = fs if typeof(fs) == TYPE_BOOL else false

		var gv = config.get_value("game", "game_variant", Options.game_variant)
		if typeof(gv) != TYPE_INT:
			gv = Options.game_variant
		Options.game_variant = clampi(int(gv), 0, Options.GameVariant.size() - 1) as Options.GameVariant

	InputRemapper.apply(Options.control_scheme)


func switch_to_title() -> void:
	get_tree().change_scene_to_packed(TITLE_SCREEN)
