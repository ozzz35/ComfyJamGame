extends Node

@onready var music: Node = $Music
@onready var sfx: Node = $SFX

## Add a key when a clip exists, for example "yard": "res://assets/audio/music/yard.ogg"
var sounds: Dictionary = {}

var looping_music: Array[String] = []

var current_music: String = ""
var current_player: AudioStreamPlayer

signal transition_ended
signal music_ended(music_name: String)


func play_music(music_name: String, transition_duration: float = 1.0) -> void:
	if current_music == music_name or not sounds.has(music_name):
		return

	var old_player: AudioStreamPlayer = current_player
	var new_player := AudioStreamPlayer.new()
	new_player.stream = load(sounds[music_name])
	new_player.volume_db = -80.0
	new_player.bus = "Music"
	music.add_child(new_player)
	new_player.play()

	if current_player:
		current_player.finished.disconnect(on_player_stream_finished)

	current_player = new_player
	current_music = music_name
	current_player.finished.connect(on_player_stream_finished)

	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(new_player, "volume_db", 0.0, transition_duration).set_delay(transition_duration * 0.15)
	if is_instance_valid(old_player):
		tween.tween_property(old_player, "volume_db", -80.0, transition_duration / 2.0).set_delay(transition_duration / 2.0)

	await tween.finished

	if is_instance_valid(old_player):
		old_player.queue_free()

	transition_ended.emit()


func on_player_stream_finished() -> void:
	if looping_music.has(current_music):
		current_player.play()
	else:
		music_ended.emit(current_music)


func play_sfx(sfx_key: String, change_pitch: bool = true, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not sounds.has(sfx_key):
		return null
	var new_player := AudioStreamPlayer.new()
	_play(new_player, sfx_key, volume_db, change_pitch)
	return new_player


func play_sfx_2d(sfx_key: String, world_position: Vector2, change_pitch: bool = true, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	if not sounds.has(sfx_key):
		return null
	var new_player := AudioStreamPlayer2D.new()
	new_player.global_position = world_position
	new_player.max_distance = 2000.0
	_play(new_player, sfx_key, volume_db, change_pitch)
	return new_player


func _play(player: Node, sfx_key: String, volume_db: float, change_pitch: bool) -> void:
	player.bus = "SFX"
	player.stream = load(sounds[sfx_key])
	player.volume_db = volume_db
	if change_pitch:
		player.pitch_scale = randf_range(0.8, 1.2)
	sfx.add_child(player)
	player.play()
	player.finished.connect(func() -> void: player.queue_free())


func set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_error("Audio bus not found: " + bus_name)
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
