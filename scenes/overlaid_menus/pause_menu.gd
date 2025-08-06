extends PauseMenu

func _on_save_pressed() -> void:
	var day_handler = get_parent().get_node("Day")
	SaveHandler.save(day_handler.day, day_handler.money)
	
	OS.alert("Game saved!")
