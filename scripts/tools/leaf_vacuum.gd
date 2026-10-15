extends "res://scripts/tools/aimed_tool.gd"

@onready var _intake: CollisionShape2D = $IntakeArea/IntakeAreaCollider
@onready var _sound: AudioStreamPlayer2D = $VacuumSound

@export var tool_strength: float = 60.0
@export var vacuum_capacity: int = 125
@export var spew_strength: float = 140.0

var vacuum_stored: int = 0
var _stored_leaves: Array[Leaf] = []
var _spewing: Array[Leaf] = []

const _ARRIVE_DISTANCE_SQ := 4.0
const _ACTION_DELAY_SEC := 0.12

var _left_hold_sec := 0.0
var _right_hold_sec := 0.0


func _ready() -> void:
	$IntakeArea.monitoring = false


func _physics_process(delta: float) -> void:
	if GameUI.movement_locked:
		_sound.set_motor_on(false)
		_left_hold_sec = 0.0
		_right_hold_sec = 0.0
		return
	var target := _aim_point()
	_tip = _tip.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
	_aim_angle = _tip.angle()
	_place_from_tip()
	_reveal_spewed()
	var left_held := Input.is_action_pressed("mouse_left")
	var right_held := Input.is_action_pressed("mouse_right")
	var spew_ready := right_held and not left_held and not _stored_leaves.is_empty()
	var vacuum_ready := left_held and not right_held and vacuum_stored < vacuum_capacity
	if spew_ready:
		_right_hold_sec += delta
	else:
		_right_hold_sec = 0.0
	if vacuum_ready:
		_left_hold_sec += delta
	else:
		_left_hold_sec = 0.0
	var can_spew := spew_ready and _right_hold_sec >= _ACTION_DELAY_SEC
	var can_vacuum := vacuum_ready and _left_hold_sec >= _ACTION_DELAY_SEC
	var motor_on := false
	if can_spew:
		motor_on = true
		spew()
	elif can_vacuum:
		motor_on = true
		if _sound.can_vacuum_leaves():
			vacuum()
	_sound.set_motor_on(motor_on)


func vacuum() -> void:
	if vacuum_stored >= vacuum_capacity:
		return
	var intake_global := _intake.global_position
	for leaf in _leaves_in_reach():
		if _close_enough_to_store(leaf, intake_global):
			_store(leaf)
			if vacuum_stored >= vacuum_capacity:
				return
		else:
			leaf.pull_toward(intake_global, tool_strength)


func _leaves_in_reach() -> Array[Leaf]:
	var found: Array[Leaf] = []
	for area in reach_area.get_overlapping_areas():
		if area.name != "LeafArea":
			continue
		var leaf: Leaf = area.get_parent()
		if leaf == null or leaf.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		found.append(leaf)
	return found


func _close_enough_to_store(leaf: Leaf, intake_global: Vector2) -> bool:
	var to_intake := intake_global - leaf.global_position
	return to_intake.length_squared() <= _ARRIVE_DISTANCE_SQ


func _store(leaf: Leaf) -> void:
	leaf.velocity = Vector2.ZERO
	leaf.visible = false
	leaf.process_mode = Node.PROCESS_MODE_DISABLED
	_stored_leaves.append(leaf)
	vacuum_stored = _stored_leaves.size()


func spew() -> void:
	if _stored_leaves.is_empty():
		return
	var leaf: Leaf = _stored_leaves.pop_back()
	vacuum_stored = _stored_leaves.size()
	var direction := Vector2.from_angle(_aim_angle + PI / 2.0)
	var origin := _intake.global_position
	leaf.visible = false
	leaf.process_mode = Node.PROCESS_MODE_INHERIT
	leaf.global_position = origin
	leaf.reset_physics_interpolation()
	leaf.receive_gust(origin, direction, spew_strength)
	_spewing.append(leaf)


func _reveal_spewed() -> void:
	var circle := _intake.shape as CircleShape2D
	var radius := circle.radius if circle != null else 6.0
	var limit := radius * radius
	var center := _intake.global_position
	var still: Array[Leaf] = []
	for leaf in _spewing:
		if not is_instance_valid(leaf):
			continue
		if leaf.global_position.distance_squared_to(center) > limit:
			leaf.visible = true
		else:
			still.append(leaf)
	_spewing = still
