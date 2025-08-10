# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Node3D
const REASON_FOR_DENIAL_SCENE = preload("res://scenes/inspector/denial_reason.tscn")
const WOOSH_SFX = preload("res://scenes/inspector/woosh.mp3")
const PAPER_SFX = preload("res://scenes/inspector/paper.mp3")
const NPC_SCENE = preload("res://scenes/npc/npc.tscn")
const MESSAGE_SCENE = preload("res://scenes/inspector/message.tscn")
const EXPLOSION_SFX = preload("res://resources/audio/sfx/explosion.mp3")
const STAMP_SFX = preload("res://scenes/inspector/stamp.mp3")
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
@onready var bucket_wall_view: Node3D = get_parent().get_node("BucketWallView")
@onready var furnace_view: Node3D = get_parent().get_node("FurnaceView")
@onready var lab_view: Node3D = get_parent().get_node("LabView")
@onready var scale_object: Area3D = get_node("Scale")
@onready var scale_view: Node3D = get_parent().get_node("ScaleView")
@onready var bucket_point: Node3D = get_node("BucketPoint")
@onready var passport_point: Node3D = get_node("PassportPoint")
@onready var rulebook_tab: TabContainer = rulebook.get_node("TabContainer")
@onready var npc_wait_timer: Timer = get_node("NPCWait")
@export var correct_fare: int = 0
@export var wrong_fare: int = 0

var insurance = false
var decay = 0.8
var max_offset = Vector2(0.5, 0.5)
var max_roll = 0.1
var shake_strength = 0

func _process(delta: float) -> void:
	if current_npc == null and npc_wait_timer.is_stopped():
		npc_wait_timer.wait_time = randi_range(1, 2)
		npc_wait_timer.start()
		
	var amount = pow(shake_strength, 2)
	camera.rotation = Vector3(camera.rotation.x, camera.rotation.y, 0.1 * amount * randi_range(-1, 1))
	camera.h_offset = max_offset.x * amount * randi_range(-1, 1)
	camera.v_offset = max_offset.y * amount * randi_range(-1, 1)

var looking = 0
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("pickup_bucket"):
		if current_npc:
			if current_npc.progress_ratio == 0.5 and not moved_items:
				move_items_to_stand()
	elif event.is_action_pressed("rulebook"):
		if not terrorist_spawned:
			rulebook.visible = not rulebook.visible
			Engine.time_scale = 0.5 if rulebook.visible else 1
	elif event.is_action_pressed("look_left"):
		if looking == 0:
			if day_handler.day > 1:
				var tween: Tween = get_tree().create_tween()
				tween.tween_property(camera, "global_transform", lab_view.global_transform, 0.5)
				looking = 1
				_play_sfx(WOOSH_SFX, -20)
		else:
			unfocus()
			_play_sfx(WOOSH_SFX, -20)
			looking = 0
	elif event.is_action_pressed("look_right"):
		if looking == 1:
			unfocus()
			_play_sfx(WOOSH_SFX, -20)
			looking = 0
		elif looking == 0:
			if day_handler.day >= 6:
				focus_furnace()
				_play_sfx(WOOSH_SFX, -20)
				looking = 2
			
		
func focus_scale() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", scale_view.global_transform, 0.5)
	_play_sfx(WOOSH_SFX, -15)

func focus_wall_bucket() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", bucket_wall_view.global_transform, 0.5)
	_play_sfx(WOOSH_SFX, -15)

func focus_furnace() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", furnace_view.global_transform, 0.5)

func focus_passport() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", passport_view.global_transform, 0.5)
	_play_sfx(WOOSH_SFX, -15)

func focus_bucket() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(camera, "global_transform", bucket_view.global_transform, 0.5)
	_play_sfx(WOOSH_SFX, -15)

func unfocus() -> void:
	if rulebook.visible == true: return
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
	_play_sfx(PAPER_SFX)
	
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
		bucket.get_node("Wall").mouse_entered.connect(focus_wall_bucket)
		bucket.get_node("Wall").mouse_exited.connect(unfocus)
	
	if terrorist_spawned:
		get_tree().create_timer(3).timeout.connect(_act_terrorist)

func random_bright_color() -> Color:
	var hue = randf()
	var saturation = 0.7 + randf() * 0.3
	var value = 0.8 + randf() * 0.2
	var color = Color.from_hsv(hue, saturation, value)
	return color

func spawn_npc() -> void:	
	var npc: PathFollow3D = NPC_SCENE.instantiate()
	path.add_child(npc)
	
	current_npc_information = {
		"name": NAMES.pick_random(),
		"surname": SURNAMES.pick_random(),
		"errors": []
	}
	
	var kingdom_real = randf() > 0.4
		
	var content_legal = randf() > 0.45
	var bucket: Area3D = npc.get_node("Npc/Bucket")
	var content_model: MeshInstance3D = bucket.get_node("Content")
	var material: StandardMaterial3D = StandardMaterial3D.new()
	var fake_content
	material.disable_ambient_light = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	if content_legal:
		current_npc_information["content"] = LIQUIDS.keys().pick_random()
		material.albedo_color = LIQUIDS[current_npc_information["content"]]["color"]
	else:
		fake_content = LIQUIDS.keys().pick_random() if (randf() > 0.3 and day_handler.day > 1) else null
		if fake_content:
			current_npc_information["real_content"] = ILLEGAL_LIQUIDS.pick_random()
			current_npc_information["content"] = fake_content
			
			var real_color = LIQUIDS[current_npc_information["content"]]["color"]
			if fake_content:
				material.albedo_color = Color(
					randf_range(real_color.r-0.5, real_color.r+0.5), 
					randf_range(real_color.g-0.5, real_color.g+0.5), 
					randf_range(real_color.b-0.5, real_color.b+0.5)
				)
				print("color was faked")
				kingdom_real = true
		else:
			current_npc_information["content"] = ILLEGAL_LIQUIDS.pick_random()
		
		if not fake_content:
			material.albedo_color = Color(randf(), randf(), randf())
			
		current_npc_information["errors"].append(Utils.DENIAL_REASONS["illegal-content"])
	
	if kingdom_real:
		current_npc_information["kingdom"] = KINGDOMS.pick_random()
	else:
		current_npc_information["kingdom"] = FAKE_KINGDOMS.pick_random()
		current_npc_information["errors"].append(Utils.DENIAL_REASONS["fake-kingdom"])
	
	content_model.mesh.surface_set_material(0, material)
	var weight_legal = randi() > 0.45 or fake_content
	if weight_legal and (content_legal or fake_content):
		current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]["max"]-50, LIQUIDS[current_npc_information["content"]]["max"])
	else:
		if day_handler.day > 0:
			if content_legal:
				current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]["max"]+10, LIQUIDS[current_npc_information["content"]]["max"]+100)
			else:
				current_npc_information["content_weight"] = randi_range(70, 100)
			current_npc_information["errors"].append(Utils.DENIAL_REASONS["illegal-weight"])
		else:
			if content_legal:
				current_npc_information["content_weight"] = randi_range(LIQUIDS[current_npc_information["content"]]["max"], LIQUIDS[current_npc_information["content"]]["max"])
			else:
				current_npc_information["content_weight"] = randi_range(70, 100)

	if day_handler.day > 4:
		var explosive = randf() > 0.4
		var particles: GPUParticles3D = bucket.get_node("GPUParticles3D")
		var d_pass = particles.draw_pass_1
		var pass_material: StandardMaterial3D = StandardMaterial3D.new()
		var stickers_amount = randi_range(1, 8)
		var stickers = bucket.get_node("Stickers")
		if explosive:
			get_node("ExplosiveHintTimer").start() 
			
			var explosive_type = randf() > 0.5
			if explosive_type:
				# type 1
				var pink_sticker: Sprite3D = stickers.get_children().pick_random()
				pink_sticker.modulate = Color("#ff75e8")
				pink_sticker.visible = true
				pink_sticker.reparent(stickers.get_parent())
				var green_sticker: Sprite3D = stickers.get_children().pick_random()
				green_sticker.modulate = Color("#097969")
				green_sticker.visible = true
				green_sticker.reparent(stickers.get_parent())
				print("type 1 explosive")
				current_npc_information["errors"].append(Utils.DENIAL_REASONS["explosive1"])

				pass_material.albedo_color = Color(1, 1, 0, 0.5)
			else:
				# type 2
				current_npc_information["errors"].append(Utils.DENIAL_REASONS["explosive2"])
				stickers_amount = randi_range(1,3)
				current_npc_information["content_weight"] = randi_range(20, 45)
				pass_material.albedo_color = Color(1, 0, 0, 0.5)
				print("type 2 explosive")
				
		else:
			#no explosive
			var decpetive_bubble = randf() > 0.5
			if decpetive_bubble:
				pass_material.albedo_color = [
					Color(1, 1, 0, 0.5),
					Color(1, 0, 0, 0.5),
					Color(0, 1, 0, 0.5),
					Color(0, 0, 1, 0.5)
				].pick_random()
				
		# generate stickers
		for i in range(stickers_amount):
			var sticker = stickers.get_children().pick_random()
			sticker.modulate = random_bright_color()
			sticker.visible = true
			sticker.reparent(stickers.get_parent())
		
		d_pass.surface_set_material(0, pass_material)

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
	if is_instance_valid(animation_player):
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
	tween.tween_property(bucket, "position", Vector3(0.241, 0.738, 0.366), 1)
	await tween.finished
	scale_object.get_node("Label").text = "0 st"
	
	tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(passport, "position", Vector3(-0.073, 1, 0.192), 1)
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
	_play_sfx(STAMP_SFX)
	
	await tween.finished		
	tween = get_tree().create_tween()
	tween.tween_property(approve_stamp.get_node("Model"), "global_position", approve_stamp_initial_pos, 0.4)
	
	await (await give_items_back()).finished
	approve_stamp.block = false
	
	if (Utils.DENIAL_REASONS["explosive1"] in current_npc_information["errors"]) or (Utils.DENIAL_REASONS["explosive2"] in current_npc_information["errors"]):
		if not insurance:
			day_handler.money -= 75
			var finished = await _act_terrorist()
			await finished
			var localized_errors = []
			for error in current_npc_information["errors"]:
				localized_errors.append(tr(error))
			prompt_message(tr("mistake.fatal") % [", ".join(localized_errors)])
			return
		else:
			insurance = false
			day_handler.get_node("Insurance").visible = false
			prompt_message(tr("mistake.insurance"))
	
	tween = get_tree().create_tween()
	tween.tween_property(current_npc, "progress_ratio", 1, 4)
	var animation_player: AnimationPlayer = current_npc.get_node("Npc/Character/AnimationPlayer")
	animation_player.stop()
	animation_player.play("walk")
	
	await tween.finished
	
	if len(current_npc_information["errors"]) == 0:
		print("Correct")
		day_handler.quota += 1
		day_handler.money += correct_fare
	else:
		print("Wrong!")
		print(current_npc_information["errors"])
		
		prompt_message(tr("mistake.normal") + ", ".join(current_npc_information["errors"]))
		day_handler.money -= wrong_fare
	
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
	_play_sfx(STAMP_SFX)
	
	await tween.finished		
	tween = get_tree().create_tween()
	tween.tween_property(deny_stamp.get_node("Model"), "global_position", deny_stamp_initial_pos, 0.4)
	
	var mismatches = []
	if day_handler.day > 3:
		# reason for denial ticket
		var ticket = REASON_FOR_DENIAL_SCENE.instantiate()
		get_parent().add_child(ticket)
		var reasons = await ticket.confirmed
		if reasons == null:
			deny_stamp.block = false
			return
		for error in current_npc_information["errors"]:
			if not (error in reasons):
				mismatches.append(error)
	
	await (await give_items_back()).finished
	deny_stamp.block = false
	
	tween = get_tree().create_tween()
	tween.set_parallel(false)
	tween.tween_property(current_npc.get_node("Npc"), "rotation_degrees", Vector3(0, 180, 0), 1)
	tween.tween_property(current_npc, "progress_ratio", 0, 4)
	var animation_player: AnimationPlayer = current_npc.get_node("Npc/Character/AnimationPlayer")
	animation_player.stop()
	animation_player.play("walk")
	
	await tween.finished
	get_node("ExplosiveHintTimer").stop()
	current_npc.queue_free()
	current_npc = null

	if len(mismatches) > 0:
		print("Wrong!")
		var localized_mismatches = []
		for error in mismatches:
			localized_mismatches.append(tr(error))
		prompt_message("You made a mistake. Mismatched denial reasons, %s are missing." % [", ".join(localized_mismatches)])
		day_handler.money -= wrong_fare
		return
	
	if len(current_npc_information["errors"]) > 0:
		print("Correct")
		print(current_npc_information["errors"])
		day_handler.quota += 1
		day_handler.money += correct_fare
	else:
		print("Wrong!")
		prompt_message("You made a mistake. The stranger didn't have any issues and could pass... but you DENIED HIM!")
		day_handler.money -= wrong_fare

func _unpause_time() -> void:
	day_handler.day_timer.paused = false
	if day_handler.day >= 6:
		get_node("Furnace").process_mode = Node.PROCESS_MODE_INHERIT
	
func prompt_message(text: String) -> Signal:
	var message = MESSAGE_SCENE.instantiate()
	message.text = text
	message.on_continue.connect(_unpause_time)
	
	get_parent().add_child.call_deferred(message)
	day_handler.day_timer.paused = true
	get_node("Furnace").process_mode = Node.PROCESS_MODE_DISABLED

	return message.on_continue

func do_day_0():
	await get_tree().create_timer(1).timeout
	var on_continue = prompt_message(tr(messages.messages["warning"].text))
	await on_continue
	await get_tree().create_timer(2).timeout
	prompt_message(tr(messages.messages["intro"].text))

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
		rulebook_tab.set_tab_hidden(
			rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Explosives")), 
			true
		)
		
		Utils.SHOWING_REASONS.set(
			Utils.DENIAL_REASONS["fake-kingdom"],
			Utils.DENIAL_REASONS["fake-kingdom"]
		)
		Utils.SHOWING_REASONS.set(
			Utils.DENIAL_REASONS["illegal-content"],
			Utils.DENIAL_REASONS["illegal-content"]
		)
		
		if day_handler.day == 0:
			do_day_0()
	if day_handler.day >= 1:
		var idx = rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Weight Restrictions"))
		rulebook_tab.set_tab_hidden(idx, false)
		
		Utils.SHOWING_REASONS.set(
			Utils.DENIAL_REASONS["illegal-weight"],
			Utils.DENIAL_REASONS["illegal-weight"]
		)
		
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
	
	if day_handler.day >= 3:
		day_handler.activate_quota()
		
		if day_handler.day == 3:
			get_tree().create_timer(2).timeout.connect(
				prompt_message.bind(tr(messages.messages["day3"].text))
			)
	
	if day_handler.day == 4:
		get_tree().create_timer(2).timeout.connect(
			prompt_message.bind(tr(messages.messages["day4"].text))
		)
	
	if day_handler.day >= 5:
		rulebook_tab.set_tab_hidden(
			rulebook_tab.get_tab_idx_from_control(rulebook_tab.get_node("Explosives")), 
			false
		)
		
		Utils.SHOWING_REASONS.set(
			Utils.DENIAL_REASONS["explosive1"],
			Utils.DENIAL_REASONS["explosive1"]
		)
		Utils.SHOWING_REASONS.set(
			Utils.DENIAL_REASONS["explosive2"],
			Utils.DENIAL_REASONS["explosive2"]
		)
		
		get_node("MagicWand").visible = true
		if day_handler.day == 5:
			get_tree().create_timer(2).timeout.connect(
				prompt_message.bind(tr(messages.messages["day5"].text))
			)
	
	if day_handler.day >= 6:
		get_node("Furnace").visible = true
		get_node("Furnace").process_mode = Node.PROCESS_MODE_INHERIT
		if day_handler.day == 6:
			get_tree().create_timer(2).timeout.connect(
				prompt_message.bind(tr(messages.messages["day6"].text))
			)
			
	
	if current_npc:
		current_npc.queue_free()
		current_npc = null
		scale_object.get_node("Label").text = "0 st"
		moved_items = false

func _play_sfx(stream: AudioStream, volume: float = 0.0):
	var sound: AudioStreamPlayer = AudioStreamPlayer.new()
	sound.bus = "SFX"
	sound.volume_db = volume
	sound.stream = stream
	get_parent().add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)

func _act_terrorist() -> bool:
	get_node("ExplosiveHintTimer").stop()
	var bucket: Area3D = current_npc.get_node("Npc/Bucket")
	var particles: GPUParticles3D = bucket.get_node("GPUParticles3D")
	var explosion: Node3D = bucket.get_node("Explosion")	
	particles.emitting = true
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
	return true

func _on_npc_wait_timeout() -> void:
	if day_handler.current_time > 15 and day_handler.day == 0:
		day_handler.day_timer.paused = true
		terrorist_spawned = true
		
		rulebook.visible = false
		Engine.time_scale = 1
		
		spawn_npc()
	elif day_handler.current_time > 13 and day_handler.day == 4:
		day_handler.day_timer.paused = true
		terrorist_spawned = true
		
		rulebook.visible = false
		Engine.time_scale = 1
		
		spawn_npc()
	else:
		spawn_npc()

func _on_explosive_hint_timer_timeout() -> void:
	if current_npc and current_npc_information:
		if current_npc.progress_ratio == 0.5:
			var bucket = current_npc.get_node("Npc/Bucket")
			if  is_instance_valid(bucket):
				var particles = bucket.get_node("GPUParticles3D")
				if is_instance_valid(particles):
					particles.amount = 10
					particles.emitting = true
					await get_tree().create_timer(0.6).timeout
					particles.emitting = false
					particles.amount = 83
