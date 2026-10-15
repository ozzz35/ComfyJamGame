class_name Leaf extends Node2D
var velocity : Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var slowdown : int = 60
var job : Node2D

const angular_drag: float = 16.0
const GUST_GAP_MSEC := 55
const FENCE_MASK := 32

var _next_gust_msec := 0
var _blocker_shape := RectangleShape2D.new()

const LEAF_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/environment/leaves/leaf_1.png"),
	preload("res://assets/art/environment/leaves/leaf_2.png"),
	preload("res://assets/art/environment/leaves/leaf_3.png"),
]

@onready var graphic: Sprite2D = $Graphic

func _ready() -> void:
	graphic.texture = LEAF_TEXTURES.pick_random()
	var node := get_parent()
	while node:
		if node.has_method("contains_world_point"):
			job = node
			break
		node = node.get_parent()
	_blocker_shape.size = Vector2(6, 6)
	set_physics_process(false)

func _physics_process(delta):
	status_check()
	_move_against_fences(delta)
	velocity = velocity.move_toward(Vector2.ZERO, slowdown * delta)
	graphic.rotation += angular_velocity * delta
	angular_velocity = move_toward(angular_velocity, 0.0, angular_drag * delta)
	if velocity == Vector2.ZERO and angular_velocity == 0.0:
		set_physics_process(false)


func receive_gust(_origin: Vector2, direction: Vector2, strength: float):
	if direction == Vector2.ZERO:
		return
	var now := Time.get_ticks_msec()
	if now < _next_gust_msec:
		return
	_next_gust_msec = now + GUST_GAP_MSEC
	set_physics_process(true)
	var spread_direction := direction.rotated(randf_range(-0.45, 0.45))
	var varied_strength := strength * randf_range(0.68, 1.24)
	velocity = spread_direction.normalized() * varied_strength
	angular_velocity += randf_range(-7.5, 7.5)
	_play_rustle()


func pull_toward(point: Vector2, strength: float) -> void:
	var to_point := point - global_position
	if to_point.length_squared() <= 4.0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		return
	set_physics_process(true)
	velocity = to_point.normalized() * strength
	angular_velocity += randf_range(-3.0, 3.0)
	_play_rustle()

func _play_rustle() -> void:
	var rustle := get_node_or_null("RustleSound")
	if rustle:
		rustle.play_rustle()


func _move_against_fences(delta: float) -> void:
	var remaining := velocity * delta
	if remaining.length_squared() <= 0.000001:
		return
	var space := get_world_2d().direct_space_state
	for _attempt in 2:
		if remaining.length_squared() <= 0.000001:
			return
		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = _blocker_shape
		params.transform = Transform2D(0.0, global_position)
		params.motion = remaining
		params.collision_mask = FENCE_MASK
		params.collide_with_areas = false
		params.collide_with_bodies = true
		var fractions := space.cast_motion(params)
		var safe: float = fractions[0]
		global_position += remaining * safe
		if safe >= 1.0:
			return
		var normal := _fence_normal(space, remaining)
		if normal == Vector2.ZERO:
			velocity = Vector2.ZERO
			return
		velocity = velocity.slide(normal)
		remaining = velocity * delta * (1.0 - safe)


func _fence_normal(space: PhysicsDirectSpaceState2D, motion: Vector2) -> Vector2:
	var probe := PhysicsShapeQueryParameters2D.new()
	probe.shape = _blocker_shape
	probe.collision_mask = FENCE_MASK
	probe.collide_with_areas = false
	probe.collide_with_bodies = true
	probe.transform = Transform2D(0.0, global_position + motion.normalized() * 2.0)
	var info := space.get_rest_info(probe)
	if info.is_empty():
		return Vector2.ZERO
	return info.normal


func status_check():
	if velocity == Vector2.ZERO:
		return
	if job.contains_world_point(global_position):
		return
	job.leaf_removed()
	queue_free()
