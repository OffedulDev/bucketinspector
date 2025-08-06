extends Area3D

@onready var model: Node3D = get_node("Model")
@onready var fire_particles: GPUParticles3D = model.get_node("Fire")
@onready var uses_label: Label3D = get_node("Uses")
@onready var light_label: Label3D = get_node("Light")
@onready var test_label: Label3D = get_node("Test")
@onready var inspector = get_parent()
const MAX_USES = 3

var lighted = false
var uses = 0

func _light_cup() -> void:
	lighted = true
	fire_particles.visible = true

func _use_cup() -> void:
	if uses == MAX_USES: 
		inspector.prompt_message("""
[font_size=20]The cup has NOT spoken![/font_size]
The cup is [b]now tired and needs to rest[/b] for the day,
sorry inspector!
		""")
		return
	uses += 1
	uses_label.text = str(uses) + "/" + str(MAX_USES) + " uses"
	
	inspector.prompt_message("""
[font_size=20]The cup has spoken![/font_size]
The cup has spoken and it has determined with the power
of ancient debris that the content the [color=yellow]outlander[/color]
is bringing [b][color=green]IS 
	""" + (inspector.current_npc_information["real_content"] if inspector.current_npc_information.get("real_content") else inspector.current_npc_information["content"]) + "[/color][/b]")
	
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
