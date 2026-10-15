extends AudioStreamPlayer2D

enum Phase { OFF, LOOP, ENDING }

@export var blower_loop: AudioStream
@export var blower_end: AudioStream

var _wants_on := false
var _phase := Phase.OFF


func _ready() -> void:
	finished.connect(_on_finished)


func _process(_delta: float) -> void:
	var tool := get_parent()
	if tool.process_mode == Node.PROCESS_MODE_DISABLED and (_wants_on or _phase != Phase.OFF):
		set_blowing(false)


func set_blowing(on: bool) -> void:
	if on == _wants_on:
		return
	_wants_on = on
	if on:
		_start_loop()
	else:
		_stop_loop()


func _start_loop() -> void:
	if _phase == Phase.LOOP:
		return
	if _phase == Phase.ENDING:
		stop()
	if blower_loop == null:
		return
	stream = blower_loop
	_phase = Phase.LOOP
	play()


func _stop_loop() -> void:
	if _phase != Phase.LOOP:
		return
	_play_end()


func _play_end() -> void:
	if blower_end == null:
		_phase = Phase.OFF
		stop()
		return
	stream = blower_end
	_phase = Phase.ENDING
	play()


func _on_finished() -> void:
	match _phase:
		Phase.LOOP:
			if _wants_on:
				play()
		Phase.ENDING:
			_phase = Phase.OFF
			if _wants_on:
				_start_loop()
