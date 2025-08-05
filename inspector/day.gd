extends Control

@onready var day_label: Label = get_node("Day")
@onready var time_label: Label = get_node("Time")
@onready var blocker_panel: Panel = get_node("Panel")
@onready var day_timer: Timer = get_node("DayCycle")

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func format_time(decimal_hours: float) -> String:
	var hours = floor(decimal_hours)
	var minutes = floor((decimal_hours - hours) * 60)
	return "%02d:%02d" % [hours, minutes]

var current_time = 0
func _process(delta: float) -> void:
	current_time = round_to_dec(remap(day_timer.wait_time-day_timer.time_left, 0, day_timer.wait_time, 9, 18), 2)
	time_label.text = format_time(current_time)

var day = 0
signal day_started

func reset_day() -> void:
	if process_mode == Node.PROCESS_MODE_DISABLED: return
	
	blocker_panel.modulate = Color(1, 1, 1, 0)
	blocker_panel.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(blocker_panel, "modulate", Color(1, 1, 1, 1), 1.5)
	await tween.finished
	await get_tree().create_timer(3).timeout
	
	day += 1
	day_label.text = "DAY " + str(day)
	day_timer.start()
	day_started.emit()
	
	tween = get_tree().create_tween()
	tween.tween_property(blocker_panel, "modulate", Color(1, 1, 1, 0), 1.5)
	await tween.finished
	blocker_panel.visible = false

func _ready() -> void:
	day_timer.start()
	day_timer.timeout.connect(reset_day)
