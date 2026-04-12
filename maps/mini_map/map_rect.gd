class_name MapRect
extends NinePatchRect

const BRIGHTEST: float = 0.7
const DEFAULT_DURATION: float = 0.5

@export var location: Map.Location = Map.Location.NONE

var tween: Tween = null


func _ready() -> void:
	Global.location_changed.connect(_on_location_changed)


func start_flashing(duration: float) -> void:
	material = material as ShaderMaterial
	tween = create_tween().set_loops()
	tween.tween_method(
		func(v: float) -> void: material.set_shader_parameter("flash_amount", v),
		0.0,
		BRIGHTEST,
		duration,
	)
	tween.tween_method(
		func(v: float) -> void: material.set_shader_parameter("flash_amount", v),
		BRIGHTEST,
		0.0,
		duration,
	)


func stop_flashing() -> void:
	if tween:
		tween.kill()
	material.set_shader_parameter("flash_amount", 0.0)


func _on_location_changed(player_location: Map.Location) -> void:
	if location == player_location:
		start_flashing(DEFAULT_DURATION)
	else:
		stop_flashing()
