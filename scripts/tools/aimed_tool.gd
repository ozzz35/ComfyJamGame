extends Sprite2D

@onready var player: PlayerBase = $"../.."
@onready var reach_area: Area2D = $ReachArea
@onready var _reach_shape: CollisionShape2D = $ReachArea/ReachAreaCollider

var _tip := Vector2.RIGHT * 22.0
var _aim_angle := 0.0


func _place_from_tip() -> void:
	if _tip.length_squared() <= 0.001:
		return
	rotation = _tip.angle()
	_aim_angle = rotation
	position = _tip - _reach_shape.position.rotated(rotation)


func _aim_point() -> Vector2:
	var to_mouse := get_global_mouse_position() - player.global_position
	if to_mouse == Vector2.ZERO:
		return _tip if _tip.length_squared() > 0.001 else Vector2.RIGHT * 22.0
	var reach := clampf(to_mouse.length() / 280.0, 0.0, 1.0)
	return to_mouse.normalized() * lerpf(22.0, 50.0, reach)
