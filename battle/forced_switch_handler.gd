extends Node
@onready var battle: Control = $".."


func force_player_send_new_monster(handler: Node) -> void:
	print_debug("BATTLE: force_player_send_new_monster begin")
	Global.request_forced_switch.emit()
	print_debug("BATTLE: waiting for send_selected_force_switch")
	var target = await Global.send_selected_force_switch
	print_debug("BATTLE: received forced switch target=%s" % [target.name if target else "null"])

	var switch = Switch.new()
	switch.actor = battle.player_actor
	switch.target = target

	var battle_context = BattleContext.new(handler, battle)
	print_debug(
		"BATTLE: executing forced player switch actor=%s target=%s"
		% [switch.actor.name, switch.target.name]
	)
	await switch.execute(switch.actor, switch.target, battle_context)
	print_debug("BATTLE: forced player switch complete")


func force_enemy_send_new_monster(handler: Node) -> void:
	var available_monsters: Array[Monster] = []
	for monster: Monster in battle.enemy_party:
		if monster.is_able_to_fight:
			available_monsters.append(monster)

	var next_monster = available_monsters.pick_random()
	print_debug(
		"BATTLE: enemy force switch available=%s picked=%s"
		% [available_monsters.size(), next_monster.name if next_monster else "null"]
	)

	var switch = Switch.new()
	switch.actor = battle.enemy_actor
	switch.target = next_monster
	switch.out_unformatted = "Enemy %s withdrew %%s." % [battle.enemy_trainer.npc_name]
	switch.in_unformatted = "Enemy %s sent out %%s." % [battle.enemy_trainer.npc_name]

	var battle_context = BattleContext.new(handler, battle)
	print_debug(
		"BATTLE: executing forced enemy switch actor=%s target=%s"
		% [switch.actor.name, switch.target.name]
	)
	await switch.execute(switch.actor, switch.target, battle_context)
	print_debug("BATTLE: forced enemy switch complete")
