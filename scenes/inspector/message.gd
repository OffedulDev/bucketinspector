extends PanelContainer

@onready var label: RichTextLabel = get_node("MarginContainer/VBoxContainer/Label")
@onready var continue_btn: Button = get_node("MarginContainer/VBoxContainer/Continue")
var text = ""

signal on_continue

func _on_continue():
	on_continue.emit()
	
	var tween: Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.25)
	await tween.finished
	queue_free()

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	label.text = text
	
	var tween: Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)
