@tool
extends Node2D

const RADIUS_MIN := 10
const RADIUS_MAX := 100
const DENSITY_MIN := 0.005
const DENSITY_MAX := 0.2
const DENSITY_STEP := 0.005
const SQUISH_MIN := 0.4
const SQUISH_MAX := 1.0
const WOBBLE_MAX := 0.35

@export_range(10, 100, 1, "or_greater") var pile_radius: int = 75:
	set(value):
		pile_radius = value
		_spawn_leaves()

@export_range(0.005, 0.2, 0.005, "or_greater", "or_less") var density: float = 0.02:
	set(value):
		density = value
		_spawn_leaves()

@export_range(0.4, 1.0, 0.01, "or_greater", "or_less") var squish: float = 0.75:
	set(value):
		squish = value
		_spawn_leaves()

@export_range(0, 360, 1, "radians_as_degrees") var spin: float = 0.0:
	set(value):
		spin = value
		_spawn_leaves()

@export_range(0, 0.35, 0.01, "or_greater") var edge_wobble: float = 0.15:
	set(value):
		edge_wobble = value
		_spawn_leaves()

## Rolls radius, density, squish, spin, and edge wobble inside the slider ranges, then turns itself off.
@export var randomize_pile: bool = false:
	set(value):
		randomize_pile = false
		if not value or not Engine.is_editor_hint():
			return
		pile_radius = randi_range(RADIUS_MIN, RADIUS_MAX)
		density = snappedf(randf_range(DENSITY_MIN, DENSITY_MAX), DENSITY_STEP)
		squish = snappedf(randf_range(SQUISH_MIN, SQUISH_MAX), 0.01)
		spin = randf() * TAU
		edge_wobble = snappedf(randf_range(0.0, WOBBLE_MAX), 0.01)
		notify_property_list_changed()

const leaves = preload("res://scenes/jobs/leaves.tscn")

func _ready() -> void:
	_spawn_leaves()
	
func _point_around_center(radius: float) -> Vector2:
	var offset := Vector2.from_angle(randf() * TAU) * (radius * sqrt(randf()))
	offset = offset.rotated(-spin)
	offset.x *= squish
	var low := maxf(0.0, 1.0 - edge_wobble)
	offset *= randf_range(low, 1.0 + edge_wobble)
	offset = offset.rotated(spin)
	return offset

func _spawn_leaves() -> void:
	if not is_inside_tree():
		return
	if pile_radius <= 0 or density <= 0.0:
		_clear_spawned()
		return
	_clear_spawned()
	var count := roundi(float(pile_radius * pile_radius) * squish * density)
	for i in count:
		var leaf := leaves.instantiate()
		leaf.add_to_group("spawned_leaf")
		if Engine.is_editor_hint():
			add_child(leaf, false, Node.INTERNAL_MODE_BACK)
		else:
			add_child(leaf)
		leaf.position = _point_around_center(float(pile_radius))

func _clear_spawned() -> void:
	for child in get_children(true):
		if not child.is_in_group("spawned_leaf"):
			continue
		remove_child(child)
		child.queue_free()
