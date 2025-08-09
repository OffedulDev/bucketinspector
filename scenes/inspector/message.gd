extends PanelContainer

@onready var label: RichTextLabel = get_node("MarginContainer/VBoxContainer/Label")
@onready var continue_btn: Button = get_node("MarginContainer/VBoxContainer/Continue")
var text = """Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent pharetra dapibus volutpat. Suspendisse gravida, est vitae consequat ultrices, eros urna vulputate arcu, eget rutrum mauris enim quis velit. Donec feugiat felis non nibh dictum, iaculis tempor elit consectetur. Sed velit sem, faucibus vitae nulla scelerisque, maximus mollis lacus. Mauris elit quam, posuere viverra ultricies a, porttitor eget libero. Phasellus vehicula maximus nunc, ut volutpat tellus lobortis a. Nullam vel eleifend tortor. Suspendisse cursus semper ullamcorper. Morbi eu dui tincidunt, porttitor diam quis, mollis velit. In at egestas ipsum.

Sed efficitur purus vel commodo aliquet. Nullam dictum pretium ex quis elementum. Vestibulum in lorem dolor. Suspendisse eu tempus ipsum. Mauris finibus magna nec pharetra consectetur. Nullam velit libero, sagittis id accumsan et, pretium ac eros. Mauris viverra rutrum tortor, non bibendum ex hendrerit quis. Morbi ac libero et ipsum pellentesque varius. Vivamus vel rutrum dolor. Mauris tincidunt porta augue, vel mollis ipsum. Fusce non velit quis lectus euismod hendrerit. Praesent suscipit aliquet ligula nec facilisis. Duis lobortis fringilla dolor nec vestibulum. Interdum et malesuada fames ac ante ipsum primis in faucibus.

Donec maximus justo quis ullamcorper finibus. Mauris vehicula tincidunt massa sit amet gravida. Vestibulum maximus sit amet lectus eget facilisis. Vivamus elementum commodo velit, eu blandit urna vehicula ut. Sed accumsan tortor vel ligula mollis, et auctor odio aliquam. Pellentesque rhoncus elit quis metus malesuada scelerisque. Suspendisse viverra mauris ligula, eget vulputate sem imperdiet posuere. Aliquam dignissim turpis sit amet dictum interdum. Suspendisse ac nisl sit amet velit sagittis accumsan.

In fermentum elementum elementum. Proin sit amet interdum ipsum. Vestibulum egestas urna nec nulla consequat, nec blandit nisi maximus. Interdum et malesuada fames ac ante ipsum primis in faucibus. Curabitur tincidunt, eros ut mattis mollis, lorem nisi finibus nulla, at iaculis augue eros eget risus. Duis sagittis dapibus ligula, a dignissim purus sodales eget. Nunc et sapien sed turpis ultricies gravida ac at dui."""
signal on_continue

func _on_continue():
	on_continue.emit()
	
	var tween: Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.25)
	await tween.finished
	queue_free()

func _scrolling(bar: VScrollBar) -> void:
	if bar.value >= (bar.max_value-279):
		continue_btn.visible = true
	
func _loaded() -> void:
	var scroll_bar = label.get_v_scroll_bar()
	if scroll_bar.visible == false:
		continue_btn.visible = true
	else:
		scroll_bar.scrolling.connect(_scrolling.bind(scroll_bar))

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	
	label.text = text
	label.finished.connect(_loaded)
	
	var tween: Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)
