extends Node
@onready var battle: Control = $".."

func _display_current_monsters() -> void:
	"""Main entry point for displaying new monsters"""
	_update_labels()
	_update_textures()
	_update_bars()
	_update_moves()

func _update_labels() -> void:
	battle.player_labels["level"].text = "Lvl. %s" % battle.player_actor.level
	battle.player_labels["name"].text = battle.player_actor.name
	battle.player_labels["level"].actor = battle.player_actor
	battle.player_labels["level"].label_level = battle.player_actor.level
	
	battle.enemy_labels["level"].text = "Lvl. %s" % battle.enemy_actor.level
	battle.enemy_labels["name"].text = battle.enemy_actor.name

func _update_textures() -> void:
	battle.player_display["texture"].texture = battle.player_actor.monster_data.texture
	battle.player_display["texture"].player_actor = battle.player_actor
	
	battle.enemy_display["texture"].texture = battle.enemy_actor.monster_data.texture
	battle.enemy_display["texture"].enemy_actor = battle.enemy_actor

func _update_bars() -> void:
	"""Call only on new player_actor"""
	battle.player_display["hp_bar"].max_value = battle.player_actor.max_hitpoints
	battle.player_display["hp_bar"].value = battle.player_actor.current_hitpoints
	battle.player_display["hp_bar"].actor = battle.player_actor
	
	battle.enemy_display["hp_bar"].max_value = battle.enemy_actor.max_hitpoints
	battle.enemy_display["hp_bar"].value = battle.enemy_actor.current_hitpoints
	battle.enemy_display["hp_bar"].actor = battle.enemy_actor
	
	var min_exp: int = Monster.EXPERIENCE_PER_LEVEL * (battle.player_actor.level - 1)
	var max_exp: int = Monster.EXPERIENCE_PER_LEVEL * battle.player_actor.level
	
	battle.player_display["exp_bar"].max_value = max_exp
	battle.player_display["exp_bar"].min_value = min_exp
	battle.player_display["exp_bar"].value = battle.player_actor.experience
	battle.player_display["exp_bar"].actor = battle.player_actor

func _clear_actor_references() -> void:
	battle.player_labels["level"].actor = null
	battle.player_display["texture"].player_actor = null
	battle.enemy_display["texture"].enemy_actor = null
	battle.player_display["hp_bar"].actor = null
	battle.enemy_display["hp_bar"].actor = null
	battle.player_display["exp_bar"].actor = null

func _clear_textures() -> void:
	battle.player_display["texture"].texture = null
	battle.enemy_display["texture"].texture = null

func _update_moves() -> void:
	for i in battle.player_actor.moves.size():
		if battle.player_actor.moves[i] != null:
			battle.move_labels[i].text = battle.player_actor.moves[i].name
