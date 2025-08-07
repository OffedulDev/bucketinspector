extends Node3D
const NPC_SCENE = preload("res://scenes/npc/npc.tscn")
const MESSAGE_SCENE = preload("res://scenes/inspector/message.tscn")
const EXPLOSION_SFX = preload("res://resources/audio/sfx/explosion.mp3")
const NAMES: Array[StringName] = [
	"Aethelred", "Brynjolf", "Cassian", "Drystan", "Einar", "Gawain",
	"Isolde", "Lyra", "Morwen", "Seraphina", "Thorne", "Valerius"
]
const SURNAMES: Array[StringName] = [
	"Ashwood", "Blackwood", "Carroway", "Drakon", "Faewind", "Grimm",
	"Ironhand", "Longshadow", "Oakheart", "Silverbane", "Stonebridge", "Winterfall"
]
const LIQUIDS: Dictionary[StringName, Dictionary] = {
	"Aetherium": {
		"max": 100,
		"color": Color("#82b0a8")
	},
	"Sunpetal": {
		"max": 85,
		"color": Color("#c3cc8d")
	},
	"Glimmer": {
		"max": 95,
		"color": Color("#9e84cf")
	},
	"Brightale": {
		"max": 120,
		"color": Color("#92c3d4")
	},
	"Dewdrop": {
		"max": 75,
		"color": Color("#ad2638")
	},
	"Nectar": {
		"max": 90,
		"color": Color("#8bad26")
	},
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
var terrorist_spawned = false
var moved_items = false
@export var messages: Messages
@onready var rulebook = get_parent().get_node("Rulebook")
@onready var path: Path3D = get_parent().get_node("NpcPath")
@onready var camera: Camera3D = get_parent().get_node("Camera")

@onready var day_handler = get_parent().get_node("Day")
@onready var passport_view: Node3D = get_parent().get_node("PassportView")
@onready var normal_view: Node3D = get_parent().get_node("NormalView")
@onready var bucket_view: Node3D = get_parent().get_node("BucketView")
@onready var lab_view: Node3D = get_parent().get_node("LabView")
@onready var scale_object: Area3D = get_node("Scale")
@onready var scale_view: Node3D = get_parent().get_node("ScaleView")
@onready var bucket_point: Node3D = get_node("BucketPoint")
@onready var passport_point: Node3D = get_node("PassportPoint")
@onready var rulebook_tab: TabContainer = rulebook.get_node("TabContainer")
@onready var npc_wait_timer: Timer = get_node("NPCWait")
@export var correct_fare: int = 0
@export var wrong_fare: int = 0

var decay = 0.8
var max_offset = Vector2(0.5, 0.5)
var max_roll = 0.1
var shake_strength = 0

func _process(delta: float) -> void:
	if current_npc == null and npc_wait_timer.is_stopped():
		npc_wait_timer.wait_time = randi_range(1, 4)
		npc_wait_timer.start()
		
	var amount = pow(shake_strength, 2)
	camera.rotation = Vector3(camera.rotation.x, camera.rotation.y, 0.1 * amount * randi_range(-1, 1))
	camera.h_offset = max_offset.x * amount * randi_range(-1, 1)
	camera.v_offset = max_offset.y * amount * randi_range(-1, 1)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("pickup_bucket"):
		if current_npc:
			if current_npc.progress_ratio == 0.5 and not moved_items:
				move_items_to_stand()
	elif event.is_action_pressed("rulebook"):
		rulebook.visible = not rulebook.visible
	elif event.is_action_pressed("look_left"):
		if day_handler.day > 1:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(camera, "global_transform", lab_view.global_transform, 0.5)
	elif event.is_action_pressed("look_right"):
		unfocus()
		
func focus_scale() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", scale_view.global_transform, 0.5)

func focus_passport() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", passport_view.global_transform, 0.5)

func focus_bucket() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", bucket_view.global_transform, 0.5)

func unfocus() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", normal_view.global_transform, 0.5)

func _ready() -> void:
	randomize()
	scale_object.mouse_entered.connect(focus_scale)
	scale_object.mouse_exited.connect(unfocus)
	
	# Initialize UI colors
	for liquid in LIQUIDS.keys():
		var template = rulebook_tab.get_node("Fake Liquids/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Template").duplicate()
		template.get_node("Label").text = liquid
		template.get_node("ColorRect").color = LIQUIDS[liquid]["color"]
		template.visible = true
		
		rulebook_tab.get_node("Fake Liquids/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/").add_child(template)
	
	_on_day_day_started()

func set_scale_label():
	# Set scale
	scale_object.get_node("Label").text = str(current_npc_information["content_weight"]) + " st"

func move_items_to_stand() -> void:
	if moved_items == true: return
	var bucket: Area3D = current_npc.get_node("Npc").get_node("Bucket")
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
	
	if not terrorist_spawned:
		passport.mouse_entered.connect(focus_passport)
		passport.mouse_exited.connect(unfocus)
		bucket.mouse_entered.connect(focus_bucket)
		bucket.mouse_exited.connect(unfocus)
	
	if terrorist_spawned:
		get_tree().create_timer(3).timeout.connect(_act_terrorist)

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
		current_npc_information["errors"].append("fake kingdom")
		
	var content_legal = randf() > 0.45
	var bucket: Area3D = npc.get_node("Npc/Bucket")
	var content_model: MeshInstance3D = bucket.get_node("Content")
	var material: StandardMaterial3D = StandardMaterial3D.new()
	var fake_content
	if content_legal:
		current_npc_information["content"] = LIQUIDS.keys().pick_random()
		material.albedo_color = LIQUIDS[current_npc_information["content"]]["color"]
	else:
		fake_content = LIQUIDS.keys().pick_random() if (randf() > 0.3 and day_handler.day > 1) else null
		var color_faked = randi() > 0.2
		if fake_content:
			current_npc_information["real_content"] = ILLEGAL_LIQUIDS.pick_random()
			current_npc_information["content"] = fake_content
			
			var real_color = LIQUIDS[current_npc_information["content"]]["color"]
			if color_faked:
				material.albedo_color = Color(
					randf_range(real_color.r-0.2, real_color.r+0.2), 
					randf_range(real_color.g-0.2, real_color.g+0.2), 
					randf_range(real_color.b-0.2, real_color.b+0.2)
				)
				print("color was faked")
		else:
			current_npc_information["content"] = ILLEGAL_LIQUIDS.pick_random()
		
		if not color_faked:
			material.albedo_color = Color(randf(), randf(), randf())
			
		current_npc_information["errors"].append("illegal content")
	
	content_model.mesh.surface_set_material(0, material)
	var weight_legal = randi() > 0.45 or fake_content
	if weight_legal and content_legal:
		current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]["max"]-50, LIQUIDS[current_npc_information["content"]]["max"])
	else:
		if day_handler.day > 0:
			if content_legal:
				current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]["max"]+10, LIQUIDS[current_npc_information["content"]]["max"]+100)
			else:
				current_npc_information["content_weight"] = randi_range(70, 100)
			current_npc_information["errors"].append("illegal weight")
		else:
			if content_legal:
				current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]["max"], LIQUIDS[current_npc_information["content"]]["max"])
			else:
				current_npc_information["content_weight"] = randi_range(70, 100)

	# Editing passport
	var passport: Area3D = npc.get_node("Npc").get_node("Passport")
	var passport_bottom: MeshInstance3D = passport.get_node("Bottom")
	passport_bottom.get_node("Name").text = current_npc_information["name"]
	passport_bottom.get_node("Surname").text = current_npc_information["surname"]
	passport_bottom.get_node("Age").text = str(randi_range(10, 30))
	passport_bottom.get_node("Kingdom").text = current_npc_information["kingdom"]
	passport_bottom.get_node("Content").text = current_npc_information["content"] if not fake_content else fake_content

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(npc, "progress_ratio", 0.5, 4)
	
	current_npc = npc
	
	var animation_player: AnimationPlayer = npc.get_node("Npc/Character/AnimationPlayer")
	animation_player.play("walk")
	await tween.finished
	animation_player.stop()
	animation_player.play("idle")

@onready var approve_stamp = get_node("Approve")
@onready var approve_stamp_initial_pos = approve_stamp.global_position
@onready var deny_stamp = get_node("Deny")
@onready var deny_stamp_initial_pos = deny_stamp.global_position
@onready var stamp_point = get_node("StampPoint")

func give_items_back() -> Tween:
	var bucket: Area3D = current_npc.get_node("Npc").get_node("Bucket")
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
	if terrorist_spawned:
		return
		
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
	var animation_player: AnimationPlayer = current_npc.get_node("Npc/Character/AnimationPlayer")
	animation_player.stop()
	animation_player.play("walk")
	
	await tween.finished
	
	if len(current_npc_information["errors"]) == 0:
		print("Correct")
		day_handler.today_earnings += correct_fare
	else:
		print("Wrong!")
		print(current_npc_information["errors"])
		prompt_message("You made a mistake! The stranger had the following issues: " + ",".join(current_npc_information["errors"]))
		day_handler.today_earnings -= wrong_fare
	
	current_npc.queue_free()
	current_npc = null
	
func deny_npc() -> void:
	if terrorist_spawned:
		return
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
	var animation_player: AnimationPlayer = current_npc.get_node("Npc/Character/AnimationPlayer")
	animation_player.stop()
	animation_player.play("walk")
	
	await tween.finished
	
	if len(current_npc_information["errors"]) > 0:
		print("Correct")
		print(current_npc_information["errors"])
		day_handler.today_earnings += correct_fare
	else:
		print("Wrong!")
		prompt_message("You made a mistake. The stranger didn't have any issues and could pass... but you DENIED HIM!")
		day_handler.today_earnings -= wrong_fare
	
	current_npc.queue_free()
	current_npc = null

func _unpause_time() -> void:
	day_handler.day_timer.paused = false
	
func prompt_message(text: String) -> Signal:
	var message = MESSAGE_SCENE.instantiate()
	message.text = text
	message.on_continue.connect(_unpause_time)
	
	get_parent().add_child(message)
	day_handler.day_timer.paused = true


	return message.on_continue
	
func _on_day_day_started() -> void:
	if day_handler.day >= 0:
		rulebook_tab.set_tab_hidden(
			rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Weight Restrictions")), 
			true
		)
		rulebook_tab.set_tab_hidden(
			rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Fake Liquids")), 
			true
		)
		
		if day_handler.day == 0:
			get_tree().create_timer(2).timeout.connect(
				prompt_message.bind(tr(messages.messages["intro"].text))
			)
	if day_handler.day >= 1:
		var idx = rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Weight Restrictions"))
		rulebook_tab.set_tab_hidden(idx, false)
		
		scale_object.visible = true
		bucket_point.position = Vector3(-0.981, 0.954, -0.393)
		
		if day_handler.day == 1:
			get_tree().create_timer(2).timeout.connect(
				prompt_message.bind(tr(messages.messages["day1"].text))
			)
	if day_handler.day >= 2:
		get_parent().get_node("LabDesk").visible = true
		get_node("MagicCup").visible = true
		
		var idx = rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Fake Liquids"))
		rulebook_tab.set_tab_hidden(idx, false)
		
		if day_handler.day == 2:
			get_tree().create_timer(2).timeout.connect(
				prompt_message.bind(tr(messages.messages["day2"].text))
			)
	
	if current_npc:
		current_npc.queue_free()
		current_npc = null
		scale_object.get_node("Label").text = "0 st"
		moved_items = false

func _play_sfx(stream: AudioStream):
	var sound: AudioStreamPlayer = AudioStreamPlayer.new()
	sound.bus = "SFX"
	sound.stream = stream
	get_parent().add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)

func _act_terrorist() -> void:
	var bucket: Area3D = current_npc.get_node("Npc/Bucket")
	var particles: GPUParticles3D = bucket.get_node("GPUParticles3D")
	var explosion: Node3D = bucket.get_node("Explosion")
	
	particles.visible = true
	await get_tree().create_timer(2).timeout
	explosion.visible = true
	_play_sfx(EXPLOSION_SFX)
	shake_strength = 0.5
	await get_tree().create_timer(0.5).timeout
	_play_sfx(EXPLOSION_SFX)
	await get_tree().create_timer(0.5).timeout
	day_handler.reset_day(true)
	await get_tree().create_timer(1).timeout
	shake_strength = 0
	
	terrorist_spawned = false

func _on_npc_wait_timeout() -> void:
	if day_handler.current_time > 15 and day_handler.day == 0:
		day_handler.day_timer.paused = true
		terrorist_spawned = true
		spawn_npc()
	else:
		spawn_npc()
