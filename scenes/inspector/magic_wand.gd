# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Area3D

const MAGIC_SFX = preload("res://scenes/inspector/magic.mp3")

@onready var fire_audio: AudioStreamPlayer3D = get_node("AudioStreamPlayer3D")
@onready var model = get_node("Model")
@onready var fire = model.get_node("Fire")
@onready var label = model.get_node("Label")
@onready var inspector = get_parent()
@onready var day_handler = get_parent().get_parent().get_node("Day")

func _mouse_enter() -> void:
	fire.visible = true
	label.visible = true
	
	fire_audio.volume_db = -20
	fire_audio.play()
	get_tree().create_tween().tween_property(fire_audio, "volume_db", -10, 0.3)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(model, "position", Vector3(0, 0.1, 0), 0.2)

func use_wand():
	if day_handler.money > 30:
		day_handler.money -= 30
		inspector._play_sfx(MAGIC_SFX)
		inspector.insurance = true
		day_handler.get_node("Insurance").visible = true
		inspector.prompt_message(tr("magic_wand.used"))

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		use_wand()

func _mouse_exit() -> void:
	fire.visible = false
	label.visible = false
	fire_audio.volume_db = -20
	var t = get_tree().create_tween()
	t.tween_property(fire_audio, "volume_db", -30, 0.3)
	t.finished.connect(fire_audio.stop)
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(model, "position", Vector3(0, 0, 0), 0.2)
