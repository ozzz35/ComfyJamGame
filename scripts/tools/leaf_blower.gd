extends "res://scripts/tools/aimed_tool.gd"

@export var tool_strength: float = 80.0


func _physics_process(delta: float) -> void:
	var target := _aim_point()
	_tip = _tip.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
	_aim_angle = _tip.angle()
	_place_from_tip()
	if Input.is_action_pressed("mouse_left"):
		blow()


func blow() -> void:
	var tip_global := to_global(_reach_shape.position)
	var push := Vector2.from_angle(_aim_angle + PI / 2.0)
	for area in reach_area.get_overlapping_areas():
		if area.name != "LeafArea":
			continue
		var leaf: Leaf = area.get_parent()
		leaf.receive_gust(tip_global, push, tool_strength)
