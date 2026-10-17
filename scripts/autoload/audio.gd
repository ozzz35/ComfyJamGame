extends Node

@onready var music: Node = $Music
@onready var sfx: Node = $SFX

var sounds: Dictionary = {}

var looping_music: Array[String] = []

var current_music: String = ""
var current_player: AudioStreamPlayer
var _playlist: Array[String] = []
var _playlist_index: int = 0
var _crossfade_tween: Tween
var _vanish_player: AudioStreamPlayer
var _vanish_playback: AudioStreamGeneratorPlayback
var _vanish_audio_active := false
var _vanish_phase := 0.0

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_CROSSFADE := 2.0
const DEFAULT_MUSIC_LINEAR := 0.4
const VANISH_TARGET_DB := -4.0
const VANISH_DIALOGUE_DB := -14.0

signal transition_ended
signal music_ended(music_name: String)


func _ready() -> void:
	_register_music_tracks()
	_load_saved_settings()


func _register_music_tracks() -> void:
	for key: String in MusicTracks.TRACKS:
		sounds[key] = MusicTracks.TRACKS[key]
	looping_music.assign(MusicTracks.LOOP)


func _load_saved_settings() -> void:
	var cfg := _read_settings_file()
	if cfg == null:
		apply_audio_levels(1.0, DEFAULT_MUSIC_LINEAR, 1.0)
		apply_vsync(true)
		return
	apply_audio_levels(
		float(cfg.get_value("audio", "master", 1.0)),
		float(cfg.get_value("audio", "music", DEFAULT_MUSIC_LINEAR)),
		float(cfg.get_value("audio", "sfx", 1.0)),
	)
	apply_vsync(bool(cfg.get_value("display", "vsync", true)))


func _read_settings_file() -> ConfigFile:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return null
	return cfg


func read_audio_levels() -> Vector3:
	var cfg := _read_settings_file()
	if cfg == null:
		return Vector3(1.0, DEFAULT_MUSIC_LINEAR, 1.0)
	return Vector3(
		float(cfg.get_value("audio", "master", 1.0)),
		float(cfg.get_value("audio", "music", DEFAULT_MUSIC_LINEAR)),
		float(cfg.get_value("audio", "sfx", 1.0)),
	)


func read_vsync() -> bool:
	var cfg := _read_settings_file()
	if cfg == null:
		return true
	return bool(cfg.get_value("display", "vsync", true))


func persist_settings(master: float, music: float, sfx: float, vsync: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master", master)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("display", "vsync", vsync)
	cfg.save(SETTINGS_PATH)


func apply_audio_levels(master: float, music: float, sfx: float) -> void:
	set_bus_volume("Master", master)
	set_bus_volume("Music", music)
	set_bus_volume("SFX", sfx)


func apply_vsync(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)


func start_music_playlist(track_keys: Array[String], transition_duration: float = DEFAULT_CROSSFADE) -> void:
	if track_keys.is_empty():
		return
	_playlist = track_keys.duplicate()
	_playlist_index = 0
	play_music(_playlist[0], transition_duration, true)


func play_music(music_name: String, transition_duration: float = DEFAULT_CROSSFADE, keep_playlist: bool = false) -> void:
	if not keep_playlist:
		_playlist.clear()
		_playlist_index = 0
	if current_music == music_name or not sounds.has(music_name):
		return

	var stream := _music_stream_for(music_name)
	if stream == null:
		return

	var old_player: AudioStreamPlayer = current_player
	var new_player := AudioStreamPlayer.new()
	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.bus = "Music"
	music.add_child(new_player)
	new_player.play()

	if is_instance_valid(old_player) and old_player.finished.is_connected(on_player_stream_finished):
		old_player.finished.disconnect(on_player_stream_finished)

	current_player = new_player
	current_music = music_name
	current_player.finished.connect(on_player_stream_finished)

	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_crossfade_tween.tween_property(new_player, "volume_db", 0.0, transition_duration)
	if is_instance_valid(old_player):
		_crossfade_tween.tween_property(old_player, "volume_db", -80.0, transition_duration)
	_crossfade_tween.finished.connect(func() -> void:
		if is_instance_valid(old_player):
			old_player.stop()
			old_player.queue_free()
		transition_ended.emit()
	, CONNECT_ONE_SHOT)


func set_music_paused(paused: bool) -> void:
	if current_player == null or not is_instance_valid(current_player):
		return
	current_player.stream_paused = paused


func crossfade_music_volume(target_db: float, transition_duration: float = DEFAULT_CROSSFADE) -> void:
	if current_player == null or not is_instance_valid(current_player):
		return
	current_player.stream_paused = false
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_crossfade_tween.tween_property(current_player, "volume_db", target_db, transition_duration)


func begin_remnant_vanish_audio(at_db: float = VANISH_TARGET_DB) -> void:
	_ensure_vanish_player()
	_vanish_phase = randf() * TAU
	_vanish_player.volume_db = at_db
	_vanish_player.play()
	_vanish_playback = _vanish_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_vanish_audio_active = true


func end_remnant_vanish_audio() -> void:
	_vanish_audio_active = false
	if is_instance_valid(_vanish_player):
		_vanish_player.stop()
	_vanish_playback = null


func _ensure_vanish_player() -> void:
	if is_instance_valid(_vanish_player):
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.15
	_vanish_player = AudioStreamPlayer.new()
	_vanish_player.stream = generator
	_vanish_player.bus = "SFX"
	_vanish_player.volume_db = VANISH_TARGET_DB
	sfx.add_child(_vanish_player)


func _process(_delta: float) -> void:
	if not _vanish_audio_active or _vanish_playback == null:
		return
	var frames_available := _vanish_playback.get_frames_available()
	if frames_available < 1:
		return
	var frames := PackedVector2Array()
	frames.resize(frames_available)
	var mix_rate := 44100.0
	for i in frames_available:
		_vanish_phase += 1.0 / mix_rate
		var hum := sin(_vanish_phase * 47.0) * 0.06 + sin(_vanish_phase * 113.0) * 0.04
		var hiss := randf_range(-1.0, 1.0) * 0.18
		if randf() < 0.018:
			hiss += randf_range(-1.0, 1.0) * 0.65
		if randf() < 0.004:
			hiss = 0.0
		var sample := clampf(hiss + hum, -1.0, 1.0)
		var wobble := randf_range(0.85, 1.15)
		frames[i] = Vector2(sample, sample * wobble)
	_vanish_playback.push_buffer(frames)


func stop_music(transition_duration: float = DEFAULT_CROSSFADE) -> void:
	_playlist.clear()
	_playlist_index = 0
	if current_player == null or not is_instance_valid(current_player):
		current_music = ""
		return
	var old_player: AudioStreamPlayer = current_player
	current_player = null
	current_music = ""
	if old_player.finished.is_connected(on_player_stream_finished):
		old_player.finished.disconnect(on_player_stream_finished)
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(old_player, "volume_db", -80.0, transition_duration)
	_crossfade_tween.finished.connect(func() -> void:
		old_player.stop()
		old_player.queue_free()
	, CONNECT_ONE_SHOT)


func on_player_stream_finished() -> void:
	if _playlist.size() > 0:
		_playlist_index = (_playlist_index + 1) % _playlist.size()
		play_music(_playlist[_playlist_index], DEFAULT_CROSSFADE, true)
		return
	if looping_music.has(current_music):
		return
	music_ended.emit(current_music)


func _music_stream_for(music_name: String) -> AudioStream:
	var stream: AudioStream = load(sounds[music_name])
	if stream == null:
		return null
	stream = stream.duplicate()
	if not looping_music.has(music_name):
		return stream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	return stream


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
