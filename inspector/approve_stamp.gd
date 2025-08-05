extends Area3D

@onready var inspector = get_parent()
@onready var tween: Tween
@onready var deny_stamp = get_parent().get_node("Deny")
var status = "exit"
var block = false

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and not deny_stamp.block and not block:
			block = true
			inspector.approve_npc()

func _mouse_enter() -> void:
	if block == true: return
	if status == "enter":
		return
	
	if tween != null and tween.is_running():
		tween.kill()
	
	
	tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(get_node("Model"), "position", Vector3(0, 0.5, 0), 0.3)
	
	get_node("Label").visible = true
	status = "enter"

func _mouse_exit() -> void:
	if block == true: return
	if status == "exit":
		return
	
	if tween != null and tween.is_running():
		tween.kill()
	
	
	tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(get_node("Model"), "position", Vector3(0, 0, 0), 0.3)
	
	get_node("Label").visible = false
	status = "exit"
