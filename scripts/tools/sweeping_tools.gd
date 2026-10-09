extends Sprite2D

@onready var player: PlayerBase = $"../.."
@onready var reach_area: Area2D = $ReachArea
@onready var _reach_shape: CollisionShape2D = $ReachArea/ReachAreaCollider

@export var tool_strength: float = 50.0
var sweeping := false
var _tip := Vector2.RIGHT * 22.0
var _aim_angle := 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left"):
		sweep()


func _physics_process(delta: float) -> void:
	if not sweeping:
		var target := _aim_point()
		_tip = _tip.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
	_place_from_tip()


func _place_from_tip() -> void:
	if _tip.length_squared() <= 0.001:
		return
	rotation = _tip.angle()
	position = _tip - _reach_shape.position.rotated(rotation)


func _aim_point() -> Vector2:
	var to_mouse := get_global_mouse_position() - player.global_position
	if to_mouse == Vector2.ZERO:
		return _tip if _tip.length_squared() > 0.001 else Vector2.RIGHT * 22.0
	var reach := clampf(to_mouse.length() / 280.0, 0.0, 1.0)
	return to_mouse.normalized() * lerpf(22.0, 50.0, reach)


func sweep() -> void:
	if sweeping:
		return
	sweeping = true
	var hold := _aim_point()
	_aim_angle = hold.angle()
	var facing := hold.normalized()
	var distance := hold.length()
	var tween := create_tween()
	tween.tween_property(self, "_tip", facing.rotated(-0.35) * distance, 0.07)
	tween.tween_property(self, "_tip", facing.rotated(0.55) * distance, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_rake_leaves)
	tween.tween_property(self, "_tip", hold, 0.08)
	tween.finished.connect(_end_sweep)


func _rake_leaves() -> void:
	_place_from_tip()
	var tip_global := to_global(_reach_shape.position)
	var toward_player := player.global_position - tip_global
	if toward_player == Vector2.ZERO:
		return
	var push := (Vector2.from_angle(_aim_angle + PI / 2.0) + toward_player.normalized() * 0.5).normalized()
	for area in reach_area.get_overlapping_areas():
		if area.name != "LeafArea":
			continue
		var leaf: Leaf = area.get_parent()
		leaf.receive_gust(tip_global, push, tool_strength)


func _end_sweep() -> void:
	sweeping = false
