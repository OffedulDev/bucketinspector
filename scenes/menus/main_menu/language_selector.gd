extends OptionButton

var languages = [
	"en",
	"it"
]

func _on_item_selected(index: int) -> void:
	TranslationServer.set_locale(languages[index])
