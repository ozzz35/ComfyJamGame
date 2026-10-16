extends Node

@export_enum("menu", "hub", "yard_stroll", "yard_sunset", "battle") var music_key: String = "hub"


func _ready() -> void:
	Audio.play_music(music_key)
