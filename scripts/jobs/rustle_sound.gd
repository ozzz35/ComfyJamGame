class_name RustleSound
extends AudioStreamPlayer2D

@export var rustles: Array[AudioStream]

const MAX_AT_ONCE := 50
const CLAIM_GRACE_MSEC := 100
const COOLDOWN_MSEC := 140
const LOUDNESS_OF := 6.0
static var _holders: Array[int] = []
static var _applied_count := -1

var last_index: int = -1
var _holding := false
var _claimed_msec := 0
var _last_rustle_msec := -100000


static func active_count() -> int:
	return _holders.size()


func play_rustle() -> void:
	if rustles.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - _last_rustle_msec < COOLDOWN_MSEC:
		return
	_drop_finished()
	if _holding or _holders.size() >= MAX_AT_ONCE:
		return
	var index := randi_range(0, rustles.size() - 1)
	while rustles.size() > 1 and index == last_index:
		index = randi_range(0, rustles.size() - 1)
	stream = rustles[index]
	pitch_scale = randf_range(0.94, 1.06)
	_holding = true
	_claimed_msec = Time.get_ticks_msec()
	_holders.append(get_instance_id())
	_match_loudness()
	play()
	_last_rustle_msec = now
	last_index = index


func _drop_finished() -> void:
	var now := Time.get_ticks_msec()
	var live: Array[int] = []
	for id in _holders:
		var player := instance_from_id(id) as AudioStreamPlayer2D
		if player == null:
			continue
		var claimed_at: int = player._claimed_msec
		var still_claimed: bool = player.playing or now - claimed_at < CLAIM_GRACE_MSEC
		if still_claimed:
			live.append(id)
			continue
		player._holding = false
	_holders = live
	_match_loudness()


func _match_loudness() -> void:
	var count := _holders.size()
	if count == _applied_count:
		return
	_applied_count = count
	if count == 0:
		return
	var gain := minf(1.0, sqrt(LOUDNESS_OF / float(count)))
	var db := linear_to_db(gain)
	for id in _holders:
		var player := instance_from_id(id) as AudioStreamPlayer2D
		if player:
			player.volume_db = db
