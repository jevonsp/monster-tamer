extends Node

@onready var battle: Control = $".."


func force_player_send_new_monster(handler: Node) -> void:
	Global.request_forced_switch.emit()
	var target = await Global.send_selected_force_switch

	var switch = Switch.new()
	switch.actor = battle.player_actor
	switch.target = target

	var battle_context = BattleContext.new(handler, battle)
	await switch.execute(switch.actor, switch.target, battle_context)


func force_enemy_send_new_monster(handler: Node) -> void:
	var available_monsters: Array[Monster] = []
	for monster: Monster in battle.enemy_party:
		if monster.is_able_to_fight:
			available_monsters.append(monster)

	var next_monster = available_monsters.pick_random()

	var switch = Switch.new()
	switch.actor = battle.enemy_actor
	switch.target = next_monster
	switch.out_unformatted = "Enemy %s withdrew %%s." % [battle.enemy_trainer.npc_name]
	switch.in_unformatted = "Enemy %s sent out %%s." % [battle.enemy_trainer.npc_name]

	var battle_context = BattleContext.new(handler, battle)
	await switch.execute(switch.actor, switch.target, battle_context)
