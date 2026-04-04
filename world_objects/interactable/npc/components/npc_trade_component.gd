class_name NPCTradeComponent
extends NPCComponent

@export var monster_to_take: MonsterData
@export var monster_to_give: MonsterData


func trigger(obj: Node) -> NPCComponent.Result:
	if monster_to_take == null or monster_to_give == null:
		return NPCComponent.Result.CONTINUE

	var party: Array[Monster] = obj.party_handler.party
	var ta: Array[String]
	var monster_in_party: Monster = null

	for monster: Monster in party:
		if monster.monster_data == monster_to_take:
			monster_in_party = monster
			break

	if monster_in_party == null:
		ta = ["You dont have the %s I'm looking for. Come back when you have it!" % [monster_to_take.species]]
		Ui.send_text_box.emit(null, ta, false, false, true)
		await Ui.text_box_complete
		return NPCComponent.Result.CONTINUE

	party.erase(monster_in_party)
	var received: Monster = monster_to_give.set_up(monster_in_party.level)
	obj.party_handler.add(received)

	ta = ["Bye %s! I'll take good care of %s." % [monster_to_give.species, monster_to_take.species]]
	Ui.send_text_box.emit(null, ta, false, false, true)
	await Ui.text_box_complete
	return NPCComponent.Result.CONTINUE
