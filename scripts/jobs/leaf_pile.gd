@tool
extends Node2D
@export var spawn_polygon: PackedVector2Array:
	set(value):
		spawn_polygon = value
		_copy_polygon()
@export var leaf_count: int = 0
@onready var spawnarea = $SpawnArea
const leaves = preload("res://scenes/jobs/leaves.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_copy_polygon()
	_spawn_leaves()
	
func _copy_polygon() -> void:
	var area := get_node_or_null("SpawnArea") as Polygon2D
	if area == null:
		return
	area.polygon = spawn_polygon
	print(name, " copied ", spawn_polygon.size(), " points: ", spawn_polygon)

func _spawn_leaves():
	if spawn_polygon.size() < 3:
		print(name, " spawn skipped, points: ", spawn_polygon.size())
		return
	print(name, " spawning from ", spawn_polygon.size(), " points: ", spawn_polygon)
	var min_x := spawn_polygon[0].x
	var max_x := min_x
	var min_y := spawn_polygon[0].y
	var max_y := min_y
	for point in spawn_polygon:
		max_y = max(max_y, point.y)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		min_x = min(min_x, point.x)
	
	for i in leaf_count:
		var x_pos : float = randf_range(max_x, min_x)
		var y_pos : float = randf_range(max_y, min_y)
		var leaf_pos : Vector2 = Vector2(x_pos, y_pos)
		if not Geometry2D.is_point_in_polygon(leaf_pos, spawn_polygon):
			leaf_count += 1
			var limit =+ 15
			if limit >= 15:
				return
		else:
			var leaf = leaves.instantiate()
			add_child(leaf)
			leaf.position = leaf_pos
