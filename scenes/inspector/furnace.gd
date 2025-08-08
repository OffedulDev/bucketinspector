# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Area3D

const FURNACE_FUEL_SFX = preload("res://scenes/inspector/furnace_fuel.mp3")
const METAL_DOOR_SFX = preload("res://scenes/inspector/metal_door.mp3")

@onready var fire = get_node("Fire")
@onready var left_label = get_node("Left")
@onready var fuel_label = get_node("Fuel")
@onready var overtime_timer = get_node("Overtime")
@onready var burning_timer = get_node("Burning")
@onready var day_handler = get_parent().get_parent().get_node("Day")
@onready var inspector = get_parent()
@onready var bell_audio = get_node("AudioStreamPlayer3D")

func _mouse_enter() -> void:
	fuel_label.visible = true
	get_node("Model/DoorClose").visible = false
	get_node("Model/DoorOpen").visible = true
	inspector._play_sfx(METAL_DOOR_SFX)
	

func _ready() -> void:
	burning_timer.start()

func _process(delta: float) -> void:
	if not burning_timer.is_stopped():
		left_label.text = str(int(burning_timer.time_left)) + "s"
	else:
		left_label.text = "-" + str(int(overtime_timer.time_left)) + "s"
	
	if not burning_timer.is_stopped():
		fire.visible = true
	else:
		fire.visible = false
	
func use_furnace():
	if day_handler.money > 20:
		day_handler.money -= 20
		burning_timer.stop()
		burning_timer.start()
		overtime_timer.stop()
		inspector._play_sfx(FURNACE_FUEL_SFX)

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		use_furnace()

func _mouse_exit() -> void:
	fuel_label.visible = false
	
	get_node("Model/DoorClose").visible = true
	get_node("Model/DoorOpen").visible = false
	inspector._play_sfx(METAL_DOOR_SFX)

func _on_burning_timeout() -> void:
	overtime_timer.start()
	
	for i in range(2):
		bell_audio.play()
		await get_tree().create_timer(4.81).timeout
		bell_audio.stop()

func _on_overtime_timeout() -> void:
	var fine = randi_range(10, 30)
	
	inspector.prompt_message(tr("furnace.burn_out") % [str(fine)])
	day_handler.money -= fine
	day_handler.reset_day()

func _on_day_day_started() -> void:
	overtime_timer.stop()
	burning_timer.stop()
	burning_timer.start()
	
