extends Node

const ActionQueueBuilder = preload("res://battle/action_queue_builder.gd")

@onready var battle: Control = $".."
@onready var post_action_resolver: Node = $"../PostActionResolver"
@onready var turn_executor: Node = $"../TurnExecutor"
var turn_queue: Array[Dictionary] = []
var executing_turn: bool = false
var action_queue_builder := ActionQueueBuilder.new()
var is_escaped: bool = false


func _ready() -> void:
	Battle.add_item_to_turn_queue.connect(execute_player_turn)
	Battle.add_switch_to_turn_queue.connect(execute_player_turn)
	Battle.request_battle_level_up_resolution.connect(_on_request_battle_level_up_resolution)


func execute_player_turn(action) -> void:
	if executing_turn or not battle.processing:
		return
	if action_queue_builder.add_action_to_queue(action, battle.player_actor, battle, turn_queue):
		battle.processing = false
		executing_turn = true
		battle.visibility_focus_handler.manage_focus()
		action_queue_builder.queue_enemy_action(battle, turn_queue)
		var battle_ended: bool = await turn_executor.execute_turn_queue(
			self,
			turn_queue,
			post_action_resolver,
		)
		if not battle_ended:
			_reset_turn_state()


func attempt_run() -> void:
	if executing_turn or not battle.processing:
		return
	var action = Run.new()
	execute_player_turn(action)


func _reset_turn_state() -> void:
	turn_queue.clear()
	battle.processing = true
	executing_turn = false
	battle.visibility_focus_handler.manage_focus()


func _on_request_battle_level_up_resolution(monster: Monster, amount: int) -> void:
	await post_action_resolver.resolve_level_up(monster, amount)
