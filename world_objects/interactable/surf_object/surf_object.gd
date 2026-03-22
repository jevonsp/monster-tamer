extends Area2D
class_name SurfObject

enum State { NOT_PASSABLE, PASSABLE }
@export var state: State = State.NOT_PASSABLE
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	pass


func interact(body: Player) -> void:
	var ta: Array[String]
	if body.available_travel_methods[Player.TravelState.SURFING] != true:
		ta = ["If you had a Monster strong enough, you could surf here!"]
		Global.send_text_box.emit(null, ta, false, false, true)
		await Global.text_box_complete
		return
	
	ta = ["Would you like to surf?"]
	Global.send_text_box.emit(self, ta, false, true, false)
	var answer = await Global.answer_given
	Global.toggle_player.emit()
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
