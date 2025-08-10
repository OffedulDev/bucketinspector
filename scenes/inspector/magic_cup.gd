# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Area3D

const MAGIC_CUP_SFX = preload("res://scenes/inspector/magic_cup_sound.mp3")
const LIGHT_CUP_SFX = preload("res://scenes/inspector/light.mp3")

@onready var model: Node3D = get_node("Model")
@onready var fire_particles: GPUParticles3D = model.get_node("Fire")
@onready var uses_label: Label3D = get_node("Uses")
@onready var light_label: Label3D = get_node("Light")
@onready var test_label: Label3D = get_node("Test")
@onready var inspector = get_parent()
const MAX_USES = 3

var lighted = false
var uses = 0

func _ready():
	uses_label.text = tr("magic_cup.uses") % [str(uses) + "/" + str(MAX_USES)]

func _light_cup() -> void:
	lighted = true
	fire_particles.visible = true
	inspector._play_sfx(LIGHT_CUP_SFX)
	light_label.visible = false
	test_label.visible = true

func _use_cup() -> void:
	inspector._play_sfx(MAGIC_CUP_SFX)
	if uses == MAX_USES: 
		inspector.prompt_message(tr("magic_cup.max_uses"))
		return
	uses += 1
	uses_label.text = tr("magic_cup.uses") % [str(uses) + "/" + str(MAX_USES)]
	
	inspector.prompt_message(tr("magic_cup.used") % [(inspector.current_npc_information["real_content"] if inspector.current_npc_information.get("real_content") else inspector.current_npc_information["content"])])
	
	lighted = false
	fire_particles.visible = false
	
	light_label.visible = false
	test_label.visible = false

func _on_mouse_entered() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(model, "position", Vector3(-1.882, 1.146, -1.354), 0.2)
	
	if lighted == false:
		light_label.visible = true
		test_label.visible = false
	else:
		light_label.visible = false
		test_label.visible = true

func _on_mouse_exited() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(model, "position", Vector3(-1.882, 1.046, -1.354), 0.2)
	
	light_label.visible = false
	test_label.visible = false

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.is_action_pressed("click"):
			if not lighted:
				if inspector.moved_items == true:
					_light_cup()
			else:
				_use_cup()

func _on_day_day_started() -> void:
	uses = 0
	uses_label.text = tr("magic_cup.uses") % [str(uses) + "/" + str(MAX_USES)]
	lighted = false
	fire_particles.visible = false
