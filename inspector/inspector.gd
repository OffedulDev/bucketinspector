extends Node3D
const NPC_SCENE = preload("res://npc/npc.tscn")
const MESSAGE_SCENE = preload("res://inspector/message.tscn")
const NAMES: Array[StringName] = [
	"Aethelred", "Brynjolf", "Cassian", "Drystan", "Einar", "Gawain",
	"Isolde", "Lyra", "Morwen", "Seraphina", "Thorne", "Valerius"
]
const SURNAMES: Array[StringName] = [
	"Ashwood", "Blackwood", "Carroway", "Drakon", "Faewind", "Grimm",
	"Ironhand", "Longshadow", "Oakheart", "Silverbane", "Stonebridge", "Winterfall"
]
const LIQUIDS: Dictionary[StringName, int] = {
	"Aetherium": 100,
	"Sunpetal": 85,
	"Glimmer": 95,
	"Brightale": 120,
	"Dewdrop": 75,
	"Nectar": 90,
}
const ILLEGAL_LIQUIDS: Array[StringName] = [
	"Shadowink",
	"Voidgaze",
	"Bloodrite",
	"Nightshade",
	"Whisper",
	"Mirevine",
	"Cursedrain",
	"Blackveil",
	"Frostbite",
	"Poisonfall",
	"Doomflow",
	"Vilebrew"
]
const KINGDOMS: Array[StringName] = [
	"Aethelgard",
	"Bryndale",
	"Caledon",
	"Drakonburg",
	"Emberfall",
	"Gwynedd",
]
const FAKE_KINGDOMS: Array[StringName] = [
	"Unicornia",
	"Glimmerhaven",
	"Sparkleburg",
	"Waffleford",
	"Fluffington",
	"Fairy-talia",
	"Noodlethrone",
	"Popsicle Peaks",
	"Giggledom",
	"Whimsyville",
	"Tumbleton",
	"Jellybean Isle"
]

var current_npc: PathFollow3D = null
var current_npc_information: Dictionary = {}
var moved_items = false
@export var messages: Messages
@onready var rulebook = get_parent().get_node("Rulebook")
@onready var path: Path3D = get_parent().get_node("NpcPath")
@onready var camera: Camera3D = get_parent().get_node("Camera")

@onready var day_handler = get_parent().get_node("Day")
@onready var passport_view: Node3D = get_parent().get_node("PassportView")
@onready var normal_view: Node3D = get_parent().get_node("NormalView")
@onready var scale_object: Area3D = get_node("Scale")
@onready var scale_view: Node3D = get_parent().get_node("ScaleView")
@onready var bucket_point: Node3D = get_node("BucketPoint")
@onready var passport_point: Node3D = get_node("PassportPoint")
@onready var rulebook_tab: TabContainer = rulebook.get_node("TabContainer")
@onready var npc_wait_timer: Timer = get_node("NPCWait")

func _process(delta: float) -> void:
	if current_npc == null and npc_wait_timer.is_stopped():
		npc_wait_timer.wait_time = randi_range(1, 4)
		npc_wait_timer.start()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("pickup_bucket"):
		if current_npc:
			if current_npc.progress_ratio == 0.5 and not moved_items:
				move_items_to_stand()
	elif event.is_action_pressed("rulebook"):
		rulebook.visible = not rulebook.visible

func focus_scale() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", scale_view.global_transform, 0.5)

func focus_passport() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", passport_view.global_transform, 0.5)

func unfocus() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", normal_view.global_transform, 0.5)

func _ready() -> void:
	randomize()
	scale_object.mouse_entered.connect(focus_scale)
	scale_object.mouse_exited.connect(unfocus)
	
	_on_day_day_started()

func set_scale_label():
	# Set scale
	scale_object.get_node("Label").text = str(current_npc_information["content_weight"]) + " st"

func move_items_to_stand() -> void:
	var bucket: Node3D = current_npc.get_node("Npc").get_node("Bucket")
	var passport: Area3D = current_npc.get_node("Npc").get_node("Passport")
	moved_items = true

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(bucket, "global_position", bucket_point.global_position, 1)
	tween.finished.connect(set_scale_label)
	
	tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(passport, "global_position", passport_point.global_position, 1)
	tween.tween_property(passport, "rotation", passport_point.rotation, 1)
	tween.set_parallel(false)
	tween.tween_property(passport.get_node("Top"), "rotation_degrees", Vector3(0, -180, 0), 1)
	
	passport.mouse_entered.connect(focus_passport)
	passport.mouse_exited.connect(unfocus)

func spawn_npc() -> void:	
	var npc: PathFollow3D = NPC_SCENE.instantiate()
	path.add_child(npc)
	
	current_npc_information = {
		"name": NAMES.pick_random(),
		"surname": SURNAMES.pick_random(),
		"errors": []
	}
	
	var kingdom_real = randf() > 0.4
	if kingdom_real:
		current_npc_information["kingdom"] = KINGDOMS.pick_random()
	else:
		current_npc_information["kingdom"] = FAKE_KINGDOMS.pick_random()
		current_npc_information["errors"].append("kingdom")
		
	var content_legal = randf() > 0.45
	if content_legal:
		current_npc_information["content"] = LIQUIDS.keys().pick_random()
	else:
		current_npc_information["content"] = ILLEGAL_LIQUIDS.pick_random()
		current_npc_information["errors"].append("content")
	
	var weight_legal = day_handler.day == 0 if true else randi() > 0.45
	if weight_legal and content_legal:
		current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]-50, LIQUIDS[current_npc_information["content"]])
	else:
		if content_legal:
			current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]+10, LIQUIDS[current_npc_information["content"]]+100)
		else:
			current_npc_information["content_weight"] = randi_range(70, 100)
		current_npc_information["errors"].append("illegal-weight")
			
	# Editing passport
	var passport: Area3D = npc.get_node("Npc").get_node("Passport")
	var passport_bottom: MeshInstance3D = passport.get_node("Bottom")
	passport_bottom.get_node("Name").text = current_npc_information["name"]
	passport_bottom.get_node("Surname").text = current_npc_information["surname"]
	passport_bottom.get_node("Kingdom").text = current_npc_information["kingdom"]
	passport_bottom.get_node("Content").text = current_npc_information["content"]

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(npc, "progress_ratio", 0.5, 1)
	
	current_npc = npc

@onready var approve_stamp = get_node("Approve")
@onready var approve_stamp_initial_pos = approve_stamp.global_position
@onready var deny_stamp = get_node("Deny")
@onready var deny_stamp_initial_pos = deny_stamp.global_position
@onready var stamp_point = get_node("StampPoint")

func give_items_back() -> Tween:
	var bucket: Node3D = current_npc.get_node("Npc").get_node("Bucket")
	var passport: Area3D = current_npc.get_node("Npc").get_node("Passport")
	moved_items = false
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(passport.get_node("Top"), "rotation_degrees", Vector3(0, 0, 0), 1)
	tween.tween_property(bucket, "position", Vector3(0.021, 0.738, -0.764), 1)
	await tween.finished
	scale_object.get_node("Label").text = "0 st"
	
	tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(passport, "position", Vector3(-1.125, 1, -0.502), 1)
	tween.tween_property(passport, "rotation_degrees", Vector3(0, 0, 0), 1)
	
	passport.mouse_entered.disconnect(focus_passport)
	passport.mouse_exited.disconnect(unfocus)
	unfocus()
	
	return tween
	

func approve_npc() -> void:
	if moved_items == false: 
		approve_stamp.block = false
		return
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(approve_stamp.get_node("Model"), "global_position", stamp_point.global_position, 0.4)
	
	await tween.finished		
	tween = get_tree().create_tween()
	tween.tween_property(approve_stamp.get_node("Model"), "global_position", approve_stamp_initial_pos, 0.4)
	
	await (await give_items_back()).finished
	approve_stamp.block = false
	
	tween = get_tree().create_tween()
	tween.tween_property(current_npc, "progress_ratio", 1, 1)
	await tween.finished
	
	if len(current_npc_information["errors"]) == 0:
		print("Correct")
	else:
		print("Wrong!")
		print(current_npc_information["errors"])
	
	current_npc.queue_free()
	current_npc = null
	
func deny_npc() -> void:
	if moved_items == false: 
		deny_stamp.block = false
		return
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(deny_stamp.get_node("Model"), "global_position", stamp_point.global_position, 0.4)
	
	await tween.finished		
	tween = get_tree().create_tween()
	tween.tween_property(deny_stamp.get_node("Model"), "global_position", deny_stamp_initial_pos, 0.4)
	
	await (await give_items_back()).finished
	deny_stamp.block = false
	
	tween = get_tree().create_tween()
	tween.set_parallel(false)
	tween.tween_property(current_npc.get_node("Npc"), "rotation_degrees", Vector3(0, 180, 0), 1)
	tween.tween_property(current_npc, "progress_ratio", 0, 1)
	await tween.finished
	
	if len(current_npc_information["errors"]) > 0:
		print("Correct")
		print(current_npc_information["errors"])
	else:
		print("Wrong!")
	
	current_npc.queue_free()
	current_npc = null

func _unpause() -> void:
	get_tree().paused = false
	
func prompt_message(text: String) -> Signal:
	var message = MESSAGE_SCENE.instantiate()
	message.text = text
	message.on_continue.connect(_unpause)
	
	get_parent().add_child(message)
	get_tree().paused = true
	
	
	return message.on_continue
	
func _on_day_day_started() -> void:
	if day_handler.day == 0:
		var idx = rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Weight Restrictions"))
		rulebook_tab.set_tab_hidden(idx, true)
		get_tree().create_timer(2).timeout.connect(
			prompt_message.bind(messages.messages["intro"].text)
		)
	elif day_handler.day == 1:
		var idx = rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Weight Restrictions"))
		rulebook_tab.set_tab_hidden(idx, false)
		scale_object.visible = true
		bucket_point.position = Vector3(-0.981, 0.954, -0.393)
	
	if current_npc:
		current_npc.queue_free()
		current_npc = null
		scale_object.get_node("Label").text = "0 st"

func _on_npc_wait_timeout() -> void:
	if day_handler.current_time > 15:
		day_handler.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		spawn_npc()
