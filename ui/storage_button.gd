extends Button
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel


func update(target) -> void:
	if target == null:
		clear_monster()
	else:
		display_monster(target)


func clear_monster() -> void:
	name_label.text = ""
	texture_rect.texture = null
	level_label.text = ""


func display_monster(monster: Monster) -> void:
	name_label.text = monster.name
	texture_rect.texture = monster.monster_data.texture
	level_label.text = "Lvl. %s" % monster.level
