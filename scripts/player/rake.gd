extends Sprite2D

@onready var player: PlayerBase = $".."
@onready var reach_area: Area2D = $ReachArea

var rake_strength: int = 500

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left"):
		rake()

func _physics_process(_delta: float) -> void:
	_update_position()

func rake() -> void:
	for area in reach_area.get_overlapping_areas():
		if area.name != "LeafArea":
			continue
		var leaf: Leaf = area.get_parent()
		var push_direction: Vector2 = global_position - player.global_position
		leaf.receive_gust(push_direction, rake_strength)

func _update_position() -> void:
	const minimum_distance := 80.0
	const maximum_distance := 230.0
	const full_mouse_range := 400.0

	var to_mouse := get_global_mouse_position() - player.global_position
	if to_mouse == Vector2.ZERO:
		return

	var mouse_range := clampf(to_mouse.length() / full_mouse_range, 0.0, 1.0)
	var eased_range := smoothstep(0.0, 1.0, mouse_range)
	var distance_from_player := lerpf(minimum_distance, maximum_distance, eased_range)
	global_position = player.global_position + to_mouse.normalized() * distance_from_player
