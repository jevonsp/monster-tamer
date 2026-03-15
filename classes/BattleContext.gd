extends RefCounted
class_name BattleContext

var handler: Node
var battle: Control

func _init(_handler: Node, _battle: Control) -> void:
	handler = _handler
	battle = _battle

# --- Lookups ---------------------------------------------------------------

func get_player_actor() -> Monster:
	return battle.player_actor


func get_enemy_actor() -> Monster:
	return battle.enemy_actor


func get_opponent(of: Monster) -> Monster:
	if of == battle.player_actor:
		return battle.enemy_actor
	if of == battle.enemy_actor:
		return battle.player_actor
	return of


func get_player_party() -> Array:
	return battle.player_party


func get_enemy_party() -> Array:
	return battle.enemy_party

# --- Text helpers ----------------------------------------------------------

func show_text(lines: Array[String], wait_for_close: bool = true) -> void:
	Global.send_text_box.emit(null, lines, not wait_for_close, false, false)
	if wait_for_close:
		await Global.text_box_complete


func show_move_used_text(actor: Monster, move_name: String, target: Monster) -> void:
	var text: Array[String] = ["%s used %s on %s" % [actor.name, move_name, target.name]]
	Global.send_text_box.emit(null, text, true, false, false)
	await Global.text_box_complete


func show_move_result_text(lines: Array[String]) -> void:
	Global.send_text_box.emit(null, lines, false, false, false)
	await Global.text_box_complete


func show_item_used_text(item: Item, _actor: Monster, target: Monster) -> void:
	var text: Array[String] = ["Used a %s on %s" % [item.name, target.name]]
	Global.send_text_box.emit(null, text, true, false, false)
	await Global.text_box_complete


func show_capture_result_text(lines: Array[String]) -> void:
	Global.send_text_box.emit(null, lines, false, false, false)
	await Global.text_box_complete

# --- Animation helpers -----------------------------------------------------

func play_move_animation(animation_scene: PackedScene) -> void:
	if animation_scene == null:
		return
	Global.send_move_animation.emit(animation_scene)
	await Global.move_animation_complete


func play_hit_reaction(target: Monster) -> void:
	Global.send_sprite_shake.emit(target)


func play_switch_out(old_monster: Monster) -> void:
	Global.send_monster_switch_out.emit(old_monster)
	await Global.monster_switch_out_animation_complete


func play_switch_in(new_monster: Monster) -> void:
	Global.send_monster_switch_in.emit(new_monster)


func play_item_throw(item: Item) -> void:
	Global.send_item_throw_animation.emit(item)
	await Global.item_animation_complete


func play_ball_wiggle(times: int) -> void:
	Global.send_item_wiggle.emit(times)
	await Global.wiggle_animation_complete


func play_capture_animation(target: Monster) -> void:
	Global.send_capture_animation.emit()
	Global.capture_monster.emit(target)
	await Global.capture_or_escape_animation_complete


func play_escape_animation() -> void:
	Global.send_escape_animation.emit()
	await Global.capture_or_escape_animation_complete

# --- Battle flow helpers ---------------------------------------------------

func perform_switch(old_monster: Monster, new_monster: Monster, out_text: String, in_text: String) -> void:
	if old_monster.is_able_to_fight:
		var t_out: Array[String] = [out_text % [old_monster.name]]
		Global.send_text_box.emit(null, t_out, true, false, false)
		await Global.text_box_complete
		
	await play_switch_out(old_monster)
	
	Global.switch_monster_to_first.emit(new_monster)
	Global.switch_battle_actors.emit(old_monster, new_monster)
	
	play_switch_in(new_monster)
	
	var t_in: Array[String] = [in_text % [new_monster.name]]
	Global.send_text_box.emit(null, t_in, false, false, false)
	await Global.text_box_complete


func handle_capture_success(target: Monster) -> void:
	target.is_captured = true
	await play_capture_animation(target)


func handle_capture_failure() -> void:
	await play_escape_animation()
