class_name Leaf extends Node2D

var velocity := Vector2.ZERO
var drag := 4.0

func _physics_process(delta: float) -> void:
	position += velocity * delta
	velocity *= exp(-drag * delta)
	if velocity.length() < 5.0:
		velocity = Vector2.ZERO

func receive_gust(direction: Vector2, strength: float) -> void:
	if direction == Vector2.ZERO:
		return
	var gust_velocity := direction.normalized() * strength
	velocity = velocity.lerp(gust_velocity, 0.3)
