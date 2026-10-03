extends Node2D

@onready var base : PlayerBase = get_parent()

var speed : int = 430
var acceleration := 3000.0
var friction := 2600.0
var input_vector = Vector2.ZERO

var knockback_strength : int = 40
var knockback_friction : float = 700.0
var knockback_velocity : Vector2 = Vector2.ZERO

var can_recieve_input : bool = true

## Components
#@onready var movement_component: Node2D = $"../movement_component"
#@onready var combat_component: Node2D = $"../combat_component"
#@onready var animation_component: Node2D = $"../animation_component"
#@onready var state_machine: StateMachine = $"../state_machine"

func _physics_process(delta: float) -> void:
	if not can_recieve_input:
		return
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		base.velocity = base.velocity.move_toward(input_vector * speed, delta * acceleration)
	else:
		base.velocity = base.velocity.move_toward(Vector2.ZERO, delta * friction)
	
	
	base.velocity += knockback_velocity
	
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_friction * delta
	)
	
	base.move_and_slide()

func apply_knockback(from_position: Vector2):
	var dir = (global_position - from_position).normalized()
	knockback_velocity = dir * knockback_strength
