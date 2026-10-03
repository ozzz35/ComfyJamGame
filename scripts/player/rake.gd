extends Sprite2D

@onready var base: PlayerBase = $".."
var rake_strength: int = 500
@onready var reach_area: Area2D = $ReachArea

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_left"):
		rake()

func _physics_process(delta: float) -> void:
	_update_position()

func rake():
	for node in reach_area.get_overlapping_areas():
		if node.name == "LeafArea":
			var leaf: Leaf = node.get_parent()
			var dir: Vector2 = global_position - base.global_position
			leaf.receive_gust(global_position, dir, rake_strength)

func _update_position():
	const MIN_DIST := 80.0
	const MAX_DIST := 230.0
	const FULL_RANGE := 400.0
	
	var to_mouse := get_global_mouse_position() - base.global_position
	
	var t := clampf(to_mouse.length() / FULL_RANGE, 0.0, 1.0)
	
	var eased := smoothstep(0.0, 1.0, t)
	
	var distance := lerpf(MIN_DIST, MAX_DIST, eased)
	global_position = base.global_position + to_mouse.normalized() * distance
