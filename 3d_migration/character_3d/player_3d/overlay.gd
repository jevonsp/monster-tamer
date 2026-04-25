class_name Overlay
extends ColorRect

signal show_overlay(type: OverlayType)

enum OverlayType { NONE, IRIS, DARK }

@export var overlay_type: OverlayType = OverlayType.NONE


func _ready() -> void:
	show_overlay.connect(_on_show_overlay)


func show_none() -> void:
	material.set_shader_parameter("iris_size", 1.0)
	visible = false


func show_iris() -> void:
	material.set_shader_parameter("iris_size", 0.2)
	visible = true


func show_dark() -> void:
	material.set_shader_parameter("iris_size", 0.0)
	material.set_shader_parameter("overlay_opacity", 0.95)
	visible = true


func _on_show_overlay(type: OverlayType) -> void:
	match type:
		OverlayType.NONE:
			show_none()
		OverlayType.IRIS:
			show_iris()
		OverlayType.DARK:
			show_dark()
