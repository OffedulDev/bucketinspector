extends AudioStreamPlayer

@export var loops: Array[AudioStream] = []
var current_loop: int = 0

func change_loop(idx: int) -> void:
	stream = loops[idx]
	play()

func _on_finished() -> void:
	current_loop += 1
	if current_loop >= len(loops):
		current_loop = 0
		
	change_loop(current_loop)

func _ready() -> void:
	_on_finished()
	play()
