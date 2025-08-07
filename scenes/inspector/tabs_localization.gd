extends TabContainer

func _ready() -> void:
	for i in range(get_child_count()):
		var child = get_child(i)
		var translation = tr("rulebook.tabs." + child.name.to_lower())
		set_tab_title(i, translation)
