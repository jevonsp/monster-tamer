extends Node

# gdlint:ignore-file:god-class-signals
@warning_ignore_start("unused_signal")
signal toggle_in_battle
signal battle_started
signal wild_battle_requested(mon_data: MonsterData, level: int)
signal trainer_battle_requested(trainer: Trainer3D)
#signal add_switch_to_turn_queue(switch: Switch)
signal switch_monster_to_first(monster: Monster)
signal battle_ended(enemy_trainer: Trainer3D)
signal send_item_throw_animation(item: Item)
signal item_animation_complete
signal send_item_wiggle(times: int)
signal wiggle_animation_complete
signal send_sprite_hit(target: Monster)
signal send_hitpoints_change(target: Monster, from_hp: int, to_hp: int)
signal hitpoints_animation_complete
signal send_monster_death_experience(amount: int)
signal monster_gained_experience(target: Monster, amount: int)
signal experience_animation_complete
signal player_done_giving_exp
signal monster_gained_level(target: Monster, amount: int)
signal request_forced_switch
signal request_display_monsters

@warning_ignore_restore("unused_signal")
var chassis: BattleChassis
var presenter: BattlePresenter


func _ready() -> void:
	presenter = UiBattlePresenter.new()
	chassis = BattleChassis.new()


func attach_chassis(value: BattleChassis) -> void:
	chassis = value


func set_battle_scene(scene: BattleScene3D = null) -> void:
	if presenter is UiBattlePresenter:
		(presenter as UiBattlePresenter).set_battle_scene(scene)
	if scene != null:
		scene.set_battle_chassis(chassis)


func enqueue_item_choice(item: Item) -> void:
	if item == null or item.actions == null:
		return
	_ensure_chassis()
	var actor := resolve_player_actor()
	if actor == null:
		return
	var choice := Choice.new()
	choice.type = Choice.Type.ITEM
	choice.actor = actor
	choice.targets = _resolve_default_targets()
	choice.action_or_list = item
	chassis.turn_queue.append(choice)


func enqueue_move_choice(move: Move) -> void:
	if move == null or move.action_list == null:
		return
	_ensure_chassis()
	var actor := resolve_player_actor()
	if actor == null:
		return
	var choice := Choice.new()
	choice.type = Choice.Type.MOVE
	choice.actor = actor
	choice.targets = _resolve_default_targets()
	choice.action_or_list = move
	chassis.turn_queue.append(choice)
	@warning_ignore("redundant_await")
	await chassis.advance_turn()


func enqueue_enemy_move_choice() -> void:
	var enemy := resolve_enemy_actor()
	if enemy == null or enemy.is_fainted:
		return
	var player := resolve_player_actor()
	if player == null:
		return
	var picker := EnemyMovePicker.new(enemy)
	var move := picker.pick_move()
	if move == null:
		return
	var choice := Choice.new()
	choice.type = Choice.Type.MOVE
	choice.actor = enemy
	choice.targets = [player]
	choice.action_or_list = move
	chassis.turn_queue.append(choice)


func submit_forced_switch(target: Monster) -> void:
	if target == null:
		return
	switch_monster_to_first.emit(target)


func resolve_queued_turn() -> void:
	if chassis == null or chassis.turn_queue.is_empty() or presenter == null:
		return
	await chassis.resolve_turn(presenter)
	chassis.turn_queue.clear()
	chassis.turn_index = 0


func resolve_player_actor() -> Monster:
	var handler: PartyHandler3D = null
	if PlayerContext3D.party_handler != null:
		handler = PlayerContext3D.party_handler
	elif PlayerContext3D.player != null and PlayerContext3D.player.party_handler != null:
		handler = PlayerContext3D.player.party_handler
	if handler == null:
		return null
	var party: Array[Monster] = handler.party
	for m: Monster in party:
		if m != null and not m.is_fainted:
			return m
	return null


func resolve_enemy_actor() -> Monster:
	if chassis == null:
		return null
	return chassis.enemy_actors.get(0, null)


func _resolve_default_targets() -> Array[Monster]:
	if chassis == null:
		return []
	var enemy: Monster = chassis.enemy_actors.get(0, null)
	if enemy != null and not enemy.is_fainted:
		return [enemy]
	return []


func _ensure_chassis() -> void:
	if chassis == null:
		chassis = BattleChassis.new()
	var handler: PartyHandler3D = null
	if PlayerContext3D.party_handler != null:
		handler = PlayerContext3D.party_handler
	elif PlayerContext3D.player != null and PlayerContext3D.player.party_handler != null:
		handler = PlayerContext3D.player.party_handler
	if handler == null:
		return
	chassis.player_team = handler.party
