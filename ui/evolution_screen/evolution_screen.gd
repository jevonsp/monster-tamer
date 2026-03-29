extends Control

const PISTOL_SHRIMP_MD = preload("uid://cdor45ba2o0aa")
const AKIMBO_SHRIMP_MD = preload("uid://b0531qwrotpbx")

@onready var old_texture_rect: TextureRect = $OldTextureRect
@onready var new_texture_rect: TextureRect = $NewTextureRect


func _ready() -> void:
	var monster: Monster = PISTOL_SHRIMP_MD.set_up(1)
	var entry_list: EntryList = EvolutionHandler.evolution_table.table[PISTOL_SHRIMP_MD]
	var entry = entry_list.list[0]

	_set_up_screen(monster, entry)
	_animate_evolution()


func _set_up_screen(monster: Monster, entry: Entry) -> void:
	old_texture_rect.texture = monster.monster_data.texture
	new_texture_rect.texture = entry.finish_monster.texture

	new_texture_rect.modulate = Color.TRANSPARENT


func _animate_evolution() -> void:
	var time := 1.5
	var count := 0

	while count < 15:
		var is_toward_new := count % 2 == 0
		await _crossfade(is_toward_new, time)
		count += 1
		time *= .75


## Fades old and new together so both contribute mid-transition (true crossfade).
func _crossfade(show_new_monster: bool, duration: float) -> void:
	var old_target := Color.TRANSPARENT if show_new_monster else Color.WHITE
	var new_target := Color.WHITE if show_new_monster else Color.TRANSPARENT
	var tween = get_tree().create_tween()
	tween.tween_property(old_texture_rect, "modulate", old_target, duration).set_trans(
		Tween.TRANS_SINE,
	).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(new_texture_rect, "modulate", new_target, duration).set_trans(
		Tween.TRANS_SINE,
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
