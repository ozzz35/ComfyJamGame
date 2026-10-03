class_name Leaf extends Node2D

var velocity := Vector2.ZERO
var drag := 4.0

func _physics_process(delta):
	position += velocity * delta
	velocity *= exp(-drag * delta)
	if velocity.length() < 5.0:
		velocity = Vector2.ZERO

func receive_gust(origin: Vector2, direction: Vector2, strength: float):
	if direction == Vector2.ZERO:
		return
	var target := direction.normalized() * strength
	velocity = velocity.lerp(target, 0.3)
