class_name UiBattlePresenter
extends BattlePresenter

var battle_scene: BattleScene3D


func set_battle_scene(scene: BattleScene3D) -> void:
	battle_scene = scene


func show_text(lines: Array[String], auto_complete: bool = false) -> void:
	if battle_scene != null:
		@warning_ignore("redundant_await")
		await battle_scene.show_text(lines, auto_complete)
		return
	Ui.send_text_box.emit(null, lines, auto_complete, false, false)
	await Ui.text_box_complete


func play_move_animation(choice: Choice) -> void:
	if choice.type != Choice.Type.MOVE:
		return
	if battle_scene != null:
		@warning_ignore("redundant_await")
		await battle_scene.play_move_animation(choice)
		return
	var animation = choice.action_or_list.animation
	if animation:
		pass


func play_fx(fx_id: StringName, payload: Dictionary = { }) -> void:
	if battle_scene != null:
		@warning_ignore("redundant_await")
		await battle_scene.play_fx(fx_id, payload)
		return
	# example:
	match fx_id:
		&"hit":
			Battle.send_sprite_shake.emit(payload.get("target"))
		&"throw":
			Battle.send_item_throw_animation.emit(payload.get("item"))
			await Battle.item_animation_complete
		&"wiggle":
			Battle.send_item_wiggle.emit(payload.get("times", 1))
			await Battle.wiggle_animation_complete


func tween_hp(target: Monster, from_hp: int, to_hp: int) -> void:
	if battle_scene != null:
		@warning_ignore("redundant_await")
		await battle_scene.tween_hp(target, from_hp, to_hp)
		return
	Battle.send_hitpoints_change.emit(target, from_hp, to_hp)
	await Battle.hitpoints_animation_complete
