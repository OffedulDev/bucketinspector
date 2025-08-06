extends Control

@export_file("*.tscn") var next_scene : String
@export var images : Array[Texture2D]
@export_group("Animation")
@export var fade_in_time : float = 0.2
@export var fade_out_time : float = 0.2
@export var visible_time : float = 1.6
@export_group("Transition")
@export var start_delay : float = 0.5
@export var end_delay : float = 0.5
@export var show_loading_screen : bool = false

var tween : Tween
var next_image_index : int = 0

func _load_next_scene() -> void:
	var status = SceneLoader.get_status()
	if show_loading_screen or status != ResourceLoader.THREAD_LOAD_LOADED:
		SceneLoader.change_scene_to_loading_screen()
	else:
		SceneLoader.change_scene_to_resource()

func _ready() -> void:
	SceneLoader.load_scene(next_scene, true)	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_load_next_scene()

func _on_video_stream_player_finished() -> void:
	_load_next_scene()
