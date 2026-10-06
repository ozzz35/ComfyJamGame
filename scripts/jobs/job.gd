extends Node2D

@onready var garden_area: Polygon2D = $GardenArea

var points : int = 0
var percent_oc : float = 0.0
var starting_leaves : int = 0
var job_status : bool = false
var leaves_cleared : int = 0

@export var job_goal : float = 0.98

signal job_finished

func _ready():
	starting_leaves = _count_leaves()

	
func _count_leaves() -> int:
	var total : int = 0
	for node in find_children("*", "", true, false):
		if node.has_method("receive_gust"):
			total += 1
	return total

func contains_world_point(world_position: Vector2) -> bool:
	var local_point := garden_area.to_local(world_position)
	return Geometry2D.is_point_in_polygon(local_point, garden_area.polygon)
	
func leaf_removed():
	if job_status == true:
		return
	leaves_cleared += 1 
	points += 20
	print("Points: ", points, "\n Leaves cleared: ", leaves_cleared, "\n Completion: ", percent_oc)
	percent_oc = snapped(float(leaves_cleared) / float(starting_leaves), 0.01)
	if percent_oc >= job_goal:
		job_status = true
		job_finished.emit()
		print("Finished!")
