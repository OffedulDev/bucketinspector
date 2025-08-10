# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Control

const MAIN_MENU_SCENE = "res://scenes/menus/main_menu/main_menu_with_animations.tscn"
const CASH_SFX = preload("res://scenes/inspector/cash.mp3")

@onready var day_label: Label = get_node("Day")
@onready var time_label: Label = get_node("Time")
@onready var topbar_balance: Label = get_node("Balance")
@onready var blocker_panel: PanelContainer = get_node("Panel")
@onready var day_timer: Timer = get_node("DayCycle")
@onready var directional_light: DirectionalLight3D = get_parent().get_node("DirectionalLight3D")
@onready var inspector = get_parent().get_node("Inspector")

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func format_time(decimal_hours: float) -> String:
	var hours = floor(decimal_hours)
	var minutes = floor((decimal_hours - hours) * 60)
	return "%02d:%02d" % [hours, minutes]

var money = 60:
	set(value):
		today_earnings += (money-value)
		money = value
		topbar_balance.text = "€" + str(value)
		inspector._play_sfx(CASH_SFX, -5)

var current_time = 0
signal _accepted
signal _free
func _process(delta: float) -> void:
	current_time = round_to_dec(remap(day_timer.wait_time-day_timer.time_left, 0, day_timer.wait_time, 9, 18), 2)
	time_label.text = format_time(current_time)
	directional_light.rotation_degrees = Vector3(
		remap(day_timer.wait_time-day_timer.time_left, 0, day_timer.wait_time, -0.156, -160),
		0,
		0
	)
	if Input.is_action_just_pressed("ui_accept"):
		_accepted.emit()
	
	if get_parent().get_node("Inspector").current_npc == null:
		_free.emit()

var day = 0
var today_earnings = 0
var waiting = false

@onready var quota_label = get_node("Quota")
@onready var strikes_label = quota_label.get_node("Strikes")
var strikes = 0:
	set(value):
		strikes = value
		strikes_label.text = str(value) + " " + tr("strikes")
var daily_quota = 0:
	set(value):
		daily_quota = value
		quota_label.text = "Quota: " + str(quota) + "/" + str(daily_quota) 
var quota = 0:
	set(value):
		quota = value
		quota_label.text = "Quota: " + str(value) + "/" + str(daily_quota) 
var quota_activated = false

func activate_quota() -> void:
	quota_activated = true
	quota_label.visible = true
	
signal day_started

func update_blocker() -> void:
	var vbox = blocker_panel.get_node("MarginContainer/VBoxContainer")
	var title = vbox.get_node("Title")
	var earnings = vbox.get_node("Earnings")
	var balance = vbox.get_node("Balance")
	
	title.text = "END OF DAY " + str(day)
	earnings.text = "€" + str(today_earnings)
	today_earnings = 0
	balance.text = "€" + str(money)
	

func reset_day(bypass: bool = false) -> void:
	if waiting == true: return
	if process_mode == Node.PROCESS_MODE_DISABLED and bypass == false: return
	if (get_parent().get_node("Inspector").current_npc != null) and bypass == false:
		waiting = true
		await _free
		waiting = false
	
	blocker_panel.modulate = Color(1, 1, 1, 0)
	blocker_panel.visible = true
	update_blocker()
	var tween = get_tree().create_tween()
	tween.tween_property(blocker_panel, "modulate", Color(1, 1, 1, 1), 0.5)
	await tween.finished
	
	if quota_activated:
		if quota < daily_quota:
			if strikes == 3:
				await inspector.prompt_message(tr("game_over.strikes"))
				get_tree().paused = false
				SceneLoader.load_scene(MAIN_MENU_SCENE)
			else:
				await inspector.prompt_message(tr("striked"))
				strikes += 1
	
	await _accepted
	
	day += 1
	day_timer.wait_time += 10
	day_label.text = tr("day_label") % [str(day)]
	day_timer.start()
	day_started.emit()
	daily_quota = randi_range(day-2, day+1)
	quota = 0
	
	tween = get_tree().create_tween()
	tween.tween_property(blocker_panel, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	blocker_panel.visible = false
	
	SaveHandler.save(day, money)

func load_save() -> void:
	var content = SaveHandler.load_save()
	day = int(content["day"])
	money = int(content["money"])
	day_label.text = tr("day_label").format(str(day))
	day_timer.wait_time += day*10

func _ready() -> void:
	if SaveHandler.wants_to_load:
		load_save()
		
	day_timer.start()
	day_timer.timeout.connect(reset_day)
	day_label.text = tr("day_label") % [str(day)]
	topbar_balance.text = "€" + str(money)
	daily_quota = randi_range(int(day/2), day+1)
	
