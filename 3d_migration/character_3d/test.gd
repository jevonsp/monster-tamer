extends RayCast3D


func _process(_delta: float) -> void:
	print("%s: %s" % [get_parent().name, get_collider()])
