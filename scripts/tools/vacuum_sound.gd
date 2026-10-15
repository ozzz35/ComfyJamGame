extends AudioStreamPlayer2D

enum Phase { OFF, STARTUP, LOOP, ENDING }

@export var vacuum_startup: AudioStream
@export var vacuum_loop: AudioStream
@export var vacuum_end: AudioStream

var _phase := Phase.OFF
var _wants_on := false
var _startup_to_end := false

const STARTUP_SKIP_SEC := 0.2


func _ready() -> void:
	finished.connect(_on_finished)


func _process(_delta: float) -> void:
	var tool := get_parent()
	if tool.process_mode == Node.PROCESS_MODE_DISABLED and (_wants_on or _phase != Phase.OFF):
		set_motor_on(false)


func can_vacuum_leaves() -> bool:
	return _wants_on and (_phase == Phase.LOOP)


func set_motor_on(on: bool) -> void:
	if on == _wants_on:
		return
	_wants_on = on
	if on:
		_motor_start()
	else:
		_motor_stop()


func _motor_start() -> void:
	if _phase == Phase.LOOP:
		return
	if _phase == Phase.STARTUP:
		_startup_to_end = false
		return
	stop()
	_startup_to_end = false
	_play_startup()


func _motor_stop() -> void:
	match _phase:
		Phase.STARTUP:
			_startup_to_end = true
		Phase.LOOP:
			_play_end()
		_:
			pass


func _play_startup() -> void:
	if vacuum_startup == null:
		_play_loop()
		return
	stream = vacuum_startup
	_phase = Phase.STARTUP
	var start_at := STARTUP_SKIP_SEC
	var length := vacuum_startup.get_length()
	if length > 0.0 and start_at >= length - 0.05:
		_play_loop()
		return
	play(start_at)


func _play_loop() -> void:
	if vacuum_loop == null:
		_phase = Phase.OFF
		return
	stop()
	stream = vacuum_loop
	_phase = Phase.LOOP
	play()


func _play_end() -> void:
	if vacuum_end == null:
		_phase = Phase.OFF
		stop()
		return
	stream = vacuum_end
	_phase = Phase.ENDING
	play()


func _on_finished() -> void:
	match _phase:
		Phase.STARTUP:
			if _wants_on and not _startup_to_end:
				_play_loop()
			else:
				_startup_to_end = false
				_play_end()
		Phase.LOOP:
			if _wants_on:
				play()
		Phase.ENDING:
			_phase = Phase.OFF
			if _wants_on:
				_motor_start()
