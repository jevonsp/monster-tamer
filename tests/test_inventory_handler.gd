extends "res://tests/monster_tamer_test.gd"

const InventoryHandlerScript := preload("res://player/inventory_handler.gd")
const TH := preload("res://tests/monster_factory.gd")

var inventory_handler: Node


func before_each() -> void:
	inventory_handler = InventoryHandlerScript.new()
	inventory_handler.construct_inventory()


func after_each() -> void:
	_disconnect_heal_signal()
	if is_instance_valid(inventory_handler):
		inventory_handler.free()
	inventory_handler = null
	super.after_each()


func test_add_and_remove_updates_item_stack_counts() -> void:
	var potion := Item.new()
	potion.item_type = Item.Type.USE

	inventory_handler.add(potion, 3)
	assert_eq(inventory_handler.inventory[Item.Type.USE].page[potion], 3)

	inventory_handler.remove(potion, 2)
	assert_eq(inventory_handler.inventory[Item.Type.USE].page[potion], 1)


func test_remove_erases_item_at_zero_count() -> void:
	var potion := Item.new()
	potion.item_type = Item.Type.USE
	inventory_handler.add(potion, 1)

	inventory_handler.remove(potion, 1)

	assert_false(inventory_handler.inventory[Item.Type.USE].page.has(potion))


func test_on_use_item_on_consumes_non_multi_use_item() -> void:
	var item := Item.new()
	item.item_type = Item.Type.USE
	item.is_multi_use = false
	item.use_effect = HealingEffect.new()
	var monster := TH.make_monster("PartyMon", 1, TypeChart.Type.NONE, null, 10, 10, 10, 10, 10, 50)
	monster.current_hitpoints = 10
	inventory_handler.add(item, 1)
	_connect_heal_signal()

	await inventory_handler.on_use_item_on(item, monster)

	assert_false(inventory_handler.inventory[Item.Type.USE].page.has(item))
	_disconnect_heal_signal()


func _connect_heal_signal() -> void:
	if not Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.connect(_on_send_hitpoints_change)
	if not Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.connect(_on_send_text_box)


func _disconnect_heal_signal() -> void:
	if Battle.send_hitpoints_change.is_connected(_on_send_hitpoints_change):
		Battle.send_hitpoints_change.disconnect(_on_send_hitpoints_change)
	if Ui.send_text_box.is_connected(_on_send_text_box):
		Ui.send_text_box.disconnect(_on_send_text_box)


func _on_send_hitpoints_change(_target: Monster, _hp: int) -> void:
	call_deferred("_emit_hitpoints_animation_complete")


func _on_send_text_box(
	_object,
	_text: Array[String],
	_auto_complete: bool,
	_is_question: bool,
	_toggles_player: bool
) -> void:
	call_deferred("_emit_text_box_complete")


func _emit_hitpoints_animation_complete() -> void:
	Battle.hitpoints_animation_complete.emit()


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()
