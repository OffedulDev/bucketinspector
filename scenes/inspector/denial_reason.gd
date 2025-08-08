extends Control

const WRITING_SFX = preload("res://scenes/inspector/writing.mp3")
const CONFIRM_SFX = preload("res://scenes/inspector/confirm.mp3")

@onready var reasons_container = get_node("PanelContainer/MarginContainer/VBoxContainer/Reasons/VBoxContainer")
@onready var inspector = get_parent().get_node("Inspector")

signal confirmed
var reasons = {}

func selected_reason(index: int, button: OptionButton, id: int) -> void:
	var option = button.get_item_text(index)
	if option == "remove reason":
		reasons.erase(id)
		button.queue_free()
	else:
		reasons.set(id, option)

var i = 0
func add_reason() -> void:
	i += 1
	var den_reasons = Utils.DENIAL_REASONS.values()
	var button = OptionButton.new()
	reasons.set(i, den_reasons[0])
	for reason in den_reasons:
		button.add_item(reason)
	button.add_item("remove reason")
	reasons_container.add_child(button)
	button.item_selected.connect(selected_reason.bind(button, i))
	inspector._play_sfx(CONFIRM_SFX)

func _ready() -> void:
	position = Vector2(400, -300)
	visible = true
	get_tree().create_tween().tween_property(self, "position", Vector2(400, 210), 0.3)
		
func _on_add_pressed() -> void:
	add_reason()

func _on_confirm_pressed() -> void:
	confirmed.emit(reasons.values())
	inspector._play_sfx(WRITING_SFX)
	var t = get_tree().create_tween()
	t.tween_property(self, "position", Vector2(400, -300), 0.3)
	await t.finished
	queue_free()

func _on_cancel_pressed() -> void:
	confirmed.emit(null)
	var t = get_tree().create_tween()
	t.tween_property(self, "position", Vector2(400, -300), 0.3)
	await t.finished
	queue_free()
