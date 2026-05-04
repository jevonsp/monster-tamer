extends CellObject


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return

	var player = area as Player3D
	if player.is_moving():
		await player.grid_step_landed

	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	await interaction_helper.interact(player)

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)
