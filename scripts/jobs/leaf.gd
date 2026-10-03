extends Node2D
var velocity = Vector2.ZERO
var slowdown = 60

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, slowdown * delta)

func receive_gust(origin: Vector2, direction: Vector2, strength: float):
	if direction == Vector2.ZERO:
		return
	velocity += direction.normalized() * strength
