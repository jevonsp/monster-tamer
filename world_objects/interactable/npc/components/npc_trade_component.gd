class_name NPCTradeComponent
extends NPCComponent

@export var monster_to_take: MonsterData
@export var monster_to_give: MonsterData


func trigger(obj: Node) -> void:
	if monster_to_take == null or monster_to_give == null:
		return
		
	var party: Array[Monster] = obj.party_handler.party
	var ta: Array[String]
	var monster_in_party: Monster = null
	
	for monster: Monster in party:
		if monster.monster_data == monster_to_take:
			monster_in_party = monster
			break
	
	if monster_in_party == null:
		ta = ["You dont have the %s I'm looking for. Come back when you have it!" % [monster_to_take.species]]
		Global.send_text_box.emit(null, ta, false, false, true)
		await Global.text_box_complete
		return
	
	party.erase(monster_in_party)
	obj.party_handler.add(monster_to_give)
	
	ta = ["Bye %s! I'll take good care of %s." % [monster_to_give.species, monster_to_take.species]]
	Global.send_text_box.emit(null, ta, false, false, true)
	await Global.text_box_complete
