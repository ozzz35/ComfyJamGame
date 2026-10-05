extends Node2D
var velocity : Vector2 = Vector2.ZERO
var slowdown : int = 60

const LEAF_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/environment/leaves/leaf_1.png"),
	preload("res://assets/art/environment/leaves/leaf_2.png"),
	preload("res://assets/art/environment/leaves/leaf_3.png"),
]

@onready var graphic: Sprite2D = $Graphic

func _ready() -> void:
	graphic.texture = LEAF_TEXTURES.pick_random()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, slowdown * delta)

func receive_gust(_origin: Vector2, direction: Vector2, strength: float):
	if direction == Vector2.ZERO:
		return
	velocity += direction.normalized() * strength
