class_name PlayerBase extends CharacterBody2D

@onready var movement_comp: Node2D = $MovementComp
@onready var rake: Sprite2D = $Rake

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir = (global_position - mouse_pos).normalized()
	var dir_radiants = dir.angle()
	rake.global_position = global_position + -Vector2(cos(dir_radiants) * 200, sin(dir_radiants) * 200)
