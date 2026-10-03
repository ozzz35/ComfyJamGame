@tool
extends Node2D
@export var spawn_polygon: PackedVector2Array:
	set(value):
		spawn_polygon = value
		_copy_polygon()
@export var leaf_count: int = 0
@export var pile_count : int = 0
@export var pile_radius : int = 0
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

func _random_point_in_polygon() -> Vector2:
	if spawn_polygon.size() < 3:
		return Vector2(INF, INF)
	var min_x := spawn_polygon[0].x
	var max_x := min_x
	var min_y := spawn_polygon[0].y
	var max_y := min_y
	for point in spawn_polygon:
		max_x = max(max_x, point.x)
		min_x = min(min_x, point.x)
		max_y = max(max_y, point.y)
		min_y = min(min_y, point.y)
	var attempts := 0
	while attempts < 30:
		attempts += 1
		var pos := Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
		if Geometry2D.is_point_in_polygon(pos, spawn_polygon):
			return pos
	return Vector2(INF, INF)

func _point_around_center(center: Vector2, radius: float) -> Vector2:
	var attempts := 0
	var angle : float = 0.0
	var distance : float = 0.0
	var pos : Vector2 
	while attempts < 15:
		attempts += 1	
		angle = randf() * TAU
		distance = randf_range(0.0, radius)
		pos = center + Vector2.from_angle(angle) * distance
		if Geometry2D.is_point_in_polygon(pos, spawn_polygon):
			return pos
	return Vector2(INF, INF)
	
func _plan_piles() -> Array:
	if pile_count < 1:
		return []
	var centers: Array = []
	for _pile in pile_count:
		var pos = _random_point_in_polygon()
		if not pos.is_finite():
			continue
		centers.append(pos)
	if centers.is_empty():
		return []
	var centers_weight: Array = []
	var weight_sum: float = 0.0
	var radii: Array = []
	for _i in centers.size():
		var weight := randf_range(0.4, 1.6)
		centers_weight.append(weight)
		weight_sum += weight
		radii.append(randf_range(pile_radius * 0.45, float(pile_radius)))
	var counts: Array = []
	for weight in centers_weight:
		counts.append(int(leaf_count * weight / weight_sum))
	var counts_sum: int = 0
	for count in counts:
		counts_sum += count
	while counts_sum < leaf_count:
		counts[randi_range(0, counts.size() - 1)] += 1
		counts_sum += 1
	var plan: Array = []
	for i in centers.size():
		plan.append({
			"center": centers[i],
			"count": counts[i],
			"radius": radii[i]
		})
	return plan

func _spawn_leaves() -> void:
	var piles := _plan_piles()
	if piles.is_empty():
		return
	for pile in piles:
		var center := pile["center"] as Vector2
		var count := pile["count"] as int
		var radius := pile["radius"] as float
		for i in count:
			var leaf_pos : Vector2 = _point_around_center(center, radius)
			if not leaf_pos.is_finite():
				continue
			var leaf = leaves.instantiate()
			add_child(leaf)
			leaf.position = leaf_pos
			
			
