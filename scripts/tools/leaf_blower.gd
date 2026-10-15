extends "res://scripts/tools/aimed_tool.gd"

@onready var _sound: AudioStreamPlayer2D = $BlowerSound

@export var tool_strength: float = 80.0

const MAX_LEAVES_PER_BLOW := 48
const FRONT_LAYER_DEPTH := 14.0


func _physics_process(delta: float) -> void:
	var target := _aim_point()
	_tip = _tip.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
	_aim_angle = _tip.angle()
	_place_from_tip()
	var blowing := Input.is_action_pressed("mouse_left")
	_sound.set_blowing(blowing)
	if blowing:
		blow()


func blow() -> void:
	var tip_global := to_global(_reach_shape.position)
	var push := Vector2.from_angle(_aim_angle + PI / 2.0)
	if push == Vector2.ZERO:
		return
	var axis := push.normalized()
	var depths: Array[float] = []
	var leaves: Array[Leaf] = []
	for area in reach_area.get_overlapping_areas():
		if area.name != "LeafArea":
			continue
		var leaf: Leaf = area.get_parent()
		if leaf == null or leaf.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		leaves.append(leaf)
		depths.append((leaf.global_position - tip_global).dot(axis))
	if leaves.is_empty():
		return
	var front_depth := depths[0]
	for depth in depths:
		front_depth = minf(front_depth, depth)
	var layer_limit := front_depth + FRONT_LAYER_DEPTH
	var front: Array[Leaf] = []
	for i in leaves.size():
		if depths[i] <= layer_limit:
			front.append(leaves[i])
	if front.size() > MAX_LEAVES_PER_BLOW:
		front.sort_custom(func(a: Leaf, b: Leaf) -> bool:
			return (a.global_position - tip_global).dot(axis) < (b.global_position - tip_global).dot(axis)
		)
		front = front.slice(0, MAX_LEAVES_PER_BLOW)
	for leaf in front:
		leaf.receive_gust(tip_global, push, tool_strength)
