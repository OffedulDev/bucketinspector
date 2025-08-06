extends Node

var json = JSON.new()
var path = "user://data.json"
var wants_to_load = false

func save(day, money) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(
		json.stringify({
			"day": day,
			"money": money
		})
	)
	file.close()

func load_save() -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
		
	var content = json.parse_string(file.get_as_text())
	return content
