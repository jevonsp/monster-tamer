class_name BattleContext
extends RefCounted

var handler: Node
var battle: Control


func _init(battle_handler: Node, battle_control: Control) -> void:
	handler = battle_handler
	battle = battle_control


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


func get_player_party() -> Array[Monster]:
	return battle.player_party


func get_enemy_party() -> Array[Monster]:
	return battle.enemy_party


func show_text(lines: Array[String], wait_for_close: bool = true) -> void:
	Ui.send_text_box.emit(null, lines, not wait_for_close, false, false)
	if wait_for_close:
		await Ui.text_box_complete


func show_move_used_text(actor: Monster, move_name: String, target: Monster) -> void:
	var text: Array[String] = ["%s used %s on %s" % [actor.name, move_name, target.name]]
	Ui.send_text_box.emit(null, text, true, false, false)
	await Ui.text_box_complete


func show_move_result_text(lines: Array[String]) -> void:
	Ui.send_text_box.emit(null, lines, false, false, false)
	await Ui.text_box_complete


func show_item_used_text(item: Item, _actor: Monster, target: Monster) -> void:
	var text: Array[String] = ["Used a %s on %s" % [item.name, target.name]]
	Ui.send_text_box.emit(null, text, true, false, false)
	await Ui.text_box_complete


func show_capture_result_text(lines: Array[String]) -> void:
	Ui.send_text_box.emit(null, lines, false, false, false)
	await Ui.text_box_complete


func play_move_animation(animation_scene: PackedScene) -> void:
	if animation_scene == null:
		return
	Battle.send_move_animation.emit(animation_scene)
	await Battle.move_animation_complete


func play_hit_reaction(target: Monster) -> void:
	Battle.send_sprite_shake.emit(target)


func play_switch_out(old_monster: Monster) -> void:
	Battle.send_monster_switch_out.emit(old_monster)
	await Battle.monster_switch_out_animation_complete


func play_switch_in(new_monster: Monster) -> void:
	Battle.send_monster_switch_in.emit(new_monster)


func play_item_throw(item: Item) -> void:
	Battle.send_item_throw_animation.emit(item)
	await Battle.item_animation_complete


func play_ball_wiggle(times: int) -> void:
	Battle.send_item_wiggle.emit(times)
	await Battle.wiggle_animation_complete


func play_capture_animation() -> void:
	Battle.send_capture_animation.emit()
	await Battle.capture_or_escape_animation_complete


func play_escape_animation() -> void:
	Battle.send_escape_animation.emit()
	await Battle.capture_or_escape_animation_complete


func play_stat_animation(monster: Monster, stat: Monster.Stat, amount: int) -> void:
	Battle.send_stat_change_animation.emit(monster, stat, amount)
	await Battle.stat_change_animation_complete


func perform_switch(
		old_monster: Monster,
		new_monster: Monster,
		out_text: String,
		in_text: String,
) -> void:
	if old_monster.is_able_to_fight:
		var t_out: Array[String] = [out_text % [old_monster.name]]
		Ui.send_text_box.emit(null, t_out, true, false, false)
		await Ui.text_box_complete

	await play_switch_out(old_monster)

	Battle.switch_monster_to_first.emit(new_monster)
	Battle.switch_battle_actors.emit(old_monster, new_monster)

	play_switch_in(new_monster)

	var t_in: Array[String] = [in_text % [new_monster.name]]
	Ui.send_text_box.emit(null, t_in, false, false, false)
	await Ui.text_box_complete


func handle_capture_success(target: Monster) -> void:
	target.is_captured = true
	await play_capture_animation()


func handle_capture_failure() -> void:
	await play_escape_animation()
