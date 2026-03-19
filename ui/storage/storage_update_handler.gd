extends Node

@onready var party_container: HBoxContainer = \
		$"../MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/Party"
@onready var grid_container: GridContainer = \
		$"../MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/GridContainer"
@onready var parent: Control = $".."


func display_monsters() -> void:
	update_party(parent.party_ref)
	update_storage(parent.storage_ref, parent.page_index)


func update_party(party: Array) -> void:
	for i in range(parent.PARTY_SLOT_COUNT):
		party_container.get_child(i).clear_monster()
	if parent.party_ref:
		for i in range(len(party)):
			party_container.get_child(i).update(party[i])


func update_storage(storage: Dictionary, page_index: int) -> void:
	for i in range(parent.STORAGE_SLOTS_PER_PAGE):
		grid_container.get_child(i).clear_monster()
	if parent.storage_ref:
		for i in range(parent.STORAGE_SLOTS_PER_PAGE):
			grid_container.get_child(i).update(storage[i + parent.STORAGE_SLOTS_PER_PAGE * page_index])
