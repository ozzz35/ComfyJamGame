extends Node

const STREAM_CLICK := preload("res://assets/audio/sfx/ui/click.wav")
const STREAM_BACK := preload("res://assets/audio/sfx/ui/back.wav")
const STREAM_HOVER := preload("res://assets/audio/sfx/ui/hover.mp3")
const STREAM_SLIDER_RIGHT := preload("res://assets/audio/sfx/ui/slider_1.wav")
const STREAM_SLIDER_LEFT := preload("res://assets/audio/sfx/ui/slider_2.wav")

@onready var _click: AudioStreamPlayer = $Click
@onready var _back: AudioStreamPlayer = $Back
@onready var _hover: AudioStreamPlayer = $Hover
@onready var _slider_right: AudioStreamPlayer = $SliderA
@onready var _slider_left: AudioStreamPlayer = $SliderB

const SLIDER_SOUND_MIN_INTERVAL_SEC := 0.14

var _last_slider_sound_ms: int = -1000


func _ready() -> void:
	_click.stream = STREAM_CLICK
	_back.stream = STREAM_BACK
	_hover.stream = STREAM_HOVER
	_slider_right.stream = STREAM_SLIDER_RIGHT
	_slider_left.stream = STREAM_SLIDER_LEFT


func play_click() -> void:
	_play_one_shot(_click)


func play_back() -> void:
	_play_one_shot(_back)


func play_hover() -> void:
	_play_one_shot(_hover)


func play_slider_right() -> void:
	_play_slider_direction(true)


func play_slider_left() -> void:
	_play_slider_direction(false)


func _play_slider_direction(right: bool) -> void:
	var now_ms := Time.get_ticks_msec()
	var min_gap_ms := int(SLIDER_SOUND_MIN_INTERVAL_SEC * 1000.0)
	if now_ms - _last_slider_sound_ms < min_gap_ms:
		return
	_last_slider_sound_ms = now_ms
	_play_one_shot(_slider_right if right else _slider_left, false)


func _play_one_shot(player: AudioStreamPlayer, stop_before_play: bool = true) -> void:
	if player.stream == null:
		return
	if stop_before_play:
		player.stop()
	player.play()
