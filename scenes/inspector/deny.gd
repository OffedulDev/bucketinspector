# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Area3D

const WOOSH = preload("res://scenes/inspector/woosh.mp3")

@onready var inspector = get_parent()
@onready var tween: Tween
@onready var approve_stamp = get_parent().get_node("Approve")
var status = "exit"
var block = false

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and not approve_stamp.block and not block:
			block = true
			inspector.deny_npc()

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
	inspector._play_sfx(WOOSH, -15)

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
