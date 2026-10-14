extends AudioStreamPlayer2D

@export var sweeps: Array[AudioStream]

var last_index: int = -1


func play_sweep() -> void:
	if sweeps.is_empty():
		return
	var index := randi_range(0, sweeps.size() - 1)
	while sweeps.size() > 1 and index == last_index:
		index = randi_range(0, sweeps.size() - 1)
	stream = sweeps[index]
	pitch_scale = randf_range(0.94, 1.06)
	play()
	last_index = index
