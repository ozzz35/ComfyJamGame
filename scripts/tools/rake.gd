extends Sprite2D

@onready var player: PlayerBase = $".."
@onready var reach_area: Area2D = $ReachArea

var rake_strength: float = 50.0
var sweeping := false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left"):
		sweep()


func _physics_process(delta: float) -> void:
	if not sweeping:
		_follow_mouse(delta)
	if position.length_squared() > 0.001:
		rotation = position.angle()


func _follow_mouse(delta: float) -> void:
	var hold := _hold_position()
	position = position.lerp(hold, clampf(delta * 10.0, 0.0, 1.0))


func _hold_position() -> Vector2:
	var to_mouse := get_global_mouse_position() - player.global_position
	if to_mouse == Vector2.ZERO:
		return position if position.length_squared() > 0.001 else Vector2.RIGHT * 22.0
	var reach := clampf(to_mouse.length() / 280.0, 0.0, 1.0)
	return to_mouse.normalized() * lerpf(22.0, 50.0, reach)


func sweep() -> void:
	if sweeping:
		return
	sweeping = true
	var hold := _hold_position()
	var facing := hold.normalized()
	var distance := hold.length()
	var tween := create_tween()
	tween.tween_property(self, "position", facing.rotated(-0.35) * distance, 0.07)
	tween.tween_property(self, "position", facing.rotated(0.55) * distance, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_rake_leaves)
	tween.tween_property(self, "position", hold, 0.08)
	tween.finished.connect(_end_sweep)


func _rake_leaves() -> void:
	if position.length_squared() > 0.001:
		rotation = position.angle()
	var toward_player := player.global_position - global_position
	if toward_player == Vector2.ZERO:
		return
	var push := (Vector2.from_angle(global_rotation + PI / 2.0) + toward_player.normalized() * 0.5).normalized()
	for area in reach_area.get_overlapping_areas():
		if area.name != "LeafArea":
			continue
		var leaf: Leaf = area.get_parent()
		leaf.receive_gust(global_position, push, rake_strength)


func _end_sweep() -> void:
	sweeping = false
