class_name Leaf extends Node2D
var velocity : Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var slowdown : int = 60
var gone : bool = false
var job : Node2D

const angular_drag: float = 16.0
const GUST_GAP_MSEC := 55

var _next_gust_msec := 0

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
	set_physics_process(false)

func _physics_process(delta):
	status_check()
	position += velocity * delta
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


func status_check():
	if velocity == Vector2.ZERO:
		return
	if job.contains_world_point(global_position):
		return
	job.leaf_removed()
	queue_free()
