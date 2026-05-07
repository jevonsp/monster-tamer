extends Button

var actor: Monster = null

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel


func update(target) -> void:
	if target == null:
		clear_monster()
	else:
		display_monster(target)


func clear_monster() -> void:
	actor = null
	name_label.text = ""
	texture_rect.texture = null
	level_label.text = ""


func display_monster(monster: Monster) -> void:
	actor = monster
	name_label.text = monster.name
	if actor.is_shiny:
		texture_rect.texture = monster.monster_data.shiny_front_texture
	else:
		texture_rect.texture = monster.monster_data.base_front_texture
	level_label.text = "Lvl. %s" % monster.level
