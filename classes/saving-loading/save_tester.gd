extends Control


func _on_button_pressed() -> void:
	SaverLoader.save_game()


func _on_button_2_pressed() -> void:
	SaverLoader.erase_saved_game()
