class_name SurfObject
extends Area2D

enum State { NOT_PASSABLE, PASSABLE }

@export var state: State = State.NOT_PASSABLE

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	pass


func interact(body: Player) -> void:
	var ta: Array[String]
	if body.available_travel_methods[Player.TravelState.SURFING] != true:
		ta = ["If you had a Monster strong enough, you could surf here!"]
		Ui.send_text_box.emit(null, ta, false, false, true)
		await Ui.text_box_complete
		return

	ta = ["Would you like to surf?"]
	Ui.send_text_box.emit(self, ta, false, true, false)
	var answer = await Ui.answer_given
	if answer:
		print("yes")
		await body.start_surfing()


func toggle_mode(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state

	print("state: ", State.keys()[state])

	match state:
		State.NOT_PASSABLE:
			collision_shape_2d.disabled = false
		State.PASSABLE:
			collision_shape_2d.disabled = true


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()

	new_saved_data.node_path = get_path()
	new_saved_data.state = state as int

	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			state = data.state as State
